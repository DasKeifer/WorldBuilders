local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local mechPath = resourcePath .. "img/mechs/"

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mod = modApi:getCurrentMod()

local squadColors = modApi:getPaletteImageOffset("worldbuilders_color")

local files = {
	"th_entborg.png",
	"th_entborg_a.png",
	"th_entborg_w.png",
	"th_entborg_w_broken.png",
	"th_entborg_broken.png",
	"th_entborg_ns.png",
	"th_entborg_h.png"
}

for _, file in ipairs(files) do
	modApi:appendAsset("img/units/player/" .. file, mechPath .. file)
end

local a = ANIMS
a.wb_maker =         a.MechUnit:new{Image = "units/player/th_entborg.png",          PosX = -17, PosY = -11 }
a.wb_makera =        a.MechUnit:new{Image = "units/player/th_entborg_a.png",        PosX = -17, PosY = -11, NumFrames = 4 }
a.wb_makerw =        a.MechUnit:new{Image = "units/player/th_entborg_w.png",        PosX = -17, PosY = -9 }
a.wb_maker_broken =  a.MechUnit:new{Image = "units/player/th_entborg_broken.png",   PosX = -17, PosY =  2 }
a.wb_makerw_broken = a.MechUnit:new{Image = "units/player/th_entborg_w_broken.png", PosX = -20, PosY =  4 }
a.wb_maker_ns =      a.MechIcon:new{Image = "units/player/th_entborg_ns.png" }


WorldBuilders_MakerMech = Pawn:new{	
	Name = "Maker",
	Class = "Prime",
	Health = 3,
	MoveSpeed = 3,
	Image = "wb_maker",
	ImageOffset = squadColors,
	SkillList = { "WorldBuilders_Mold" },
	SoundLocation = "/mech/prime/punch_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}