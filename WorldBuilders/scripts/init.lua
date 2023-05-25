local mod = {
	id = "eplanum_worldbuilders",
	name = "World Builders",
	icon = "img/mod_icon.png",
	version = "0.1.0",
	modApiVersion = "2.9.2",
	gameVersion = "1.2.88",
	dependencies = {
        modApiExt = "1.21",
    }
}

function mod:init()	
	-- Assets
	require(self.scriptPath .. "images")
	require(self.scriptPath .. "palettes")

	-- Achievements... TBD
	-- require(self.scriptPath .. "achievements")

	-- Libs
	-- none
		
	-- Pawns
	require(self.scriptPath .. "mechs/wb_maker")
	require(self.scriptPath .. "mechs/wb_eater")
	require(self.scriptPath .. "mechs/wb_shaper")

	-- Weapons
	require(self.scriptPath .. "weapons/wb_mold")
	require(self.scriptPath .. "weapons/wb_consume")
	require(self.scriptPath .. "weapons/wb_shift")
	
	-- Shop... TBD
	-- modApi:addWeaponDrop("truelch_M10THowitzerArtillery")
	
	--Tutorial tips... TBD
	--require(self.scriptPath .. "tips")
end

function mod:load(options, version)
	modApi:addSquad(
		{
			id = "worldbuilders",
			"World Builders",
			"WorldBuilders_MakerMech",
			"WorldBuilders_EaterMech",
			"WorldBuilders_ShaperMech",
		},
		"World Builders",
		"... Something cool here...",
		self.resourcePath .. "img/squad_icon.png"
	)
end

return mod