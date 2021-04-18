if !ConVarExists("zinv") then
    CreateConVar("zinv", '1', {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_NOTIFY})
end

if !ConVarExists("zinv_maxdist") then
    CreateConVar("zinv_maxdist", '3000', {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_NOTIFY})
end

if !ConVarExists("zinv_mindist") then
    CreateConVar("zinv_mindist", '1000', {FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED, FCVAR_NOTIFY})
end

if !SERVER then return end

net.Receive("zinv_changecvar", function(len,ply)
	if !(ply:IsValid() and ply:IsPlayer() and ply:IsSuperAdmin()) then 
		return 
	end
	
	command = net.ReadString()
	if command == "zinv" then
		RunConsoleCommand("zinv", net.ReadFloat())
	elseif command == "zinv_maxdist" then
		RunConsoleCommand("zinv_maxdist", net.ReadFloat())
	elseif command == "zinv_mindist" then
		RunConsoleCommand("zinv_mindist", net.ReadFloat())
	end
end)