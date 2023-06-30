WorldBuilders_Mold = Skill:new
{
	Name = "Mold",
	Class = "Prime",
	Description = "TODO",
	Icon = "weapons/prime_wb_mold.png",
	Rarity = 1,
	
	Explosion = "",
	LaunchSound = "/weapons/titan_fist",
	
	Range = 1,
	PathSize = 1,
	Projectile = false,
    Damage = 1,
    SplashDamage = 0,
    PowerCost = 0,
    Upgrades = 2,
    UpgradeCost = { 2, 2 },
	
	TwoClick = true,
	
	-- custom
	MakeMountains = false,
	Erupt = false,
	
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
		Enemy2 = Point(2,1),
		Building = Point(3,2),
		Forest = Point(3,1),
		Fire = Point(3,1),
	},
}

Weapon_Texts.WorldBuilders_Mold_Upgrade1 = "Permanence"
WorldBuilders_Mold_A = WorldBuilders_Mold:new
{
	UpgradeDescription = "Erect mountains instead of rocks",
	MakeMountains = true,
	Damage = 2,
}

Weapon_Texts.WorldBuilders_Mold_Upgrade2 = "Eruption"
WorldBuilders_Mold_B = WorldBuilders_Mold:new
{
	UpgradeDescription = "Does 1 damage to surrounding tiles and sets target tile on fire",
	Erupt = true,
    SplashDamage = 1,
}

WorldBuilders_Mold_AB = WorldBuilders_Mold_B:new
{
	MakeMountains = true,
	Damage = 2,
}

function WorldBuilders_Mold:GetTargetArea(p1)
	local ret = PointList()
	
	for dir = DIR_START, DIR_END do
		local targetSpace = p1 + DIR_VECTORS[dir]
		if Board:GetTerrain(targetSpace) ~= TERRAIN_BUILDING and WorldBuilders_Mold:GetSecondTargetArea(p1, targetSpace):size() > 0 then
			ret:push_back(targetSpace)
		end
	end
	
	return ret
end

function WorldBuilders_Mold:GetSecondTargetArea(p1,p2)
	local ret = PointList()
	
	-- let them choose anyspace if the space is unoccupied or the pawn will die
	if (not Board:IsPawnSpace(p2)) or self.Damage >= Board:GetPawn(p2):GetHealth() then
		ret:push_back(p2)
		for dir = DIR_START, DIR_END do
			local targetSpace = p2 + DIR_VECTORS[dir]
			if Board:IsValid(targetSpace) and targetSpace ~= p1 then
				ret:push_back(targetSpace)
			end
		end
	-- otherwise they have to have a valid space to push to
	else
		for dir = DIR_START, DIR_END do
			local pushSpace = p2 + DIR_VECTORS[dir]	
			-- Make sure its a valid space
			if Board:IsValid(pushSpace) and self:TerrainCanBeOccupied(Board:GetTerrain(pushSpace)) then
				-- if its not occupied, push it
				if not Board:IsPawnSpace(pushSpace) then
					ret:push_back(pushSpace)
				-- if it is occupied, only push if the attack kills the enemy
				elseif self.SplashDamage >= Board:GetPawn(pushSpace):GetHealth() then
					ret:push_back(pushSpace)
				end
			end
		end
	end
	
	return ret
end

function WorldBuilders_Mold:GetSkillEffect(p1, p2)
	return self:DamageEffect(p1, p2, DIR_NONE)
end

function WorldBuilders_Mold:GetFinalEffect(p1,p2,p3)
	--if its the same space, there is no pawn or the pawn would die, don't push
	if p2 == p3 or not Board:IsPawnSpace(p2) or self.Damage >= Board:GetPawn(p2):GetHealth() then
		return self:GetSkillEffect(p1, p2)
	end
	return self:DamageEffect(p1, p2, GetDirection(p3 - p2))
end

function WorldBuilders_Mold:TerrainCanBeOccupied(terrain)
	return terrain ~= TERRAIN_BUILDING and terrain ~= TERRAIN_MOUNTAIN
end


--Rework to not push if already fatal
function WorldBuilders_Mold:DamageEffect(p1, p2, pushDir)
	local ret = SkillEffect()
	
	local damage = SpaceDamage(p2, self.Damage, pushDir)
	local terrain = SpaceDamage(p2, 0)
	
	local bounce = -3
	if self.MakeMountains then
		terrain.iTerrain = TERRAIN_MOUNTAIN
		bounce = -6
	else
		-- automagically does the animation
		terrain.sPawn = "Wall"
		local p2Terrain = Board:GetTerrain(p2)
		if p2Terrain == TERRAIN_HOLE or p2Terrain == TERRAIN_WATER or p2Terrain == TERRAIN_ACID or p2Terrain == TERRAIN_LAVA then
			--if p2Terrain == TERRAIN_FOREST then
				-- hide the forest fire icon
				--damage.sImageMark = "combat/icons/icon_wb_forest_burn_cover.png"
			--end
			terrain.iTerrain = TERRAIN_ROAD
		end
	end
	
	if self.Erupt then
		damage.iFire = EFFECT_CREATE
		for dir = DIR_START, DIR_END do
			local splashSpace = p2 + DIR_VECTORS[dir]
			if splashSpace ~= p1 then
				ret:AddDamage(SpaceDamage(splashSpace, self.SplashDamage))
				ret:AddBounce(splashSpace, bounce / 2)
			end
		end
	end 
	
	ret:AddDamage(damage)
	ret:AddBounce(p2, bounce)
	-- We need to allow for the pawn to scoot off or else
	-- the spawn will kill it
	if (not self.MakeMountains) and Board:IsPawnSpace(p2) then
		ret:AddDelay(0.4)
		ret:AddBounce(p2, bounce)
	end
	ret:AddBounce(p1, 1)
	ret:AddDamage(terrain)
	
	return ret
end