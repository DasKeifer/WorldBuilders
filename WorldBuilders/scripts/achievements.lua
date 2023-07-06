local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath

WorldBuildersAchievements = {
	zapPreDamage = 0,
	zapBuildingHealth = 0,
	spleefSkillBuilt = false,
}

local squad = "worldbuilders"
local achievements = {
	utilitarian = modApi.achievements:add{
		id = "utilitarian",
		name = "Utilitarian",
		tooltip = "Consume a building to prevent even more grid damage from happening",
		image = mod.resourcePath .. "img/achievements/utilitarian.png",
		squad = squad,
	},

	greatwall = modApi.achievements:add{
		id = "greatwall",
		name = "The Great Wall",
		tooltip = "Complete a mission with mountains connecting one side of the board to the other",
		image = mod.resourcePath .. "img/achievements/greatwall.png",
		squad = squad,
	},

	spleef = modApi.achievements:add{
		id = "spleef",
		name = "Spleef!",
		tooltip = "Drop an enemy into the void by swapping out the terrain under them",
		image = mod.resourcePath .. "img/achievements/spleef.png",
		squad = squad,
	},
}

local function isGame()
	return Game ~= nil and GAME ~= nil
end

local function isRightSquad()
	return isGame() and GAME.additionalSquadData.squad == squad
end

local function isInMission()
	local mission = GetCurrentMission()
	return isGame() and mission ~= nil and mission ~= Mission_Test
end

-- Great Wall
local function searchForMountains(doReverse)
	local possibleLoc = {}
	local size = Board:GetSize()
	local yPoint = 0
	local yGoal = size.y - 1
	local baseDir = DIR_DOWN
	local closest = 0
	if doReverse then
		yPoint = size.y - 1
		yGoal = 0
		baseDir = DIR_UP
	end
	
	-- Create starting points
	for x = 0, size.x - 1 do
		local point = Point(x, yPoint)
		if Board:GetTerrain(point) == TERRAIN_MOUNTAIN then
			possibleLoc[#possibleLoc + 1] = point
		end
	end	
	
	local hash = function(point) return point.x + point.y * size.x end
	local explored = {}
	while #possibleLoc ~= 0 do
		local current = pop_back(possibleLoc)
		
		if not explored[hash(current)] then
			explored[hash(current)] = true
			
			if Board:GetTerrain(current) == TERRAIN_MOUNTAIN then
				local value = current.y + 1
				if doReverse then
					value = size.y - current.y
				end
				
				if value > closest then
					closest = value
					if closest >= size.y then
						break
					end
				end
			
				-- in reverse search priority
				local back = (baseDir + 2) % 4
				local front = baseDir
				local side1 = (baseDir + 1) % 4
				local side2 = (baseDir + 3) % 4
				local points = {current + DIR_VECTORS[back], current + DIR_VECTORS[back] + DIR_VECTORS[side1], current + DIR_VECTORS[back] + DIR_VECTORS[side2],
								current + DIR_VECTORS[side1], current + DIR_VECTORS[side2],
								current + DIR_VECTORS[front] + DIR_VECTORS[side1], current + DIR_VECTORS[front] + DIR_VECTORS[side2], current + DIR_VECTORS[front]}
				for _, neighbor in pairs(points) do
					if Board:IsValid(neighbor) and not explored[hash(neighbor)] then
						possibleLoc[#possibleLoc + 1] = neighbor
					end
				end
			end	
		end
	end
	
	return closest
end

local function sideToSideMountainChainLength()
	-- left bottom to top right check, then reverse check
	LOG("PASS 1")
	local length = searchForMountains(false)
	if length < Board:GetSize().x then
		LOG("PASS 2")
		local length2 = searchForMountains(true)
		if length2 > length then
			return length2
		end
	end
	return length
end

local baseTooltip = achievements.greatwall.getTooltip
achievements.greatwall.getTooltip = function(self)
	local result = baseTooltip(self)
	
	if (not achievements.greatwall:isComplete()) and isInMission() then
		result = result .. "\n\nCurrent Mountain Chain Length: " .. tostring(sideToSideMountainChainLength() .. " / " .. Board:GetSize().x)
		--result = result .. "\n\nCurrent Mountain Chain Length: " .. " / " .. Board:GetSize().x
	end

	return result
end

-- utilitarian
local function determineTotalGridThread()
	local gridThreat = 0
	
	-- TODO: Look through all queued effects
	
	return gridThreat
end

-- Great Wall
function WorldBuildersAchievements.onMissionEndHook(mission)
	if (not achievements.greatwall:isComplete() and sideToSideMountainChainLength() >= Board:GetSize().x) then
		achievements.greatwall:trigger()
	end
end

-- Utilitarian
function WorldBuildersAchievements.onSkillBuildHook(mission, pawn, weaponId, p1, p2, skillEffect)
	if isRightSquad() and not achievements.utilitarian:isComplete() then				
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		-- check the conditions to see if this built skill satisfies the requirement

		LOG(weaponId)
		if string.sub(weaponId, 1 , string.len("WorldBuilders_Consume")) == "WorldBuilders_Consume" then
			-- reset the flag. We do this inside the check because other
			-- weapons can be called between the final skill build hook and the
			-- skill end hook
			WorldBuildersAchievements.zapBuildingHealth = 0
		
			LOG("BUILDING CONSUME")
			local consumeSpace = p1 + DIR_VECTORS[(dir + 2) % 4]
			if Board:GetTerrain(consumeSpace) == TERRAIN_BUILDING then
				WorldBuildersAchievements.zapBuildingHealth = Board:GetHealth(consumeSpace)
			end
		end
	end
end

-- Spleef
function WorldBuildersAchievements.onFinalEffectBuildHook(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	if isRightSquad() and not achievements.spleef:isComplete() then				
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		-- check the conditions to see if this built skill satisfies the requirement

		if string.sub(weaponId, 1 , string.len("WorldBuilders_Shift")) == "WorldBuilders_Shift" then
			-- reset the flag. We do this inside the check because other
			-- weapons can be called between the final skill build hook and the
			-- skill end hook
			WorldBuildersAchievements.spleefSkillBuilt = false
		
			-- update here
			-- Skip if not a multitarget - but how?
			-- for p2 & p3 to see if they will fall into a void when swapped
			if (Board:GetTerrain(p3) == TERRAIN_HOLE and Board:GetPawn(p2) ~= nil and Board:GetPawn(p2):IsEnemy() and (Board:GetPawn(p2):IsFrozen() or not Board:GetPawn(p2):IsFlying())) or 
			   (Board:GetTerrain(p2) == TERRAIN_HOLE and Board:GetPawn(p3) ~= nil and Board:GetPawn(p3):IsEnemy() and (Board:GetPawn(p3):IsFrozen() or not Board:GetPawn(p3):IsFlying())) then
				WorldBuildersAchievements.spleefSkillBuilt = true
			end
		end
	end
end

-- Utilitarian
function WorldBuildersAchievements.onSkillStartHook(mission, pawn, weaponId, p1, p2)
	if isRightSquad() and not achievements.utilitarian:isComplete()then
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		if string.sub(weaponId, 1 , string.len("WorldBuilders_Consume")) == "WorldBuilders_Consume" and WorldBuildersAchievements.zapBuildingHealth > 0 then
			WorldBuildersAchievements.zapPreDamage = determineTotalGridThread()
		end
	end
end

-- Utilitarian
function WorldBuildersAchievements.onSkillEndHook(mission, pawn, weaponId, p1, p2)
	if isRightSquad() and not achievements.utilitarian:isComplete()then
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		if string.sub(weaponId, 1 , string.len("WorldBuilders_Consume")) == "WorldBuilders_Consume" and WorldBuildersAchievements.zapBuildingHealth > 0 then
			if WorldBuildersAchievements.zapPreDamage - determineTotalGridThread() > zapBuildingHealth then
				achievements.utilitarian:trigger()
			end
		end
	end
end

-- Spleef
function WorldBuildersAchievements.onFinalEffectEndHook(mission, pawn, weaponId, p1, p2, p3)
	if isRightSquad() and not achievements.spleef:isComplete()then
		-- make sure we have the actual weaponid
		if type(weaponId) == 'table' then
			weaponId = weaponId.__Id
		end 
		
		if string.sub(weaponId, 1 , string.len("WorldBuilders_Shift")) == "WorldBuilders_Shift" and WorldBuildersAchievements.spleefSkillBuilt then
			achievements.spleef:trigger()
		end
	end
end


function WorldBuildersAchievements:addHooks()
	modApi.events.onMissionEnd:subscribe(self.onMissionEndHook)
	
	modapiext:addSkillBuildHook(self.onSkillBuildHook)
	modapiext:addSkillEndHook(self.onSkillEndHook)
	modapiext:addFinalEffectBuildHook(self.onFinalEffectBuildHook)
	modapiext:addFinalEffectEndHook(self.onFinalEffectEndHook)
end