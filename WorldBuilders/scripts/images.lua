local WorldBuilders_ResourcePath = mod_loader.mods[modApi.currentMod].resourcePath

--Weapons
modApi:appendAsset("img/weapons/prime_wb_mold.png",    WorldBuilders_ResourcePath .. "img/weapons/prime_wb_mold.png")
modApi:appendAsset("img/weapons/brute_wb_consume.png", WorldBuilders_ResourcePath .. "img/weapons/brute_wb_consume.png")
modApi:appendAsset("img/weapons/science_wb_shift.png", WorldBuilders_ResourcePath .. "img/weapons/science_wb_shift.png")


modApi:appendAsset("img/combat/icons/icon_wb_forest_burn_cover.png", WorldBuilders_ResourcePath.."img/combat/icons/icon_wb_forest_burn_cover.png")
Location["combat/icons/icon_wb_forest_burn_cover.png"] = Point(-9, 19)