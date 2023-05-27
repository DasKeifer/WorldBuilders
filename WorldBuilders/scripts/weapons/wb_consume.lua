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
    Damage = 3,
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

function WorldBuilders_Consume:Consume_Spawn(skillEffect, consumeSpace)
	ret:AddScript([[Board:AddPawn(GetCurrentMission():GetSpawnPointData(]]..consumeSpace:GetString() .. [[).type, ]] .. consumeSpace:GetString() .. [[)]])
	ret:AddScript([[Board:GetPawn(]]..consumeSpace:GetString() .. [[):SpawnAnimation()]])
	ret:AddScript([[GetCurrentMission():RemoveSpawnPoint(]]..consumeSpace:GetString() .. [[)]])
	ret:AddDelay(1)
	local spawnDamage = SpaceDamage(consumeSpace, 1, dir)
	--custom image spawnDamage.sImageMark
	skillEffect:AddDamage(spawnDamage)
end

function WorldBuilders_Consume:Consume_Building(skillEffect, p1, p2, consumeSpace, dir)
	local chainDamage = 2 * Board:GetHealth(consumeSpace)
	
	local consumeDamage = SpaceDamage(consumeSpace, DAMAGE_DEATH)
	consumeDamage.iTerrain = TERRAIN_HOLE
	skillEffect:AddDamage(consumeDamage)
	
	-- lightning from building to mech
	skillEffect:AddAnimation(consumeSpace,"Lightning_Hit")
	
	local spaceInfront = p1 + DIR_VECTORS[dir]

	-- modified from vanilla lightning mech
	local hash = function(point) return point.x + point.y*10 end
	
	local explored = {[hash(p1)] = true}
	skillEffect:AddAnimation(p1, "Lightning_Attack_" .. dir)
	skillEffect:AddAnimation(p1, "Lightning_Hit")
	
	LOG("next space")
	while Board:IsValid(spaceInfront) and spaceInfront ~= p2 do
		LOG("space"..spaceInfront:GetString())
		explored[hash(spaceInfront)] = true
		skillEffect:AddAnimation(spaceInfront, "Lightning_Attack_" .. dir)
		skillEffect:AddAnimation(spaceInfront, "Lightning_Hit")
		
		spaceInfront = Point(spaceInfront + DIR_VECTORS[dir])
	end
	
	local damage = SpaceDamage(spaceInfront, chainDamage)
	local origin = { [hash(spaceInfront)] = p1 }
	local todo = {spaceInfront}
	
	LOG("SEARCHING")
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
		local consumeDamage = SpaceDamage(consumeSpace, 0)
		consumeDamage.iTerrain = TERRAIN_HOLE
		skillEffect:AddDamage(consumeDamage)
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
			projectileDamage.iAcid = true
			side1Damage.iAcid = true
			side2Damage.iAcid = true
		
		elseif consumedTerrain == TERRAIN_LAVA then
			applyFire = true
			projectileDamage.iFire = true
			side1Damage.iFire = true
			side2Damage.iFire = true
		
		end
		
		skillEffect:AddDamage(side1Damage)
		skillEffect:AddDamage(side2Damage)
	
	-- "land" effects - also apply fire, acid, smoke
	else
		if consumedTerrain == TERRAIN_ROAD or consumedTerrain == TERRAIN_RUBBLE then
			projectileDamage.iDamage = 1
			
		elseif consumedTerrain == TERRAIN_SAND then
			projectileDamage.iDamage = 1
			local smokeDamage = SpaceDamage(consumeSpace, 0)
			smokeDamage.iSmoke = true
			skillEffect:AddDamage(smokeDamage)
		
		elseif consumedTerrain == TERRAIN_MOUNTAIN then
			projectileDamage.iDamage = 3
		
		elseif consumedTerrain == TERRAIN_FOREST then
			projectileDamage.iDamage = 2
		end
		
		-- Fire 
		if Board:IsFire(consumeSpace) or consumedTerrain == TERRAIN_FIRE then
			applyFire = true
			projectileDamage.iFire = true
		end
		
		-- acid
		if Board:IsAcid(consumeSpace) then
			applyAcid = true
			projectileDamage.iAcid = true
		end
		
		-- smoke
		if Board:IsSmoke(consumeSpace) or consumedTerrain == TERRAIN_SAND then
			applySmoke = true
			projectileDamage.iSmoke = true
		end
	end
	
	-- in between spaces
	if applyFire or applyAcid or applySmoke then
		local spaceInfront = p1 + DIR_VECTORS[dir]
		while spaceInfront ~= p2 do
			local effectDamage = SpaceDamage(spaceInfront, 0)
			if applyFire then
				effectDamage.iFire = EFFECT_CREATE
			elseif applyAcid then
				effectDamage.iAcid = EFFECT_CREATE
			else --applySmoke
				effectDamage.iSmoke = EFFECT_CREATE
			end
			skillEffect:AddDamage(effectDamage)
			spaceInfront = spaceInfront + DIR_VECTORS[dir]
		end
	end
end

function WorldBuilders_Consume:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	ret:AddBoardShake(0.1)
	ret:AddDelay(0.1)
	
	-- Note that this will be a valid space since we already checked in in get target area
	local dir = GetDirection(p2 - p1) % 4
	local spaceBehind = p1 + DIR_VECTORS[(dir + 2) % 4]
	
	-- always at least push the space (except for building consume) - may be modified later
	local projectileDamage = SpaceDamage(p2, 0, dir)
		
	-- if its a pawn, do special things
	if Board:GetPawn(spaceBehind) ~= nil then
		ret:AddDamage(SpaceDamage(spaceBehind, 1, dir))
	elseif Board:IsSpawning(spaceBehind) then
		self:Consume_Spawn(ret, spaceBehind)
	elseif Board:GetTerrain(spaceBehind) == TERRAIN_BUILDING then
		self:Consume_Building(ret, p1, p2, spaceBehind, dir)
	else -- terrain
		self:Consume_Terrain(ret, projectileDamage, p2, spaceBehind, dir)
	end
	
	ret:AddDamage(projectileDamage)
	
	return ret
end