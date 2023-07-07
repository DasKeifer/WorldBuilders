WorldBuilders_Consume = Skill:new
{
	Name = "Consume",
    Class = "Brute",
    Description = "TODO",
	Icon = "weapons/brute_wb_consume.png",
	Rarity = 1,
	
	Explosion = "",
	
	Range = 1,
    Damage = 1,
	
	ConsumeBounce = -5,
	ProjectileHitBounce = 3,
	ProjectilePathBounce1 = 2,
	ProjectilePathBounce2 = -1,
	
	
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = { 1, 2 },
	
	
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
		Forest = Point(2,2),
		Forest2 = Point(1,2),
	},
}

Weapon_Texts.WorldBuilders_Consume_Upgrade1 = "+1 Range"
WorldBuilders_Consume_A = WorldBuilders_Consume:new
{
	UpgradeDescription = "Can fire up to one more tile",
	Range = 2,
}

Weapon_Texts.WorldBuilders_Consume_Upgrade2 = "+2 Range"
WorldBuilders_Consume_B = WorldBuilders_Consume:new
{
	UpgradeDescription = "Can fire up to two more tiles",
    Range = 3,
}

WorldBuilders_Consume_AB = WorldBuilders_Consume_B:new
{	
	Range = 4,
}

function WorldBuilders_Consume:GetTargetArea(point)
	local ret = PointList()
	
	for dir = DIR_START, DIR_END do
		local spaceBehind = point + DIR_VECTORS[(dir + 2) % 4]
		if Board:IsValid(spaceBehind) then
			for i = 1, self.Range do
				local curr = Point(point + DIR_VECTORS[dir] * i)
				if not Board:IsValid(curr) then
					break
				end
				
				ret:push_back(curr)
				
				if Board:IsBlocked(curr,PATH_PHASING) or Board:GetTerrain(curr) == TERRAIN_BUILDING then
					break
				end
			end
		end
	end
	
	return ret
end

function WorldBuilders_Consume:Consume_Spawn(skillEffect, consumeSpace, dir)
	ret:AddScript([[Board:AddPawn(GetCurrentMission():GetSpawnPointData(]]..consumeSpace:GetString() .. [[).type, ]] .. consumeSpace:GetString() .. [[)]])
	ret:AddScript([[Board:GetPawn(]]..consumeSpace:GetString() .. [[):SpawnAnimation()]])
	ret:AddScript([[GetCurrentMission():RemoveSpawnPoint(]]..consumeSpace:GetString() .. [[)]])
	ret:AddDelay(1)
	local spawnDamage = SpaceDamage(consumeSpace, 1, dir)
	--custom image spawnDamage.sImageMark
	skillEffect:AddDamage(spawnDamage)
end

function WorldBuilders_Consume:AddConsumeDamage(skillEffect, consumeSpace, damage)
	local consumeDamage = SpaceDamage(consumeSpace, damage)
	consumeDamage.iTerrain = TERRAIN_HOLE
	skillEffect:AddBounce(consumeSpace, self.ConsumeBounce)
	skillEffect:AddDelay(0.2)
	skillEffect:AddDamage(consumeDamage)
end

function WorldBuilders_Consume:Consume_Building(skillEffect, p1, p2, consumeSpace, dir)
	self:AddConsumeDamage(skillEffect, consumeSpace, DAMAGE_DEATH)
	
	local chainDamage = 2 * Board:GetHealth(consumeSpace)
	
	-- lightning from building to mech
	--skillEffect:AddAnimation(consumeSpace,"Lightning_Hit")
	
	local spaceInfront = p1 + DIR_VECTORS[dir]

	-- modified from vanilla lightning mech
	local hash = function(point) return point.x + point.y*10 end
	
	local explored = {[hash(p1)] = true}
	skillEffect:AddAnimation(p1, "Lightning_Attack_" .. dir)
	skillEffect:AddAnimation(p1, "Lightning_Hit")
	
	while Board:IsValid(spaceInfront) and spaceInfront ~= p2 do
		explored[hash(spaceInfront)] = true
		skillEffect:AddAnimation(spaceInfront, "Lightning_Attack_" .. dir)
		
		spaceInfront = Point(spaceInfront + DIR_VECTORS[dir])
	end
	
	local damage = SpaceDamage(spaceInfront, chainDamage)
	local origin = { [hash(spaceInfront)] = p1 }
	local todo = {spaceInfront}
	
	skillEffect:AddAnimation(p2,"Lightning_Hit")
	skillEffect:AddAnimation(p2, "Lightning_Attack_" .. dir)
	
	while #todo ~= 0 do
		local current = pop_back(todo)
		
		if not explored[hash(current)] then
			explored[hash(current)] = true
			
			if Board:IsPawnSpace(current) or Board:IsBuilding(current) then
			
				local direction = GetDirection(current - origin[hash(current)])
				damage.sAnimation = "Lightning_Attack_"..direction
				damage.loc = current
				damage.iDamage = Board:IsBuilding(current) and DAMAGE_ZERO or chainDamage
				skillEffect:AddDamage(damage)
				
				if not Board:IsBuilding(current) then
					skillEffect:AddAnimation(current,"Lightning_Hit")
				end
				
				for i = DIR_START, DIR_END do
					local neighbor = current + DIR_VECTORS[i]
					if not explored[hash(neighbor)] then
						todo[#todo + 1] = neighbor
						origin[hash(neighbor)] = current
					end
				end
			end		
		end
	end
end

function WorldBuilders_Consume:Consume_Terrain(skillEffect, projectileDamage, target, consumeSpace, dir)
	local consumedTerrain = Board:GetTerrain(consumeSpace)
	if consumedTerrain ~= TERRAIN_HOLE then
		self:AddConsumeDamage(skillEffect, consumeSpace, 0)
	end
	
	-- hole is the default effect
	
	-- Determine effect
	-- "Liquid" effects
	local applyFire = false
	local applyAcid = false
	local applySmoke = false
	if consumedTerrain == TERRAIN_WATER or consumedTerrain == TERRAIN_ICE or consumedTerrain == TERRAIN_ACID or consumedTerrain == TERRAIN_LAVA then
		local side1Damage = SpaceDamage(target + DIR_VECTORS[(dir + 1) % 4], 0, dir)
		local side2Damage = SpaceDamage(target + DIR_VECTORS[(dir - 1) % 4], 0, dir)
		
		-- water & ice are the default effect				
		if consumedTerrain == TERRAIN_ACID then
			applyAcid = true
			projectileDamage.iAcid = EFFECT_CREATE
			side1Damage.iAcid = EFFECT_CREATE
			side2Damage.iAcid = EFFECT_CREATE
		
		elseif consumedTerrain == TERRAIN_LAVA then
			applyFire = true
			projectileDamage.iFire = EFFECT_CREATE
			side1Damage.iFire = EFFECT_CREATE
			side2Damage.iFire = EFFECT_CREATE
		end
		
		return {side1Damage, side2Damage}
	
	-- "land" effects - also apply fire, acid, smoke
	else
		if consumedTerrain == TERRAIN_ROAD or consumedTerrain == TERRAIN_RUBBLE then
			projectileDamage.iDamage = 1
			
		elseif consumedTerrain == TERRAIN_SAND then
			projectileDamage.iDamage = 1
			local smokeDamage = SpaceDamage(consumeSpace, 0)
			smokeDamage.iSmoke = EFFECT_CREATE
			skillEffect:AddDamage(smokeDamage)
		
		elseif consumedTerrain == TERRAIN_MOUNTAIN then
			projectileDamage.iDamage = 3
		
		elseif consumedTerrain == TERRAIN_FOREST then
			projectileDamage.iDamage = 2
		end
		
		-- Fire 
		if Board:IsFire(consumeSpace) or consumedTerrain == TERRAIN_FIRE then
			applyFire = true
			projectileDamage.iFire = EFFECT_CREATE
		end
		
		-- acid
		if Board:IsAcid(consumeSpace) then
			applyAcid = true
			projectileDamage.iAcid = EFFECT_CREATE
		end
		
		-- smoke
		if Board:IsSmoke(consumeSpace) or consumedTerrain == TERRAIN_SAND then
			applySmoke = true
			projectileDamage.iSmoke = EFFECT_CREATE
		end
	end
end

function WorldBuilders_Consume:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	ret:AddBoardShake(0.1)
	ret:AddDelay(0.1)
	
	-- Note that this will be a valid space since we already checked in in get target area
	local dir = GetDirection(p2 - p1) % 4
	local consumeSpace = p1 + DIR_VECTORS[(dir + 2) % 4]
	
	-- always at least push the space (except for building consume) - may be modified later
	local projectileDamage = SpaceDamage(p2, 0, dir)
		
	-- if its a pawn, do special things
	local extraDamage = nil
	if Board:GetPawn(consumeSpace) ~= nil then
		ret:AddDamage(SpaceDamage(consumeSpace, 1, dir))
	elseif Board:IsSpawning(consumeSpace) then
		self:Consume_Spawn(ret, consumeSpace, dir)
	elseif Board:GetTerrain(consumeSpace) == TERRAIN_BUILDING then
		-- remove the push
		projectileDamage.iPush = DIR_NONE
		self:Consume_Building(ret, p1, p2, consumeSpace, dir)
	else -- terrain
		extraDamage = self:Consume_Terrain(ret, projectileDamage, p2, consumeSpace, dir)
	end
	
	-- in between spaces
	local spaceInfront = consumeSpace + (DIR_VECTORS[dir] * 2)
	while spaceInfront ~= p2 and Board:IsValid(spaceInfront) do
		local effectDamage = SpaceDamage(spaceInfront, 0)
		if projectileDamage.iFire == EFFECT_CREATE then
			effectDamage.iFire = EFFECT_CREATE
		end
		if projectileDamage.iAcid == EFFECT_CREATE then
			effectDamage.iAcid = EFFECT_CREATE
		end
		if projectileDamage.iSmoke == EFFECT_CREATE then
			effectDamage.iSmoke = EFFECT_CREATE
		end
		
		ret:AddBounce(spaceInfront, self.ProjectilePathBounce1)
		ret:AddDamage(effectDamage)
		ret:AddDelay(0.1)
		ret:AddBounce(spaceInfront, self.ProjectilePathBounce2)
		
		spaceInfront = spaceInfront + DIR_VECTORS[dir]
	end
	
	ret:AddBounce(p2, self.ProjectileHitBounce)
	ret:AddDamage(projectileDamage)
	
	if extraDamage ~= nil then
		for _, damage in ipairs(extraDamage) do
			ret:AddDamage(damage)
			ret:AddBounce(damage.loc, self.ProjectileHitBounce)
		end
	end
	
	return ret
end