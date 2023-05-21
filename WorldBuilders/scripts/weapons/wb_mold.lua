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
    Damage = 2,
    PowerCost = 0,
    Upgrades = 2,
    UpgradeCost = { 1, 2 },
	
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
}

function WorldBuilders_Mold:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	ret:AddDamage(4)
	ret:AddBounce(p2, 4)
	
	return ret
end