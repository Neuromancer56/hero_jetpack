local S = minetest.get_translator(minetest.get_current_modname())


sum_jetpack.on_use = function(itemstack, user, pointed_thing)
  if user:get_attach() ~= nil then return itemstack end
  if itemstack:get_wear() >= 65534 then return itemstack end
  local pos = user:get_pos()
  local parachute = minetest.add_entity(pos, "hero_jetpack:jetpack_ENTITY")
  local ent = parachute:get_luaentity()
  -- if ent then ent._itemstack = itemstack end  --this was commented out
  minetest.after(0.1, function(ent, user, itemstack)
    if not ent or not user then return end
    local v = user:get_velocity()
    v = vector.multiply(v, 0.8)
    v.y = math.max(v.y, -50)
    sum_jetpack.attach_object(ent, user)
    ent.object:set_velocity(v)
    ent.object:set_properties({
			physical = true
		})
    minetest.sound_play("sum_jetpack_open", {
  		gain = 1,
  		object = ent.object,
  	})
    ent._itemstack = itemstack
    ent._flags.ready = true
  end, ent, user, ItemStack(itemstack))
  if not minetest.is_creative_enabled(user:get_player_name()) then
    itemstack:take_item()
  end
  return itemstack
end

minetest.register_tool("hero_jetpack:jetpack", {
	description = S("Jetpack"),
	_tt_help = S("30 seconds of use per fuel"),
	_doc_items_longdesc = S("Can be used to fly."),
	-- _doc_items_usagehelp = how_to_throw,
	inventory_image = "sum_jetpack_item.png",
	_repair_material = "mcl_core:coal_lump",
	stack_max = 1,
  -- range = 0,
	groups = { usable = 1, transport = 1 },
	--on_secondary_use = sum_jetpack.on_use,
  on_use = sum_jetpack.on_use,
	-- _on_dispense = sum_jetpack.on_use,
  _driver = nil,
  -- _mcl_uses = 30,
})

minetest.register_craftitem("hero_jetpack:jetpack_fuel", {
	description = S("Jetpack Fuel"),
	_tt_help = S("Used in crafting"),
	_doc_items_longdesc = S("Fuel for a jetpack."),
	-- _doc_items_usagehelp = how_to_throw,
	inventory_image = "sum_jetpack_fuel.png",
	stack_max = 16,
	groups = { craftitem=1, },
})
