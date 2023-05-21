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
    UpgradeCost = { 1, 1 },
	
	-- custom options
	ForestDamageBounce = -2,
	NonForestBounce = 2,
	ForestGenBounce = forestUtils.floraformBounce,
	
	PushTarget = false,
	SeekVek = true,
	SlowEnemyMaxMove = 2,
	
	ForestToExpand = 1,
	SlowEnemy = false,
	SlowEnemyAmount = 2,
	MinEnemyMove = 1,
	
    TipImage = {
		Unit = Point(2,3),
		Target = Point(2,2),
		Enemy = Point(2,2),
		Enemy2 = Point(1,1),
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

function WorldBuilders_Consume:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	ret:AddDamage(4)
	ret:AddBounce(p2, 4)
	
	return ret
end