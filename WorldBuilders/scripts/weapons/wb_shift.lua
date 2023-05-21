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
	
	--custom
	Range = 1,
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
	DamageOuter = 1,
}

Weapon_Texts.WorldBuilders_Shift_Upgrade2 = "Project"
WorldBuilders_Shift_B = WorldBuilders_Shift:new
{
	UpgradeDescription = "Swap with any two tiles in range",
}

WorldBuilders_Shift_AB = WorldBuilders_Shift_B:new
{
	DamageOuter = 1,
}

-- First action is to move to any space in the forest
function WorldBuilders_Shift:GetTargetArea(point)
	local ret = PointList()
	
	-- if we aren't on a forest then return the point we are attack
	-- this is needed with how getGroupingOfSpaces works since it consideres the
	-- point to be of the right type or as part of the boarder
	if forestUtils.isAForest(point) then
		ret:push_back(point)
	else
		local forestGroup = forestUtils:getGroupingOfSpaces(point, forestUtils.isAForest)
		for k, v in pairs(forestGroup.group) do
			ret:push_back(Point(v))
		end
	end 
	return ret
end

function WorldBuilders_Shift:GetSkillEffect(p1, p2)
	return Move:GetSkillEffect(p1, p2)
end