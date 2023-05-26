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

function WorldBuilders_Shift:GetSpaceData(space)
	local data = {
		terrain = Board:GetTerrain(space),
		populated = Board:IsPowered(space),
		currHealth = Board:GetHealth(space),
		maxHealth = Board:GetMaxHealth(space),
		fire = Board:IsFire(space),
		acid = Board:IsAcid(space),
		smoke = Board:IsSmoke(space),
	}
	return data
end

function WorldBuilders_Shift:ApplySpaceDataAsSpaceDamage(spaceDamage, spaceData)
	if spaceData.fire then spaceDamage.iFire = EFFECT_CREATE end
	if spaceData.acid then spaceDamage.iAcid = EFFECT_CREATE end
	if spaceData.smoke then spaceDamage.iSmoke = EFFECT_CREATE end
	
	-- Buildings will literally crash if we set to iTerrain and a pawn is on
	-- it so we have to do it via script instead
	if spaceData.terrain == TERRAIN_BUILDING then
		spaceDamage.sScript = [[Board:SetTerrain(]] .. spaceDamage.loc:GetString() .. [[, TERRAIN_BUILDING)]]
	else
		spaceDamage.iTerrain = spaceData.terrain
	end	
	
	-- Set Health - currentHealth, maxHealth
	spaceDamage.sScript = spaceDamage.sScript .. [[
		Board:SetHealth(]] .. spaceDamage.loc:GetString() .. [[,]] .. spaceData.currHealth .. [[,]] .. spaceData.maxHealth .. [[)]]
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

--TODO Take into account our swapped tile
function WorldBuilders_Shift:AddPushToOpenSpace(spaceDamage, target, baseDir)
	local found = false
	local dirs = {(baseDir + 2) % 4, baseDir, (baseDir + 1) % 4, (baseDir - 1) % 4}
	
	for _, dir in pairs(dirs) do
		local pushSpace = Point(target + DIR_VECTORS[dir])
		if Board:IsValid(pushSpace) and self:IsOpenForPawn(pushSpace) then
			spaceDamage.iPush = dir
			found = true
			break
		end
	end
	
	return found
end

function WorldBuilders_Shift:GetSkillEffect(p1, p2)
	LOG("BUILDING")
	local ret = SkillEffect()
	local dir = GetDirection(p2 - p1)
	
	local p1Data = self:GetSpaceData(p1)
	local p2Data = self:GetSpaceData(p2)

	local success = true
	local p1Damage = SpaceDamage(p1, 0)
	local p1BuildingPush = SpaceDamage(p1, 0)
	self:ApplySpaceDataAsSpaceDamage(p1Damage, p2Data)
	--TODO some uneeded checks for self swap
	if Board:IsPawnSpace(p1) and not self:TerrainCanBeOccupied(Board:GetTerrain(p2)) then
		LOG("PUSHING")
		-- For some reason when swapping buildings the push doesn'table.concat
		-- go through on execution despite showing so we add another separate
		-- push to get around this
		if Board:GetTerrain(p2) == TERRAIN_BUILDING then
			success = self:AddPushToOpenSpace(p1BuildingPush, p1, dir)
		end
		if success then
			success = self:AddPushToOpenSpace(p1Damage, p1, dir)
		end
	end
	
	
	local p2Damage = SpaceDamage(p2, 0)
	if success then
		self:ApplySpaceDataAsSpaceDamage(p2Damage, p1Data)
		--[[ p1 by necessity can always be occupied. Need to check for the upgrade though
		if Board:IsPawnSpace(p2) and not self:TerrainCanBeOccupied(p1Data.terrain) then
			success = self:AddPushToOpenSpace(p2Damage, p2, dir)
		end]]--
	end
	
	if success then
		ret:AddDamage(p1BuildingPush)
		ret:AddDamage(p1Damage)
		ret:AddBounce(p1, -5)
		ret:AddDamage(p2Damage)
		ret:AddBounce(p2, -5)
	end
	
	return ret
end

function WorldBuilders_Shift_B:GetSecondTargetArea(p1,p2)

end

function WorldBuilders_Shift_B:GetFinalEffect(p1,p2,p3)

end