local S = minetest.get_translator(minetest.get_current_modname())

local function has(mod_name)
  return minetest.get_modpath(mod_name) ~= nil
end

if true then
  local c = "default:coal_lump"
  if has("mcl_core") then
    c = "mcl_core:coal_lump"
  end

	local s = "default:coal_lump"
  if has("mcl_mobitems") then
    s = "mcl_mobitems:slimeball"
  elseif has("tnt") then
		s = "tnt:gunpowder"
	end

  minetest.register_craft({
    output = "hero_jetpack:jetpack_fuel 8",
    recipe = {
      {"",s,""},
      {c, c, c},
      {c, c, c}
    },
  })
  if has("mcl_core") then
    c = "mcl_core:charcoal_lump"
    minetest.register_craft({
      output = "hero_jetpack:jetpack_fuel 8",
      recipe = {
        {s,"", s},
        {c, c, c},
        {c, c, c}
      },
    })
  end
end

if true then
	local g = "default:tin_ingot"

  if has("vessels") then g = "vessels:steel_bottle"
  elseif has("mcl_mobitems") then g = "mcl_mobitems:blaze_rod"
  end

  local s = "defailt:paper"
	local l = "group:wool"
	if has("mcl_mobitems") then
		s = "mcl_mobitems:string"
		l = "mcl_mobitems:leather"
  elseif has("farming") then
    s = "farming:string"
	end

  local i = "default:furnace"
  if has("mcl_furnaces") then
    i = "mcl_furnaces:furnace"
  end

  local f = "hero_jetpack:jetpack_fuel"
	minetest.register_craft({
		output = "hero_jetpack:jetpack",
		recipe = {
			{l, f, l},
			{g, s, g},
			{i, l, i},
		},
	})
end

minetest.register_craft({
  output = "hero_jetpack:jetpack",
  recipe = {
    {"hero_jetpack:jetpack_fuel"},
    {"hero_jetpack:jetpack"}
  },
})