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
	--two phase
	
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
	-- TODO
}

WorldBuilders_Shift_AB = WorldBuilders_Shift_B:new
{
	Range = 3,
}

function WorldBuilders_Shift:GetTargetArea(point)
	return general_DiamondTarget(point, self.Range)
end

function WorldBuilders_Shift:GetSkillEffect(p1, p2)
	local ret = SkillEffect()	
	
	

	--local p1Tile = Board:getTileTable(p1)
	--local p2Tile = Board:getTileTable(p2)
	
	
	
	local region = modapiext.board:getCurrentRegion()
	if not region then return nil end

	local p1Tile = nil
	local p1Tile = nil
	for i, entry in ipairs(region.player.map_data.map) do
		if entry.loc == p1 then
			p1Tile = entry
		elseif entry.loc == p2 then
			p2Tile = entry
		end
	end
	
	local tmp = p1Tile
	p1Tile = p2Tile
	p2Tile = tmp
	
	ret:AddDamage(SpaceDamage(p2,1,direction))
	
	return ret
end