local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("worldbuilders_color")

local files = {
	"th_forestfirer.png",
	"th_forestfirer_a.png",
	"th_forestfirer_w.png",
	"th_forestfirer_w_broken.png",
	"th_forestfirer_broken.png",
	"th_forestfirer_ns.png",
	"th_forestfirer_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

local a = ANIMS
a.wb_eater =         a.MechUnit:new{Image = "units/player/th_forestfirer.png",          PosX = -19, PosY = 5 }
a.wb_eatera =        a.MechUnit:new{Image = "units/player/th_forestfirer_a.png",        PosX = -19, PosY = 5, NumFrames = 4 }
a.wb_eaterw =        a.MechUnit:new{Image = "units/player/th_forestfirer_w.png",        PosX = -19, PosY = 5 }
a.wb_eater_broken =  a.MechUnit:new{Image = "units/player/th_forestfirer_broken.png",   PosX = -19, PosY = 10 }
a.wb_eaterw_broken = a.MechUnit:new{Image = "units/player/th_forestfirer_w_broken.png", PosX = -19, PosY = 10 }
a.wb_eater_ns =      a.MechIcon:new{Image = "units/player/th_forestfirer_ns.png" }


WorldBuilders_Eater = Pawn:new{	
	Name = "Eater",
	Class = "Brute",
	Health = 2,
	MoveSpeed = 3,
	Image = "wb_eater",
	ImageOffset = squadColors,
	SkillList = { "WorldBuilders_Consume" },
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true
}