util.AddNetworkString("send_ztable_cl")
util.AddNetworkString("send_ztable_sr")
util.AddNetworkString("zinv_changecvar")
concommand.Add("zinv_reloadsettings", load_npc_info)

include( "shared.lua" )
AddCSLuaFile( "shared.lua" )

default_settings = [[
"NPC_Settings"
{
	"1"
	{
		"health"		"-1"
		"chance"		"100"
		"model"			""
		"scale"			"1"
		"class_name"		"npc_zombie"
		"weapon"		""
		"max"			"10"
		"type"			"Chaser"
		"explode"		"true"
	}
	"2"
	{
		"health"		"-1"
		"chance"		"30"
		"model"			""
		"scale"			"1"
		"class_name"		"npc_fastzombie"
		"weapon"		""
		"max"			"10"
		"type"			"Chaser"
		"explode"		"false"
	}
	"3"
	{
		"health"		"-1"
		"chance"		"40"
		"model"			""
		"scale"			"1"
		"class_name"		"npc_headcrab_fast"
		"weapon"		""
		"max"			"10"
		"type"			"Chaser"
		"explode"		"false"
	}
}]]

hook.Add("OnNPCKilled","NPC_Died_zinv", function(victim, killer, weapon)
	local class = classSettings(victim:GetClass())
	if !class or class["explode"] != "true" then
		return
	end

	local explode = ents.Create( "env_explosion" )
	explode:SetPos( victim:GetPos() )
	explode:Spawn()
	explode:SetKeyValue( "iMagnitude", "35" )
	explode:Fire( "Explode", 0, 0 )
	explode:EmitSound( "weapon_AWP.Single", 400, 400 )
end)

hook.Add("Initialize", "initializing_zinv", function()
	Nodes = {}
	total_chance = 0
	load_npc_info()
	found_ain = false
	ParseFile()
end)

hook.Add("PlayerInitialSpawn", "pinitspawn_zinv", function(ply)
	net.Start("send_ztable_cl")
	net.WriteTable(zombie_list)
	net.Send(ply)
end)

hook.Add("EntityKeyValue", "newkeyval_zinv", function(ent)
	if ent:GetClass() == "info_player_teamspawn" then
		local valid = true
		for k,v in pairs(Nodes) do
			if v["pos"] == ent:GetPos() then
				valid = false
			end
		end

		if valid then
			local node = {
				pos = ent:GetPos(),
				yaw = 0,
				offset = 0,
				type = 0,
				info = 0,
				zone = 0,
				neighbor = {},
				numneighbors = 0,
				link = {},
				numlinks = 0
			}
			table.insert(Nodes, node)
		end
	end
end)

--Taken from nodegraph addon - thx
local SIZEOF_INT = 4
local SIZEOF_SHORT = 2
local AINET_VERSION_NUMBER = 37
local function toUShort(b)
	local i = {string.byte(b,1,SIZEOF_SHORT)}
	return i[1] +i[2] *256
end
local function toInt(b)
	local i = {string.byte(b,1,SIZEOF_INT)}
	i = i[1] +i[2] *256 +i[3] *65536 +i[4] *16777216
	if(i > 2147483647) then return i -4294967296 end
	return i
end
local function ReadInt(f) return toInt(f:Read(SIZEOF_INT)) end
local function ReadUShort(f) return toUShort(f:Read(SIZEOF_SHORT)) end

--Taken from nodegraph addon - thx
--Types:
--1 = ?
--2 = info_nodes
--3 = playerspawns
--4 = wall climbers
function ParseFile()
	if foundain then
		return
	end

	f = file.Open("maps/graphs/"..game.GetMap()..".ain","rb","GAME")
	if(!f) then
		return
	end

	found_ain = true
	local ainet_ver = ReadInt(f)
	local map_ver = ReadInt(f)
	if(ainet_ver != AINET_VERSION_NUMBER) then
		MsgN("ZINV: Unknown graph file")
		return
	end

	local numNodes = ReadInt(f)
	if(numNodes < 0) then
		MsgN("ZINV: Error, Map Nodes, 0")
		return
	end

	MsgN("ZINV: Map Nodes, ", numNodes)
	for i = 1,numNodes do
		local v = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
		local yaw = f:ReadFloat()
		local flOffsets = {}
		for i = 1,NUM_HULLS do
			flOffsets[i] = f:ReadFloat()
		end
		local nodetype = f:ReadByte()
		local nodeinfo = ReadUShort(f)
		local zone = f:ReadShort()

		if nodetype == 4 then
			continue
		end
		
		local node = {
			pos = v,
			yaw = yaw,
			offset = flOffsets,
			type = nodetype,
			info = nodeinfo,
			zone = zone,
			neighbor = {},
			numneighbors = 0,
			link = {},
			numlinks = 0
		}

		table.insert(Nodes,node)
	end
end

timer.Create("zombietimercheck_zinv", 10, 0, function()
	local status, err = pcall( function()
	local valid_nodes = {}
	local zombies = {}

	if GetConVarNumber("zinv") == 0 or table.Count(player.GetAll()) <= 0 then
		return
	end
	
	if !found_ain then
		ParseFile()
	end

	if GetConVarNumber("zinv_maxdist") < GetConVarNumber("zinv_mindist") then
		print("ZINV: Zombies cannot spawn! Max spawn distance is less than Min!")
	end

	if !zombie_list then
		print("ZINV: Error with zombie_list")
		return
	end

	if !Nodes or table.Count(Nodes) < 1 then
		print("ZINV: No info_node(s) in map! NPCs will not spawn.")
		return
	end

	if table.Count(Nodes) <= 35 then
		print("ZINV: Zombies may not spawn well on this map, please try another.")
	end

	for k, v in pairs(zombie_list) do
		local zombies = table.Add(zombies, ents.FindByClass(v["class_name"]))
	end
	
	--Check zombie
	for k, v in pairs(zombies) do
		local closest = -1
		local closest_plr = NULL
		local zombie_pos = v:GetPos()

		for k2, v2 in pairs(player.GetAll()) do
			local dist = zombie_pos:Distance(v2:GetPos())

			if dist < closest or closest == -1 then
				closest_plr = v2
				closest = dist
			end
		end

		if closest > GetConVarNumber("zinv_maxdist")*1.25 then
			v:Remove()
		else
			local class = classSettings(v:GetClass())
			if !class or v.Base == "base_nextbot" then
				continue
			end
			if class["type"] == "Chaser" then
				v:SetLastPosition(closest_plr:GetPos())
				v:SetSaveValue("m_vecLastPosition", closest_plr:GetPos())
				v:SetTarget(closest_plr)
				if !v:IsCurrentSchedule(SCHED_TARGET_CHASE) then
					v:SetSchedule(SCHED_TARGET_CHASE)
				end
			elseif class["type"] == "Roamer" then
				if !v:IsCurrentSchedule(SCHED_RUN_RANDOM) and v:IsCurrentSchedule(SCHED_IDLE_STAND) then
					v:SetSchedule(SCHED_RUN_RANDOM)
				end
			end
		end
	end

	end)

	if !status then
		print(err)
	end
end)

timer.Create("zombietimer_zinv", 1, 0, function()
	local status, err = pcall( function()
	local valid_nodes = {}
	local zombies = {}

	if GetConVarNumber("zinv") == 0 or table.Count(player.GetAll()) <= 0 then
		return
	end
	
	if !found_ain then
		ParseFile()
	end

	if GetConVarNumber("zinv_maxdist") < GetConVarNumber("zinv_mindist") then
		print("ZINV: Zombies cannot spawn! Max spawn distance is less than Min!")
	end

	if !zombie_list then
		print("ZINV: Error with zombie_list")
		return
	end

	if !Nodes or table.Count(Nodes) < 1 then
		print("ZINV: No info_node(s) in map! NPCs will not spawn.")
		return
	end

	if table.Count(Nodes) <= 35 then
		print("ZINV: Zombies may not spawn well on this map, please try another.")
	end

	for k, v in pairs(zombie_list) do
		local zombies = table.Add(zombies, ents.FindByClass(v["class_name"]))
	end
	
	--Get valid nodes
	for k, v in pairs(Nodes) do
		local valid = false

		if table.Count(valid_nodes) >= 50*table.Count(player.GetAll()) then
			break
		end

		for k2, v2 in pairs(player.GetAll()) do
			local dist = v["pos"]:Distance(v2:GetPos())

			if dist <= GetConVarNumber("zinv_mindist") then
				valid = false
				break
			elseif dist < GetConVarNumber("zinv_maxdist") then
				valid = true
			end
		end

		if !valid then
			continue
		end

		for k2, v2 in pairs(zombies) do
			local dist = v["pos"]:Distance(v2:GetPos())
			if dist <= 100 then
				valid = false
				break
			end
		end

		if valid then
			table.insert(valid_nodes, v["pos"])
		end
	end

	--Spawn zombies if not enough
	for k, v in pairs(zombie_list) do
		local c = table.Count(ents.FindByClass(v["class_name"]))
		if c < v["max"] then
			local loopmax = math.min(5, v["max"]-c)
			for i = 0, loopmax-1 do
				if (v["chance"]/100.0) <= math.Rand(0, 1) then
					continue
				end
				local pos = table.Random(valid_nodes) 
				if pos != nil then
					table.RemoveByValue(valid_nodes, pos)
					spawn_zombie(v, pos + Vector(0,0,30))
				end
			end
		end
	end
	end) 

	if !status then
		print(err)
	end
end)

--returns false if classStr not in zombie_list, returns the entry if found
function classSettings(classStr)
	for k, v in pairs(zombie_list) do
		if v["class_name"] == tostring(classStr) then
			return v
		end
	end
	return false
end

function spawn_zombie(z_class, pos)
	--Spawn NPC
	if z_class then
		local zombie = ents.Create(z_class["class_name"])
		if zombie then
			if z_class["weapon"] then
   				zombie:SetKeyValue("additionalequipment", z_class["weapon"])
   			end
   			zombie:SetPos(pos)
   			zombie:SetAngles(Angle(0, math.random(0, 360), 0))
			zombie:Spawn()
			if z_class["model"] then
				zombie:SetModel(z_class["model"])
			end
			if z_class["scale"] then
				zombie:SetModelScale(z_class["scale"], 0)
			end
			if z_class["health"] and z_class["health"] > 0 then
   				zombie:SetHealth(z_class["health"])
   				zombie:SetMaxHealth(z_class["health"])
   			end
   			zombie:Activate()			
		end
	end
end

function load_npc_info()
	zombie_list = {}
	total_chance = 0
	local f = file.Read("zinv_settings.txt", "DATA")
	if f then
		Settings = util.KeyValuesToTable(f)
		for k, v in pairs(Settings) do
			table.insert(zombie_list, v)
		end
	end

	if !f or table.Count(zombie_list) <= 0 then
		file.Write("zinv_settings.txt", default_settings) 
		Settings = util.KeyValuesToTable(default_settings)
		for k, v in pairs(Settings) do
			table.insert(zombie_list, v)
		end
		print("ZINV: Initial File Created: data/zinv_settings.txt")
	end

	--Check validity
	for k, v in pairs(zombie_list) do
		if tonumber(v["health"]) == nil then
			v["health"] = -1
		end
		if tonumber(v["chance"]) == nil then
			v["chance"] = 100
		end
		if tonumber(v["scale"]) == nil then
			v["scale"] = 1
		end
		if !v["model"] then
			v["model"] = ""
		end
		if !v["weapon"] then
			v["weapon"] = ""
		end
		if !v["class_name"] then
			v["class_name"] = ""
		end
		total_chance = total_chance + v["chance"]
	end
	print("--ZINV Settings--")
	PrintTable(zombie_list)

	--Notify players
	net.Start("send_ztable_cl")
	net.WriteTable(zombie_list)
	net.Broadcast()
end

net.Receive("send_ztable_sr", function(len, pl)
	if pl:IsValid() and pl:IsPlayer() and pl:IsSuperAdmin() then
		zombie_list = net.ReadTable()
		file.Write("zinv_settings.txt", util.TableToKeyValues(zombie_list)) 
		load_npc_info()
		print("ZINV: NPC waves edit by: "..pl:Nick())
		
	end
end)