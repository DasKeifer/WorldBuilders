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
    SplashDamage = 1,
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
}

WorldBuilders_Mold_AB = WorldBuilders_Mold_B:new
{
	MakeMountains = true,
	Damage = 2,
}

function WorldBuilders_Mold:GetSecondTargetArea(p1,p2)
	local ret = PointList()
	
	for dir = DIR_START, DIR_END do
		local pushSpace = p2 + DIR_VECTORS[dir]
		-- TODO check occupied or something else instead - not the right check
		if Board:IsValid(pushSpace) and not Board:IsBlocked(pushSpace, PATH_PROJECTILE) then
			ret:push_back(pushSpace)
		end
	end
	
	return ret
end

function WorldBuilders_Mold:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	ret:AddDamage(SpaceDamage(p2, self.Damage))
	return ret
end

function WorldBuilders_Mold:GetFinalEffect(p1,p2,p3)
	local ret = SkillEffect()
	
	local dir = GetDirection(p3 - p2)
	local damage = SpaceDamage(p2, self.Damage, dir)
	if self.MakeMountains then
		damage.iTerrain = TERRAIN_MOUNTAIN
	else
		-- automagically does the animation
		damage.sPawn = "Wall"
	end
	
	if self.Erupt then
		damage.iFire = EFFECT_CREATE
		for dir = DIR_START, DIR_END do
			local splashSpace = p2 + DIR_VECTORS[dir]
			if splashSpace ~= p1 then
				ret:AddDamage(SpaceDamage(splashSpace, self.SplashDamage))
			end
		end
	end 
	
	ret:AddDamage(damage)
	
	return ret
end