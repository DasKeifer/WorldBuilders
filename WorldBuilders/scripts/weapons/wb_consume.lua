WorldBuilders_Consume = Skill:new
{
	Name = "Consume",
    Class = "Brute",
    Description = "TODO",
	Icon = "weapons/brute_wb_consume.png",
	Rarity = 1,
	
	Explosion = "",
	
	Range = 2,
    Damage = 1,
	
    PowerCost = 1,
    Upgrades = 2,
    UpgradeCost = { 1, 1 },
	
	
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
		Forest = Point(2,2),
		Forest2 = Point(1,2),
	},
}

Weapon_Texts.WorldBuilders_Consume_Upgrade1 = "+2 Range"
WorldBuilders_Consume_A = WorldBuilders_Consume:new
{
	UpgradeDescription = "Can fire up to two more tiles",
	Range = 3,
}

Weapon_Texts.WorldBuilders_Consume_Upgrade2 = "+1 Damage"
WorldBuilders_Consume_B = WorldBuilders_Consume:new
{
	UpgradeDescription = "Attacks that do damage gain 1 more damage",
    Damage = 2,
}

WorldBuilders_Consume_AB = WorldBuilders_Consume_B:new
{	
	Range = 3,
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
				
				if Board:IsBlocked(curr,PATH_PHASING) then
					break
				end
			end
		end
	end
	
	return ret
end

function WorldBuilders_Consume:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	-- Note that this will be a valid space since we already checked in in get target area
	local dir = GetDirection(p2 - p1) % 4
	local spaceBehind = p1 + DIR_VECTORS[(dir + 2) % 4]
	
	-- if its a pawn, do special things
	if Board:GetPawn(spaceBehind) ~= nil then
		ret:AddDamage(SpaceDamage(spaceBehind, 1, dir))
	elseif Board:IsSpawning(spaceBehind) then
		LOG("EMERGING!!!!"..spaceBehind:GetString())
		ret:AddScript([[Board:AddPawn(GetCurrentMission():GetSpawnPointData(]]..spaceBehind:GetString() .. [[).type, ]] .. spaceBehind:GetString() .. [[)]])
		ret:AddScript([[Board:GetPawn(]]..spaceBehind:GetString() .. [[):SpawnAnimation()]])
		ret:AddScript([[GetCurrentMission():RemoveSpawnPoint(]]..spaceBehind:GetString() .. [[)]])
		ret:AddDelay(1)
		local spawnDamage = SpaceDamage(spaceBehind, 1, dir)
		--custom image spawnDamage.sImageMark
		ret:AddDamage(spawnDamage)
	else
		-- if its not a pawn, consume and do an effect based on its
		local consumedTerrain = Board:GetTerrain(spaceBehind)
		local projectileDamage = SpaceDamage(p2, 0, dir)
		
		if consumedTerrain ~= TERRAIN_HOLE then
			local consumeDamage = SpaceDamage(spaceBehind, 0)
			if consumedTerrain == TERRAIN_BUILDING then
				consumeDamage.iDamage = DAMAGE_DEATH
			end

			consumeDamage.iTerrain = TERRAIN_HOLE
			ret:AddDamage(consumeDamage)
		end
		
		-- hole is the default effect
		
		-- Determine effect
		-- "Liquid" effects
		if consumedTerrain == TERRAIN_WATER or consumedTerrain == TERRAIN_ICE or consumedTerrain == TERRAIN_ACID or consumedTerrain == TERRAIN_LAVA then
			local side1Damage = SpaceDamage(p2 + DIR_VECTORS[(dir + 1) % 4], 0, dir)
			local side2Damage = SpaceDamage(p2 + DIR_VECTORS[(dir - 1) % 4], 0, dir)
			
			-- water & ice are the default effect				
			if consumedTerrain == TERRAIN_ACID then
				projectileDamage.iAcid = true
				side1Damage.iAcid = true
				side2Damage.iAcid = true
			
			elseif consumedTerrain == TERRAIN_LAVA then
				projectileDamage.iFire = true
				side1Damage.iFire = true
				side2Damage.iFire = true
			
			end
			
			ret:AddDamage(side1Damage)
			ret:AddDamage(side2Damage)
		
		-- "land" effects - also apply fire, acid, smoke
		else
			if consumedTerrain == TERRAIN_BUILDING then
				local chainDamage = 2 * Board:GetHealth(spaceBehind)
				
				ret:AddAnimation(p1,"Lightning_Hit")
				
				local spaceInfront = p1 + DIR_VECTORS[dir]
	
				-- modified from vanilla lightning mech
				local damage = SpaceDamage(spaceInfront, chainDamage)
				local hash = function(point) return point.x + point.y*10 end
				local explored = {[hash(p1)] = true}
				local origin = { [hash(spaceInfront)] = p1 }
				
				
				local todo = {spaceInfront}
				while spaceInfront ~= p2 do
					spaceInfront = spaceInfront + DIR_VECTORS[dir]
					todo[#todo + 1] = spaceInfront
				end
				
				while #todo ~= 0 do
					local current = pop_back(todo)
					
					if not explored[hash(current)] then
						explored[hash(current)] = true
						
						if Board:IsPawnSpace(current) or Board:IsBuilding(current) then
						
							local direction = GetDirection(current - origin[hash(current)])
							damage.sAnimation = "Lightning_Attack_"..direction
							damage.loc = current
							damage.iDamage = Board:IsBuilding(current) and DAMAGE_ZERO or chainDamage
							ret:AddDamage(damage)
							
							if not Board:IsBuilding(current) then
								ret:AddAnimation(current,"Lightning_Hit")
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
			
			elseif consumedTerrain == TERRAIN_ROAD or consumedTerrain == TERRAIN_RUBBLE then
				projectileDamage.iDamage = 1
				
			elseif consumedTerrain == TERRAIN_SAND then
				projectileDamage.iDamage = 1
				local smokeDamage = SpaceDamage(spaceBehind, 0)
				smokeDamage.iSmoke = true
				ret:AddDamage(smokeDamage)
			
			elseif consumedTerrain == TERRAIN_MOUNTAIN then
				projectileDamage.iDamage = 3
			
			elseif consumedTerrain == TERRAIN_FOREST then
				projectileDamage.iDamage = 2
			end
			
			-- Fire 
			if Board:IsFire(spaceBehind) or consumedTerrain == TERRAIN_FIRE then
				projectileDamage.iFire = true
			end
			
			-- acid
			if Board:IsAcid(spaceBehind) then
				projectileDamage.iAcid = true
			end
			
			-- smoke
			if Board:IsSmoke(spaceBehind) or consumedTerrain == TERRAIN_SAND then
				projectileDamage.iSmoke = true
				-- TODO: Any in between tile too?
			end
		end
		
		-- to make things easier, we just add all damage for buildings above
		if consumedTerrain ~= TERRAIN_BUILDING then
			ret:AddDamage(projectileDamage)
		end
	end
	
	return ret
end