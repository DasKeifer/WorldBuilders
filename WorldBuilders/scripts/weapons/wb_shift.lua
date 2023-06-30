WorldBuilders_Shift = Skill:new{
	Name = "Shift",
	Description = "TODO",
	Class = "Science",
	Icon = "weapons/science_wb_shift.png",
	Rarity = 1,
	Damage = 1,
	PowerCost = 1,
	LaunchSound = "/weapons/artillery_volley",
	ImpactSound = "/impact/generic/explosion",	
	Explosion = "",
	Upgrades = 2,
	UpgradeCost = { 2, 2 },
	
	Range = 3,
	
	--TipImage
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,1),
		Enemy = Point(2,1),
		Building = Point(3,1),
		Forest = Point(3,3),
		Forest2 = Point(2,4),
	},
}

Weapon_Texts.WorldBuilders_Shift_Upgrade1 = "+2 Range"
WorldBuilders_Shift_A = WorldBuilders_Shift:new
{
	UpgradeDescription = "Adds 2 range",
	Range = 3,
}

Weapon_Texts.WorldBuilders_Shift_Upgrade2 = "Project"
WorldBuilders_Shift_B = WorldBuilders_Shift:new
{
	UpgradeDescription = "Swap with any two tiles in range",
	TwoClick = true,
}

WorldBuilders_Shift_AB = WorldBuilders_Shift_B:new
{
	Range = 3,
}

function WorldBuilders_Shift:GetTargetArea(center)
	local ret = PointList()
	
	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local size = self.Range
	local corner = center - Point(size, size)
	
	local p = Point(corner)
		
	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = center - p
		local dist = math.abs(diff.x) + math.abs(diff.y)
		if Board:IsValid(p) and dist <= size and p ~= center then
			ret:push_back(p)
		end
		p = p + VEC_RIGHT
		if math.abs(p.x - corner.x) == (size*2+1) then
			p.x = p.x - (size*2+1)
			p = p + VEC_DOWN
		end
	end
	
	return ret
end

-- only used for B & AB weapons
function WorldBuilders_Shift_B:GetTargetArea(p1)
	return general_DiamondTarget(p1, self.Range)
end

function WorldBuilders_Shift_B:GetSecondTargetArea(center, target1)
	local ret = PointList()
	
	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local size = self.Range
	local corner = center - Point(size, size)
	
	local target2 = Point(corner)
		
	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = center - target2
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- Validity check
		if Board:IsValid(target2) and dist <= size then
			-- check it can be pushed
			if Board:IsPawnSpace(target1) and not self:TerrainCanBeOccupied(Board:GetTerrain(target2)) then
				if self:AddPushToOpenSpace(target1, target2) ~= DIR_NONE then
					ret:push_back(target2)
				end
			elseif Board:IsPawnSpace(target2) and not self:TerrainCanBeOccupied(Board:GetTerrain(target1)) then
				if self:AddPushToOpenSpace(target2, target1) ~= DIR_NONE then
					ret:push_back(target2)
				end
			else
				ret:push_back(target2)
			end
		end
		
		target2 = target2 + VEC_RIGHT
		if math.abs(target2.x - corner.x) == (size*2+1) then
			target2.x = target2.x - (size*2+1)
			target2 = target2 + VEC_DOWN
		end
	end
	
	return ret
end

function WorldBuilders_Shift:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	local p1Data = self:GetTerrainAndEffectData(p1)
	local p2Data = self:GetTerrainAndEffectData(p2)

	local success = true
	local p1Damage = SpaceDamage(p1, 0)
	local p1TerrainPre = SpaceDamage(p1, 0)
	local p1Terrain = SpaceDamage(p1, 0)
	self:ApplyEffect(p1Damage, p2Data)
	self:ApplyTerrain(p1Terrain, p1TerrainPre, p2Data)
	
	-- p1 is by necessity occupied
	if not self:TerrainCanBeOccupied(Board:GetTerrain(p2)) then
		local pushDir = self:AddPushToOpenSpace(p1, p2)
		-- for some reason trying to apply a building too causes it
		-- to not push so we add it twice
		if Board:GetTerrain(p2) == TERRAIN_BUILDING then
			p1Damage.iPush = pushDir
		end
		p1Terrain.iPush = pushDir
	end
	
	if success then
		local p2Damage = SpaceDamage(p2, 0)
		local p2Terrain = SpaceDamage(p2, 0)
		local p2TerrainPre = SpaceDamage(p2, 0)
		self:ApplyEffect(p2Damage, p1Data)
		self:ApplyTerrain(p2Terrain, p2TerrainPre, p1Data)
		
		-- todo add space symbol and/or animation
		ret:AddDamage(p1Damage)
		ret:AddBounce(p1, -5)
		ret:AddDamage(p2Damage)
		ret:AddBounce(p2, -5)
		
		ret:AddDamage(p1TerrainPre)
		ret:AddDamage(p2TerrainPre)
		ret:AddDamage(p1Terrain)
		ret:AddDamage(p2Terrain)
	end
	
	return ret
end

-- B & AB do different things - overwrite the skill effect
function WorldBuilders_Shift_B:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	ret:AddTeleport(p2, p2, FULL_DELAY)
	return ret
end

function WorldBuilders_Shift_B:GetFinalEffect(p1,p2,p3)
	local ret = SkillEffect()
	local dir = GetDirection(p3 - p2)
	
	local p2Data = self:GetTerrainAndEffectData(p2)
	local p3Data = self:GetTerrainAndEffectData(p3)

	local success = true
	local p2Damage = SpaceDamage(p2, 0)
	local p2Terrain = SpaceDamage(p2, 0)
	local p2TerrainPre = SpaceDamage(p2, 0)
	local p2BuildingPush = SpaceDamage(p2, 0)
	self:ApplyEffect(p2Damage, p3Data)
	self:ApplyTerrain(p2Terrain, p2TerrainPre, p3Data)
	if Board:IsPawnSpace(p2) and not self:TerrainCanBeOccupied(Board:GetTerrain(p3)) then
		local pushDir = self:AddPushToOpenSpace(p2, p3)
		if pushDir == DIR_NONE then
			return
		end
		-- for some reason trying to apply a building too causes it
		-- to not push so we add it twice
		if Board:GetTerrain(p3) == TERRAIN_BUILDING then
			p2Damage.iPush = pushDir
		end
		p2Terrain.iPush = pushDir
	end
	
	local p3Damage = SpaceDamage(p3, 0)
	local p3Terrain = SpaceDamage(p3, 0)
	local p3TerrainPre = SpaceDamage(p3, 0)
	local p3BuildingPush = SpaceDamage(p3, 0)
	if success then
		self:ApplyEffect(p3Damage, p2Data)
		self:ApplyTerrain(p3Terrain, p3TerrainPre, p2Data)
		if Board:IsPawnSpace(p3) and not self:TerrainCanBeOccupied(Board:GetTerrain(p2)) then
			local pushDir = self:AddPushToOpenSpace(p3, p2)
			if pushDir == DIR_NONE then
				return
			end
			-- for some reason trying to apply a building too causes it
			-- to not push so we add it twice
			if Board:GetTerrain(p2) == TERRAIN_BUILDING then
				p3Damage.iPush = pushDir
			end
			p3Terrain.iPush = pushDir
		end
	end
	
	if success then
		-- todo add space symbol and/or animation
		ret:AddDamage(p2Damage)
		ret:AddBounce(p2, -5)
		ret:AddDamage(p3Damage)
		ret:AddBounce(p3, -5)
		
		ret:AddDamage(p2TerrainPre)
		ret:AddDamage(p3TerrainPre)
		ret:AddDamage(p2Terrain)
		ret:AddDamage(p3Terrain)
	end
	
	return ret
end

function WorldBuilders_Shift:GetTerrainAndEffectData(space)
	return {
		terrain = Board:GetTerrain(space),
		customTile = Board:GetCustomTile(space),
		populated = Board:IsPowered(space),
		specialBuilding = Board:GetUniqueBuilding(space),
		currHealth = Board:GetHealth(space),
		maxHealth = Board:GetMaxHealth(space),
		fireType = Board:GetFireType(space),
		frozen = Board:IsFrozen(space),
		acid = Board:IsAcid(space),
		smoke = Board:IsSmoke(space),
	}
end

function WorldBuilders_Shift:ApplyEffect(spaceDamage, spaceData)
	if spaceData.fireType == FIRE_TYPE_NORMAL_FIRE then spaceDamage.iFire = EFFECT_CREATE end
	if spaceData.acid then spaceDamage.iAcid = EFFECT_CREATE end
	if spaceData.smoke then spaceDamage.iSmoke = EFFECT_CREATE end
end

-- If swapping a building in, the tile terrain doesn't always update rigth. For example, if
-- its a water tile, it will remain visually a water tile until its swapped with land
-- despite being ocnsidered a road tile. To get around we do a pre damage to change it
-- to road and then do the normal changes
function WorldBuilders_Shift:ApplyTerrain(spaceDamage, spaceDamagePreform, spaceData)
	-- Buildings will literally crash if we set to iTerrain and a pawn is on
	-- it so we have to do it via script instead.	
	-- We also have oddities with setting terrain so we just do it via post script.
	-- for whatever reason this works better
	-- Need to handle forest fires special since they use raod terrain and we can'table.concat
	-- directly set a space to a forest fire
	if spaceData.fireType == FIRE_TYPE_FOREST_FIRE then spaceData.terrain = TERRAIN_FOREST end
	
	if spaceData.terrain == TERRAIN_BUILDING then
		spaceDamagePreform.iTerrain = TERRAIN_ROAD
	end
	
	spaceDamage.sScript = [[Board:SetTerrain(]] .. spaceDamage.loc:GetString() .. [[, ]] .. spaceData.terrain .. [[)]]
	LOG("TERRAIN "..spaceData.terrain)
	
	if spaceData.fireType == FIRE_TYPE_FOREST_FIRE then
		LOG("FOREST FIRE")
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetFire(]] .. spaceDamage.loc:GetString() .. [[,true)]]
		
	end
	
	if spaceData.customTile ~= nil and spaceData.customTile ~= "" then
		LOG("CUSTOM TILE")
		spaceDamage.sScript = spaceDamage.sScript .. [[
				modApi.Board:SetCustomTile(]] .. spaceDamage.loc:GetString() .. [[,"]] .. spaceData.customTile .. [[")]]
	end
	if spaceData.specialBuilding ~= "" then
		LOG("SPECIAL BULDING")
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetUniqueBuilding(]] .. spaceDamage.loc:GetString() .. [[,"]] .. spaceData.specialBuilding .. [[")]]
	end
	LOG("Health "..spaceData.currHealth)
	spaceDamage.sScript = spaceDamage.sScript .. [[
			Board:SetHealth(]] .. spaceDamage.loc:GetString() .. [[,]] .. spaceData.currHealth .. [[,]] .. spaceData.maxHealth .. [[)]]

	spaceDamage.sScript = spaceDamage.sScript .. [[
			Board:SetFrozen(]] .. spaceDamage.loc:GetString() .. [[, ]] .. tostring(spaceData.frozen) .. [[, no_animation)]]

	if spaceData.populated then 
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetPopulated(true]] .. [[,]] .. spaceDamage.loc:GetString() .. [[)]]
	end
end

function WorldBuilders_Shift:TerrainCanBeOccupied(terrain)
	return terrain ~= TERRAIN_BUILDING and terrain ~= TERRAIN_MOUNTAIN
end

function WorldBuilders_Shift:IsOpenForPawn(space)
	return self:TerrainCanBeOccupied(Board:GetTerrain(space)) and not Board:IsPawnSpace(space)
end

-- For some reason when swapping buildings the push doesn't
-- go through on execution despite showing so we use a separate
-- push to get around this that should be applied before the
-- actual space damage
function WorldBuilders_Shift:AddPushToOpenSpace(p1, p2)
	local baseDir = GetDirection(p1 - p2)
	local dirs = {baseDir, (baseDir + 2) % 4, (baseDir + 1) % 4, (baseDir - 1) % 4}
	
	for _, dir in pairs(dirs) do
		local pushSpace = Point(p1 + DIR_VECTORS[dir])
		-- if its a valid space and either is open for the pawn or its the other space and that space
		-- can be occupied
		if Board:IsValid(pushSpace) and (self:IsOpenForPawn(pushSpace) or (pushSpace == p2 and self:TerrainCanBeOccupied(Board:GetTerrain(p1)))) then
			return dir
		end
	end
	
	return DIR_NONE
end