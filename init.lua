local S = minetest.get_translator(minetest.get_current_modname())

sum_jetpack = {}

-- temp fix for not overriding other flight methods
if not attachto_player then attachto_player = {} end

dofile(minetest.get_modpath("hero_jetpack") .. DIR_DELIM .. "entities.lua")
dofile(minetest.get_modpath("hero_jetpack") .. DIR_DELIM .. "items.lua")
dofile(minetest.get_modpath("hero_jetpack") .. DIR_DELIM .. "crafts.lua")