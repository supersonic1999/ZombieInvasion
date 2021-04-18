include( "shared.lua" )

local SPAWN_MENU = {}
SPAWN_MENU.models = {"None"}
SPAWN_MENU.weapons = {"None", "weapon_357", "weapon_alyxgun", "weapon_annabelle", "weapon_ar2", "weapon_brickbat",
					  "weapon_crossbow", "weapon_crowbar", "weapon_frag", "weapon_pistol", "weapon_rpg",
					  "weapon_shotgun", "weapon_smg1", "weapon_stunstick"}
SPAWN_MENU.npcs = {"None", "npc_alyx", "npc_antlion", "npc_antlionguard", "npc_barney", "npc_citizen", "npc_combine_s",
				   "npc_crow", "npc_fastzombie", "npc_headcrab", "npc_headcrab_black", "npc_headcrab_fast",
				   "npc_manhack", "npc_metropolice", "npc_monk", "npc_poisonzombie", "npc_rollermine",
				   "npc_sniper", "npc_vortigaunt", "npc_zombie", "npc_zombie_torso"}

function SPAWN_MENU:Open_Editor()
	SPAWN_MENU.editing = nil

	self.panel = vgui.Create("DFrame")
	self.panel:SetPos(50,50)
	self.panel:SetSize(700, 500)
	self.panel:SetTitle("Spawn Editor") 
	self.panel:SetVisible(true)
	self.panel:SetDraggable(true)
	self.panel:ShowCloseButton(true)
	self.panel:MakePopup()

	self.psheet = vgui.Create( "DPropertySheet", self.panel )
	self.psheet:SetPos( 10, 35 )
	self.psheet:SetSize( 680, 240 )

	self.addTab = vgui.Create( "DPanelList" )
	self.addTab:SetPos( 0, 0 )
	self.addTab:SetSize( self.psheet:GetWide(), self.psheet:GetTall() )
	self.addTab:SetSpacing( 5 )
	self.addTab:EnableHorizontal( false )
	self.addTab:EnableVerticalScrollbar( true )

	self.editTab = vgui.Create( "DPanelList" )
	self.editTab:SetPos( 0, 0 )
	self.editTab:SetSize( self.psheet:GetWide(), self.psheet:GetTall() )
	self.editTab:SetSpacing( 5 )
	self.editTab:EnableHorizontal( false )
	self.editTab:EnableVerticalScrollbar( true )

	self.tab1 = self.psheet:AddSheet("Add", self.addTab, nil, false, false, nil)
	self.tab2 = self.psheet:AddSheet("Edit", self.editTab, nil, false, false, nil)

	self:draw_options(0)
	self:draw_options(1)
	self:disable_edit(true)

	--List
	self.list = vgui.Create("DListView", self.panel)
	self.list:SetPos(10,290)
	self.list:SetSize(680,200) --W, H
	self.list:SetMultiSelect(false)
	self.list:AddColumn("ID")
	self.list:AddColumn("Health")
	self.list:AddColumn("Chance")
	self.list:AddColumn("Model")
	self.list:AddColumn("Scale")
	self.list:AddColumn("NPC")
	self.list:AddColumn("Weapon")
	self.list:AddColumn("Max")
	self.list:AddColumn("Type")
	self.list:AddColumn("Explode?")
	self.list.OnRowRightClick = function ( pnl, num )
	    local MenuButtonOptions = DermaMenu()
	    MenuButtonOptions:AddOption("Delete Row", function() 
	    	self.list:RemoveLine(num) 
	    	table.remove(zombie_list, num) 
	    	self:update_table()
	    	if LocalPlayer():IsSuperAdmin() then
	    		self.panel:Close()
				SPAWN_MENU:Open_Editor() 
			end
	    end)
	    MenuButtonOptions:AddOption("Edit...", function() self:zlist_edit_row(num) end )
	    MenuButtonOptions:Open()
	end

	local i = 1
	for k, v in pairs(zombie_list) do
		self:add_line(table.Copy(v), i)
		i = i + 1
	end
end

function SPAWN_MENU:add_line(data, id)
	if tonumber(data["health"]) <= 0 then
		data["health"] = "Default"
	end
	if data["model"] == "" then
		data["model"] = "None"
	end
	if data["weapon"] == "" then
		data["weapon"] = "None"
	end	

	self.list:AddLine(id, data["health"], data["chance"], data["model"], data["scale"], data["class_name"], data["weapon"], data["max"], data["type"], data["explode"])
end

function SPAWN_MENU:disable_edit(bool)
	self.editTab.health:SetDisabled(bool)
	self.editTab.chance:SetDisabled(bool)
	self.editTab.model:SetDisabled(bool)
	self.editTab.scale:SetDisabled(bool)
	self.editTab.max:SetDisabled(bool)
	self.editTab.type:SetDisabled(bool)
	self.editTab.explode:SetDisabled(bool)
	self.editTab.npc:SetDisabled(bool)
	self.editTab.weapon:SetDisabled(bool)
	self.editTab.button:SetDisabled(bool)
	self.editTab.modeldrop:SetDisabled(bool)
	self.editTab.npcdrop:SetDisabled(bool)
	self.editTab.weapondrop:SetDisabled(bool)

	self.editTab.health:SetEditable(!bool)
	self.editTab.chance:SetEditable(!bool)
	self.editTab.model:SetEditable(!bool)
	self.editTab.scale:SetEditable(!bool)
	self.editTab.max:SetEditable(!bool)
	self.editTab.npc:SetEditable(!bool)
	self.editTab.weapon:SetEditable(!bool)
end

function SPAWN_MENU:apply_edit()
	zombie_list[self.editing]["health"] = self.editTab.health:GetValue()
	zombie_list[self.editing]["chance"] = self.editTab.chance:GetValue()
	zombie_list[self.editing]["model"] = self.editTab.model:GetValue()
	zombie_list[self.editing]["scale"] = self.editTab.scale:GetValue()
	zombie_list[self.editing]["class_name"] = self.editTab.npc:GetValue()
	zombie_list[self.editing]["weapon"] = self.editTab.weapon:GetValue()
	zombie_list[self.editing]["max"] = self.editTab.max:GetValue()
	zombie_list[self.editing]["type"] = self.editTab.type:GetValue()
	zombie_list[self.editing]["explode"] = tostring(self.editTab.explode:GetChecked())
	self.list:RemoveLine(self.editing)
	self:add_line(table.Copy(zombie_list[self.editing]), self.editing)
	self.editing = nil
	self.editTab.editlabel:SetText("Editing: nil")
	self:disable_edit(true)
	self:update_table()
end

function SPAWN_MENU:apply_add()
	local new = {}
	new["health"] = self.addTab.health:GetValue()
	new["chance"] = self.addTab.chance:GetValue()
	new["model"] = self.addTab.model:GetValue()
	new["scale"] = self.addTab.scale:GetValue()
	new["class_name"] = self.addTab.npc:GetValue()
	new["weapon"] = self.addTab.weapon:GetValue()
	new["max"] = self.addTab.max:GetValue()
	new["type"] = self.addTab.type:GetValue()
	new["explode"] = tostring(self.addTab.explode:GetChecked())
	
	table.insert(zombie_list, new)
	self:add_line(table.Copy(new), table.Count(zombie_list))
	self:update_table()
end

function SPAWN_MENU:draw_options(tabnum)
	local tab = {}
	if tabnum == 0 then
		tab = self.addTab
		tab.button = vgui.Create( "DButton", tab )
		tab.button:SetSize( 100, 30 )
		tab.button:SetPos( 560, 170)
		tab.button:SetText( "Add" )
		tab.button.DoClick = function( button )
			self:apply_add()
		end
	else 
		tab = self.editTab
		tab.editlabel = vgui.Create("DLabel", tab)
		tab.editlabel:SetPos(10, 190)
		tab.editlabel:SetText("Editing: "..tostring(self.editing))
		tab.editlabel:SizeToContents()

		tab.button = vgui.Create( "DButton", tab )
		tab.button:SetSize( 100, 30 )
		tab.button:SetPos( 560, 170)
		tab.button:SetText( "Update" )
		tab.button.DoClick = function( button )
			self:apply_edit()
		end
	end

	--Health
	tab.healthlabel = vgui.Create("DLabel", tab)
	tab.healthlabel:SetPos(10,10)
	tab.healthlabel:SetText("Health:")
	tab.healthlabel:SizeToContents()
	tab.health = vgui.Create("DNumberWang", tab)
	tab.health:SetPos(60,10)
	tab.health:SetMin(-1)
	tab.health:SetValue(-1)

	--Chance
	tab.chancelabel = vgui.Create("DLabel", tab)
	tab.chancelabel:SetPos(10,35)
	tab.chancelabel:SetText("Chance:")
	tab.chancelabel:SizeToContents()
	tab.chance = vgui.Create("DNumberWang", tab)
	tab.chance:SetPos(60,35)
	tab.chance:SetValue(100)
	tab.chance:SetMin(1)

	--Scale
	tab.scalelabel = vgui.Create("DLabel", tab)
	tab.scalelabel:SetPos(10,60)
	tab.scalelabel:SetText("Scale:")
	tab.scalelabel:SizeToContents()
	tab.scale = vgui.Create("DNumberWang", tab)
	tab.scale:SetPos(60,60)
	tab.scale:SetValue(1)
	tab.scale:SetMin(1)

	--Model
	tab.modellabel = vgui.Create("DLabel", tab)
	tab.modellabel:SetPos(200,10)
	tab.modellabel:SetText("Model:")
	tab.modellabel:SizeToContents()
	tab.modeldrop = vgui.Create("DComboBox", tab)
	tab.modeldrop:SetPos(250,10)
	tab.modeldrop:SetWide(300)
	tab.modeldrop:SetValue(SPAWN_MENU.models[1])
	for k, v in pairs(SPAWN_MENU.models) do
		tab.modeldrop:AddChoice(v)
	end
	tab.modeldrop.OnSelect = function(index,value,data)
		tab.model:SetValue(SPAWN_MENU.models[value])
	end
	tab.model = vgui.Create("DTextEntry", tab)
	tab.model:SetPos(250,35)
	tab.model:SetWide(300)

	--NPC
	tab.npclabel = vgui.Create("DLabel", tab)
	tab.npclabel:SetPos(200,65)
	tab.npclabel:SetText("NPC:")
	tab.npclabel:SizeToContents()
	tab.npcdrop = vgui.Create("DComboBox", tab)
	tab.npcdrop:SetPos(250,65)
	tab.npcdrop:SetWide(300)
	tab.npcdrop:SetValue(SPAWN_MENU.npcs[1])
	for k, v in pairs(SPAWN_MENU.npcs) do
		tab.npcdrop:AddChoice(v)
	end
	tab.npcdrop.OnSelect = function(index,value,data)
		tab.npc:SetValue(SPAWN_MENU.npcs[value])
	end
	tab.npc = vgui.Create("DTextEntry", tab)
	tab.npc:SetPos(250,90)
	tab.npc:SetWide(300)

	--Weapon
	tab.weaponlabel = vgui.Create("DLabel", tab)
	tab.weaponlabel:SetPos(200,120)
	tab.weaponlabel:SetText("Weapon:")
	tab.weaponlabel:SizeToContents()
	tab.weapondrop = vgui.Create("DComboBox", tab)
	tab.weapondrop:SetPos(250,120)
	tab.weapondrop:SetWide(300)
	tab.weapondrop:SetValue(SPAWN_MENU.weapons[1])
	for k, v in pairs(SPAWN_MENU.weapons) do
		tab.weapondrop:AddChoice(v)
	end
	tab.weapondrop.OnSelect = function(index,value,data)
		tab.weapon:SetValue(SPAWN_MENU.weapons[value])
	end
	tab.weapon = vgui.Create("DTextEntry", tab)
	tab.weapon:SetPos(250,145)
	tab.weapon:SetWide(300)

	--Max NPCs
	tab.maxLabel = vgui.Create("DLabel", tab)
	tab.maxLabel:SetPos(10,85)
	tab.maxLabel:SetText("Max:")
	tab.maxLabel:SizeToContents()
	tab.max = vgui.Create("DNumberWang", tab)
	tab.max:SetPos(60,85)
	tab.max:SetValue(10)
	tab.max:SetMin(0)

	--Type
	tab.typeLabel = vgui.Create("DLabel", tab)
	tab.typeLabel:SetPos(10,110)
	tab.typeLabel:SetText("Chase?")
	tab.typeLabel:SizeToContents()
	tab.type = vgui.Create("DComboBox", tab)
	tab.type:SetPos(60,110)
	tab.type:SetWide(100)
	tab.type:SetValue("Chaser")
	tab.type:AddChoice("Chaser")
	tab.type:AddChoice("Roamer")
	tab.type:AddChoice("None")

	--Explode
	tab.explodeLabel = vgui.Create("DLabel", tab)
	tab.explodeLabel:SetPos(10,135)
	tab.explodeLabel:SetText("Explode?")
	tab.explodeLabel:SizeToContents()
	tab.explode = vgui.Create("DCheckBox", tab)
	tab.explode:SetPos(60,135)
	tab.explode:SetValue(0)
end

function SPAWN_MENU:zlist_edit_row(num)
	self.editing = num
	self:disable_edit(false)
	self.editTab.editlabel:SetText("Editing: "..tostring(self.editing))
	self.psheet:SetActiveTab(self.tab2.Tab)

	self.editTab.health:SetText(zombie_list[num]["health"])
	self.editTab.chance:SetText(zombie_list[num]["chance"])
	self.editTab.model:SetText(zombie_list[num]["model"])
	self.editTab.scale:SetText(zombie_list[num]["scale"])
	self.editTab.npc:SetText(zombie_list[num]["class_name"])
	self.editTab.weapon:SetText(zombie_list[num]["weapon"])
	self.editTab.max:SetText(zombie_list[num]["max"])
	self.editTab.type:SetText(zombie_list[num]["type"])
	self.editTab.explode:SetValue(zombie_list[num]["explode"])
end

function SPAWN_MENU:update_table()
	net.Start("send_ztable_sr")
	net.WriteTable(zombie_list)
	net.SendToServer()
end

hook.Add("Initialize", "initializing_zinv_c", function()
	zombie_list = {}
end)

hook.Add("PopulateToolMenu", "ZINVmenu", function()
	spawnmenu.AddToolMenuOption("Options", "ZINV", "ZINV", "Settings", "", "", OnPopulateSettingsPanel)
end)

net.Receive("send_ztable_cl", function(len) 
	zombie_list = net.ReadTable()
end)

function OnPopulateSettingsPanel(panel)
	local p = panel:AddControl("CheckBox", {
		Label = "Enabled?"
	})
	p:SetValue( GetConVarNumber( "zinv" ) )
	p.OnChange = function(self)
		if LocalPlayer():IsSuperAdmin() then
			net.Start("zinv_changecvar")
			net.WriteString("zinv")
			net.WriteFloat(self:GetChecked()==true and 1 or 0)
			net.SendToServer()
		else
			chat.AddText(Color(255,62,62), "WARNING: ", Color(255,255,255), "You must be a super-admin to change this option.")
			chat.PlaySound()
		end			
	end

	local p = panel:AddControl("Slider", {
		Label = "Minimum Spawn Distance",
		Type = "Long",
		Min = "0",
		Max = "20000"
	})
	p:SetValue( GetConVarNumber( "zinv_mindist" ) )
	p.OnValueChanged = function(self)
		if LocalPlayer():IsSuperAdmin() then
			net.Start("zinv_changecvar")
			net.WriteString("zinv_mindist")
			net.WriteFloat(self:GetValue())
			net.SendToServer()
		else
			chat.AddText(Color(255,62,62), "WARNING: ", Color(255,255,255), "You must be a super-admin to change this option.")
			chat.PlaySound()
		end			
	end

	panel:AddControl("Label", {
		Text = "NPCs must be this far away from any player to spawn."
	})

	local p = panel:AddControl("Slider", {
		Label = "Maximum Spawn Distance",
		Type = "Long",
		Min = "0",
		Max = "20000",
	})
	p:SetValue( GetConVarNumber( "zinv_maxdist" ) )
	p.OnValueChanged = function(self)
		if LocalPlayer():IsSuperAdmin() then
			net.Start("zinv_changecvar")
			net.WriteString("zinv_maxdist")
			net.WriteFloat(self:GetValue())
			net.SendToServer()
		else
			chat.AddText(Color(255,62,62), "WARNING: ", Color(255,255,255), "You must be a super-admin to change this option.")
			chat.PlaySound()
		end			
	end

	panel:AddControl("Label", {
		Text = ""
	})

	local p = panel:AddControl("Button", {
		Label = "Spawn Editor",
		Command = ""
	})
	p.DoClick = function() 
		if LocalPlayer():IsSuperAdmin() then
			SPAWN_MENU:Open_Editor() 
		else
			chat.AddText(Color(255,62,62), "WARNING: ", Color(255,255,255), "You must be a super-admin to change this option.")
			chat.PlaySound()
		end			
	end
end