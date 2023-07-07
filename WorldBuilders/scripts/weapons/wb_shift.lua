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


function WorldBuilders_Shift:CanSpaceBeOccupied(point)
	return Board:GetTerrain(point) ~= TERRAIN_BUILDING and Board:GetTerrain(point) ~= TERRAIN_MOUNTAIN
end

function WorldBuilders_Shift:IsOpenForPawn(space)
	return self:CanSpaceBeOccupied(space) and not Board:IsPawnSpace(space)
end

function WorldBuilders_Shift:IsInvalidTargetSpace(p)
	-- don't allow swapping custom tiles or buildings
	return Board:GetCustomTile(p) ~= "" or Board:GetUniqueBuilding(p) ~= ""
end

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
				-- If the space is not an invalid target (multispace, non pushable pawn)
		if Board:IsValid(p) and dist <= size and p ~= center and not self:IsInvalidTargetSpace(p) and
				--Ensure we can occupy the space or be pushed
				(self:CanSpaceBeOccupied(p) or self:GetPushDirToOpenSpace(center, p) ~= DIR_NONE) then
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
function WorldBuilders_Shift_B:GetTargetArea(center)
	local ret = PointList()
	
	-- "borrowed" from general_DiamondTarget and modified to not
	-- include point
	local size = self.Range
	local corner = center - Point(size, size)
	
	local p = Point(corner)
		
	for i = 0, ((size*2+1)*(size*2+1)) do
		local diff = center - p
		local dist = math.abs(diff.x) + math.abs(diff.y)
		-- If the space is not an invalid target (multispace, non pushable pawn)
		if Board:IsValid(p) and dist <= size and not self:IsInvalidTargetSpace(p) then
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
		-- If the space is not an invalid target (multispace, non pushable pawn)
		if Board:IsValid(target2) and dist <= size and target2 ~= target1 and not self:IsInvalidTargetSpace(target2) then
			local goodTarget = true
			-- if the space we are swapping in can't be occupied
			if not self:CanSpaceBeOccupied(target2) then
				-- if its a pod or item, don't allow it -- too much work to swap pods as its mostly hardcoded in the game and I don't want to deal with memedit and no way to unset and item
				if Board:IsPawnSpace(target1) and self:GetPushDirToOpenSpace(target1, target2) == DIR_NONE then
					goodTarget = false
				end
			end
			if not self:CanSpaceBeOccupied(target1) then
				-- if its a pod or item, don't allow it -- too much work to swap pods as its mostly hardcoded in the game and I don't want to deal with memedit and no way to unset and item
				if Board:IsPawnSpace(target2) and self:GetPushDirToOpenSpace(target2, target1) == DIR_NONE then
					goodTarget = false
				end
			end
			
			if goodTarget then
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

function WorldBuilders_Shift:PushIfUnoccupiableSpace(p1, p2, spaceDamage, terrainDamage)
	if Board:IsPawnSpace(p1) and not self:CanSpaceBeOccupied(p2) then		
		local pushDir = self:GetPushDirToOpenSpace(p1, p2)
		-- for some reason trying to apply a building too causes it
		-- to not push so we add it twice
		if Board:GetTerrain(p2) == TERRAIN_BUILDING then
			spaceDamage.iPush = pushDir
		end
		terrainDamage.iPush = pushDir
	end
end

function WorldBuilders_Shift:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	local p1Data = self:GetTerrainAndEffectData(p1)
	local p2Data = self:GetTerrainAndEffectData(p2)

	local p1Damage = SpaceDamage(p1, 0)
	local p1TerrainPre = SpaceDamage(p1, 0)
	local p1Terrain = SpaceDamage(p1, 0)
	
	self:ApplyEffect(p1Damage, p2Data)
	self:ApplyTerrain(p1Terrain, p1TerrainPre, p2Data)
	self:PushIfUnoccupiableSpace(p1, p2, p1Damage, p1Terrain)
	
	local p2Damage = SpaceDamage(p2, 0)
	local p2Terrain = SpaceDamage(p2, 0)
	local p2TerrainPre = SpaceDamage(p2, 0)
	self:ApplyEffect(p2Damage, p1Data)
	self:ApplyTerrain(p2Terrain, p2TerrainPre, p1Data)
	-- by definition p1 is occupiable
	
	-- todo add space symbol and/or animation
	ret:AddDamage(p1Damage)
	ret:AddBounce(p1, -5)
	ret:AddDamage(p2Damage)
	ret:AddBounce(p2, -5)
	
	ret:AddDamage(p1TerrainPre)
	ret:AddDamage(p2TerrainPre)
	ret:AddDamage(p1Terrain)
	ret:AddDamage(p2Terrain)
	
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
	local p3Damage = SpaceDamage(p3, 0)
	local p3Terrain = SpaceDamage(p3, 0)
	local p3TerrainPre = SpaceDamage(p3, 0)
	local p3BuildingPush = SpaceDamage(p3, 0)
	
	self:ApplyEffect(p2Damage, p3Data)
	self:ApplyTerrain(p2Terrain, p2TerrainPre, p3Data)
	self:PushIfUnoccupiableSpace(p2, p3, p2Damage, p2Terrain)
	
	self:ApplyEffect(p3Damage, p2Data)
	self:ApplyTerrain(p3Terrain, p3TerrainPre, p2Data)
	self:PushIfUnoccupiableSpace(p3, p2, p3Damage, p3Terrain)
	
	-- todo add space symbol and/or animation
	ret:AddDamage(p2Damage)
	ret:AddBounce(p2, -5)
	ret:AddDamage(p3Damage)
	ret:AddBounce(p3, -5)
	
	ret:AddDamage(p2TerrainPre)
	ret:AddDamage(p3TerrainPre)
	ret:AddDamage(p2Terrain)
	ret:AddDamage(p3Terrain)
	
	return ret
end

function WorldBuilders_Shift:GetTerrainAndEffectData(space)
	return {
		origSpace = space,
		terrain = Board:GetTerrain(space),
		item = Board:GetItem(space),
		populated = Board:IsPowered(space),
		shielded = Board:IsShield(space),
		cracked = Board:IsCracked(space),
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
	
	-- Destroy the pod if the terrain is a no go. Simply switching to mountains does not
	-- destroy the pod and when testing various terrains, water works well for this
	if (Board:IsPod(spaceDamage.loc) or Board:IsItem(spaceDamage.loc)) and not self:CanSpaceBeOccupied(p) then
		spaceDamagePreform.iTerrain = TERRAIN_WATER
	elseif spaceData.terrain == TERRAIN_BUILDING then
		spaceDamagePreform.iTerrain = TERRAIN_ROAD
	end
	
	spaceDamage.sScript = [[Board:SetTerrain(]] .. spaceDamage.loc:GetString() .. [[, ]] .. spaceData.terrain .. [[)]]
	LOG("TERRAIN "..spaceData.terrain)
	
	if spaceData.fireType == FIRE_TYPE_FOREST_FIRE then
		LOG("FOREST FIRE")
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetFire(]] .. spaceDamage.loc:GetString() .. [[,true)]]
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
		
	-- If it should be shielded but isn't already
	if spaceData.shielded and not Board:IsShield(spaceDamage.loc) and not (Board:GetPawn(spaceDamage.loc) and Board:GetPawn(spaceDamage.loc):IsShield()) then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetShield(]] .. spaceDamage.loc:GetString() .. [[, true)]]
	-- if it should not be shielded and it is
	elseif not spaceData.shielded and (Board:IsShield(spaceDamage.loc) or (Board:GetPawn(spaceDamage.loc) and Board:GetPawn(spaceDamage.loc):IsShield())) then
		spaceDamage.sScript = spaceDamage.sScript .. [[
				Board:SetShield(]] .. spaceDamage.loc:GetString() .. [[, false)]]
	end
	
	if spaceData.cracked then 
		spaceDamage.iCrack = EFFECT_CREATE
	elseif Board:IsCracked(spaceDamage.loc) and spaceData.terrain ~= TERRAIN_BUILDING then
		-- with testing, water seems to be the magic one that makes it work...
		spaceDamagePreform.iTerrain = TERRAIN_WATER
	end
	
	-- remove items if the terrain is a no go
	if Board:IsItem(spaceDamage.loc) and not self:CanSpaceBeOccupied(p) then
		spaceDamage.sScript = spaceDamage.sScript .. [[
			Board:RemoveItem(]] .. spaceDamage.loc:GetString() .. [[)]]
	end
end

-- For some reason when swapping buildings the push doesn't
-- go through on execution despite showing so we use a separate
-- push to get around this that should be applied before the
-- actual space damage
function WorldBuilders_Shift:GetPushDirToOpenSpace(p1, p2)
	local baseDir = GetDirection(p1 - p2)
	local dirs = {baseDir, (baseDir + 2) % 4, (baseDir + 1) % 4, (baseDir - 1) % 4}
	
	for _, dir in pairs(dirs) do
		local pushSpace = Point(p1 + DIR_VECTORS[dir])
		-- if its a valid space and either is open for the pawn or its the other space and that space
		-- can be occupied
		if Board:IsValid(pushSpace) and (self:IsOpenForPawn(pushSpace) or (pushSpace == p2 and self:CanSpaceBeOccupied(p1))) then
			return dir
		end
	end
	
	return DIR_NONE
end