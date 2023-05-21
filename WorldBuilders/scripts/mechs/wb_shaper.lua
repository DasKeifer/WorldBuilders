local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset(worldbuilders_color)

local files = {
	"th_arbiformer.png",
	"th_arbiformer_a.png",
	"th_arbiformer_w.png",
	"th_arbiformer_w_broken.png",
	"th_arbiformer_broken.png",
	"th_arbiformer_ns.png",
	"th_arbiformer_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

local a = ANIMS
a.wb_shaper =         a.MechUnit:new{Image = "units/player/th_arbiformer.png",          PosX = -22, PosY = -7 }
a.wb_shapera =        a.MechUnit:new{Image = "units/player/th_arbiformer_a.png",        PosX = -22, PosY = -7, NumFrames = 4 }
a.wb_shaperw =        a.MechUnit:new{Image = "units/player/th_arbiformer_w.png",        PosX = -22, PosY = -6 }
a.wb_shaper_broken =  a.MechUnit:new{Image = "units/player/th_arbiformer_broken.png",   PosX = -22, PosY =  2 }
a.wb_shaperw_broken = a.MechUnit:new{Image = "units/player/th_arbiformer_w_broken.png", PosX = -22, PosY =  5 }
a.wb_shaper_ns =      a.MechIcon:new{Image = "units/player/th_arbiformer_ns.png" }


WorldBuilders_ShaperMech = Pawn:new{
	Name = "Shaper",
	Class = "Science",
	Health = 2,
	MoveSpeed = 4,
	Image = "wb_shaper",
	ImageOffset = squadColors,
	SkillList = { "WorldBuilders_Shift" },
	SoundLocation = "/mech/science/pulse_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}