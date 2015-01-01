-------------------------------------------------------
-- Simple E2 theft protection
-- Made by Divran
-- Made to get people to shut the f**k up
-- 01/01/2015

-- Available wire_expression2_theft_protection convar settings:
-- 0 = Disabled. Everyone can steal your E2s if the prop protection mod allows it.
-- 1 = Enabled. Only people on your Prop Protection friends list can take your code. (NOTE: Some prop protection mods will add all admins to your PP friends list at all times)
-- 2 = Enabled. Only super admins can take your code. (DEFAULT MODE)
-- 3 = Enabled. Nobody can take your code (except admins with access to Lua commands, they still can).
-------------------------------------------------------

if CLIENT then
	CreateClientConVar( "wire_expression2_theft_protection", 2, true, true )
else
	AddCSLuaFile()
	
	local duplicators = {
		duplicator = true,
		advdupe2 = true,
		adv_duplicator = true,
	}
	
	local function duplicationCheck( ply, trace )
		local ret = {}
		local entities = constraint.GetAllConstrainedEntities( trace.Entity )
		entities[trace.Entity] = trace.Entity -- add the entity itself, too (it might be an E2)
		
		for k,v in pairs( entities ) do
			if v:GetClass() == "gmod_wire_expression2" then
				ret[#ret+1] = v
			end
		end
		
		return ret
	end
	
	local function check( ply, trace, toolname, other )
		if not IsValid( trace.Entity ) then return end
		
		if toolname == "wire_expression2" and other == "halt execution" then -- just halting execution is fine, don't block that at all
			return
		end
		
		if duplicators[toolname] then
			local entities = duplicationCheck( ply, trace )
			
			-- Here we need to check all E2s on the contraption.
			-- because they might be owned by different people
			-- If you're not allowed to dupe ANY of the E2s on this contraption, prevent tool click
			for i=1,#entities do
				if not check( ply, { Entity = entities[i] }, "wire_expression2_theft_protection" ) then
					return false
				end
			end
		end
		
		if trace.Entity:GetClass() == "gmod_wire_expression2" then
			local owner = trace.Entity:CPPIGetOwner()
			
			local mode = owner:GetInfoNum( "wire_expression2_theft_protection", 2 )
			if mode == 0 then return end
		
			if mode == 1 then -- prop protection friends list can take your code
				local friends = owner:CPPIGetFriends()
				
				local found = false
				for i=1,#friends do
					if friends[i] == ply then
						found = true
						break
					end
				end
				
				if found == false then
					return false
				end
				
			elseif mode == 2 and owner ~= ply and not ply:IsSuperAdmin() then -- only super admins can take your code
				return false
			elseif mode == 3 and owner ~= ply then -- Nobody can take your code
				return false
			end
		end
	end

	hook.Add( "CanTool","simple_e2_theft_protection", function( ... )
		if not CPPI then
			hook.Remove( "CanTool", "simple_e2_theft_protection" )
			error( "Simple E2 Theft Protection unable to load: CPPI required." )
		end
		
		return check( ... )
	end)
end
