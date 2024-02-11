local S = minetest.get_translator(minetest.get_current_modname())

local mcl = minetest.get_modpath("mcl_core") ~= nil

attachto_player.player = {}

-- Staticdata handling because objects may want to be reloaded
function sum_jetpack.get_staticdata(self)
	local itemstack = "sum_jetpack:jetpack"
	if self._itemstack then
		itemstack = self._itemstack:to_table()
	end
	local data = {
		_lastpos = self._lastpos,
		_age = self._age,
		_itemstack = itemstack,
		_disabled = self._disabled,
	}
	return minetest.serialize(data)
end
function sum_jetpack.on_activate(self, staticdata, dtime_s)
	local data = minetest.deserialize(staticdata)
	if data then
		self._lastpos = data._lastpos
		self._age = data._age
		self._disabled = data._disabled
		if self._itemstack == nil and data._itemstack ~= nil then
			self._itemstack = ItemStack(data._itemstack)
		end
	end
	self._sounds = {
		idle = {
			time = 0,
			handle = nil
		},
		boost = {
			time = 0,
			handle = nil
		},
	}
	self._flags = {}
end


sum_jetpack.set_attach = function(self)
  if not self._driver then return end
	self.object:set_attach(self._driver, "",
		{x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
end

sum_jetpack.attach_object = function(self, obj)
	self._driver = obj
	if self._driver and self._driver:is_player() then
		local old_attacher = attachto_player.player[self._driver:get_player_name()]
		if old_attacher ~= nil then
			old_attacher._disabled = true
			if type(old_attacher._on_detach) == "function" then
				old_attacher._on_detach(old_attacher, nil) end
		end
		attachto_player.player[self._driver:get_player_name()] = self
	end

	sum_jetpack.set_attach(self)

	local yaw = self.object:get_yaw()
  if self._driver then
    self.object:set_yaw(minetest.dir_to_yaw(self._driver:get_look_dir()))
  end
end

-- make sure the player doesn't get stuck
minetest.register_on_joinplayer(function(player)
	attachto_player.player[player:get_player_name()] = nil
	playerphysics.remove_physics_factor(player, "gravity", "flight")
	playerphysics.remove_physics_factor(player, "speed", "flight")
end)

minetest.register_on_dieplayer(function(player, reason)
	if attachto_player.player[player:get_player_name()] ~= nil then
		local old_attacher = attachto_player.player[player:get_player_name()]
		if type(old_attacher._on_death) == "function" then
			old_attacher._on_death(old_attacher, nil) end
		sum_jetpack.on_death(old_attacher, true)
		old_attacher.object:remove()
		attachto_player.player[player:get_player_name()] = nil
	end
end)

sum_jetpack.detach_object = function(self, change_pos)
	if self._driver and self._driver:is_player() then

		local name = self._driver:get_player_name()
		if mcl then mcl_player.player_attached[name] = false end

		attachto_player.player[self._driver:get_player_name()] = nil
		if playerphysics then
			playerphysics.remove_physics_factor(self._driver, "gravity", "flight")
			playerphysics.remove_physics_factor(self._driver, "speed", "flight")
		end
	end
	self.object:set_detach()
end


function sum_jetpack.sound_play(self, soundref, instance)
	instance.time = 0
	instance.handle = minetest.sound_play(soundref.name, {
		gain = soundref.gain,
		pitch = soundref.pitch,
		object = self.object,
	})
end

function sum_jetpack.sound_stop(handle, fade)
	if not handle then return end
	if fade and minetest.sound_fade ~= nil then
		minetest.sound_fade(handle, 1, 0)
	else
		minetest.sound_stop(handle)
	end
end

function sum_jetpack.sound_stop_all(self)
	if not self._sounds or type(self._sounds) ~= "table" then return end
	for _, sound in pairs(self._sounds) do
		sum_jetpack.sound_stop(sound.handle)
	end
end

sum_jetpack.sound_list = {
	idle = {
		name = "sum_jetpack_flame",
		gain = 0.2,
		pitch = 0.7,
		duration = 3 + (3 * (1 - 0.7)), -- will stop the sound after this
	},
	boost = {
		name = "sum_jetpack_flame",
		gain = 0.4,
		pitch = 0.5,
		duration = 3 + (3 * (1 - 0.5)), -- will stop the sound after this
	},
}

sum_jetpack.sound_timer_update = function(self, dtime)
	for _, sound in pairs(self._sounds) do
		if sound.handle then
			sound.time = sound.time + dtime
		end
	end
end


sum_jetpack.do_sounds = function(self)
	if self._sounds then
		if not self._sounds.idle.handle and not self._disabled then
			sum_jetpack.sound_play(self, sum_jetpack.sound_list.idle, self._sounds.idle)
		elseif self._disabled or (self._sounds.idle.time > sum_jetpack.sound_list.idle.duration
		and self._sounds.idle.handle) then
			sum_jetpack.sound_stop(self._sounds.idle.handle)
			self._sounds.idle.handle = nil
		end

		if not self._driver and self._sounds.idle.handle then
			minetest.sound_stop(self._sounds.idle.handle)
			self._sounds.idle.handle = nil
		end


		if self._driver and self._driver:is_player() then
			local ctrl = self._driver:get_player_control()
			local moving = ctrl and (ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump)
			-- moving = moving and not ctrl.aux1
			if moving then
				if not self._sounds.boost.handle then
					sum_jetpack.sound_play(self, sum_jetpack.sound_list.boost, self._sounds.boost)
				elseif self._disabled or (self._sounds.boost.time > sum_jetpack.sound_list.boost.duration
				and self._sounds.boost.handle) then
					sum_jetpack.sound_stop(self._sounds.boost.handle)
					self._sounds.boost.handle = nil
				end
			elseif self._sounds.boost.handle then
				minetest.sound_stop(self._sounds.boost.handle)
				self._sounds.boost.handle = nil
			end
		end



	else
		self._sounds.idle = {
			time = 0,
			handle = nil}
		self._sounds.boost = {
			time = 0,
			handle = nil}
	end
end

sum_jetpack.drop_self = function(self, no_drop)
	local drop = self._itemstack
	self._flags.removed = true
	if self._driver and self._driver:is_player() then
		if minetest.is_creative_enabled(self._driver:get_player_name()) then
			drop = nil
		elseif not no_drop then
			local inv = self._driver:get_inventory()
			drop = inv:add_item("main", drop)
		end
	end
	if drop then
		minetest.add_item(self.object:get_pos(), drop)
	end
end


-- clean up
sum_jetpack.on_death = function(self, no_drop)
	if self._flags.removed then return false end
	sum_jetpack.sound_stop_all(self)
	self._flags.removed = true
	self._disabled = true
	if self._itemstack then
		sum_jetpack.drop_self(self, no_drop)
	end
  self.object:set_properties({
    physical = false
  })
  minetest.sound_play("sum_jetpack_fold", {
		gain = 1,
    object = self.object,
	})
	vel = self.object:get_velocity()
	vel = vector.multiply(vel, 0.8)
  if self._driver then
		minetest.after(0.01, function(vel, driver)
			driver:add_velocity(vel)
		end, vel, self._driver)
    sum_jetpack.detach_object(self, false)
  end
	self.object:remove()
end


-- sum_jetpack

sum_jetpack.get_movement = function(self)
  if not self._driver or not self._driver:is_player() then return vector.new() end
  local ctrl = self._driver:get_player_control()
  if not ctrl then return vector.new() end
	local anim = self._anim.idle

  local dir = self._driver:get_look_dir()
	dir.y = 0
	dir = vector.normalize(dir)

  local forward = 0
  local up = 0
  local right = 0
  if ctrl.up then
    forward = 1
		anim = self._anim.up
  elseif ctrl.down then
    forward = -0.5
		anim = self._anim.up
  end
  if ctrl.jump then
    up = 2
		anim = self._anim.up
	elseif ctrl.aux1 then
		up = -2
  end
  if ctrl.left then
    right = -1
		anim = self._anim.up
	elseif ctrl.right then
		right = 1
		anim = self._anim.up
  end

  local v = vector.new()
  v = vector.multiply(dir, forward)

	if right ~= 0 then
		local yaw = minetest.dir_to_yaw(dir)
		yaw = yaw - (right * (math.pi / 2))
		yaw = minetest.yaw_to_dir(yaw)
		v = vector.add(v, yaw)
	end

	v.y = up

	self.object:set_animation(anim, 24, 0)

  return v
end

local particles = {
	smoke = {
		chance = 0.5,
		texture = "sum_jetpack_particle_smoke.png^[colorize:#22222900:50",
		vel = 2,
		time = 4,
		size = 1.3},
	smoke3 = {
		chance = 1,
		texture = "sum_jetpack_particle_smoke.png^[colorize:#22222900:50",
		vel = 4,
		time = 1,
		size = 0.7},
	flame = {
		chance = 0.5,
		texture = "sum_jetpack_particle_flame.png",
		vel = 10,
		time = 0.6,
		size = 0.7},
	spark = {
		chance = 0.6,
		texture = "sum_jetpack_particle_spark.png",
		vel = 20,
		time = 0.4,
		size = 0.5},
}
local exhaust = {
	dist = 0.6,
	yaw = 0.5,
}
sum_jetpack.do_particles = function(self, dtime)
	if not self._driver or not dtime then return false end
	local ctrl
	if self._driver:is_player() then
		ctrl = self._driver:get_player_control()
	end
	local part_chance_mult = ctrl and (ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump)
	if not part_chance_mult then part_chance_mult = 0.2
	else part_chance_mult = 1 end

	local wind_vel = vector.new()
	local p = self.object:get_pos()
	local v = self._driver:get_velocity()
	local vel = self._driver:get_velocity()
	vel = vector.multiply(vel, dtime * 1.07)
	v = vector.multiply(v, 0.8)
	if sum_air_currents then
		sum_air_currents.get_wind(p)
	end
	for i=-1,0 do
		if i == 0 then i = 1 end
		local yaw = self.object:get_yaw() + (exhaust.yaw * i) + math.pi
		yaw = minetest.yaw_to_dir(yaw)
		yaw = vector.multiply(yaw, exhaust.dist)
		local ex = vector.add(p, yaw)
		ex.y = ex.y + 1
		for _, prt in pairs(particles) do
			if math.random(0,100)/100 < prt.chance * part_chance_mult then
				minetest.add_particle({
					pos = vector.add(ex, vel),
					velocity = vector.add(v, vector.add( wind_vel, {x=0, y= prt.vel * -math.random(0.2*100,0.7*100)/100, z=0})),
					expirationtime = ((math.random() / 5) + 0.2) * prt.time,
					size = ((math.random())*4 + 0.05) * prt.size,
					collisiondetection = false,
					vertical = false,
					texture = prt.texture,
				})
			end
		end
	end
end

local gravity = -1
local move_speed = 15
sum_jetpack.max_use_time = 30
sum_jetpack.wear_per_sec = 65535 / sum_jetpack.max_use_time
-- warn the player 5 sec before fuel runs out
sum_jetpack.wear_warn_level = (sum_jetpack.max_use_time - 5) * sum_jetpack.wear_per_sec

sum_jetpack.on_step = function(self, dtime)
  if self._age < 100 then self._age = self._age + dtime end
	if self._age < 0.6 then return
	else
		if self._driver and not self._flags.set_grav and playerphysics then
			--playerphysics.add_physics_factor(self._driver, "gravity", "flight", 0)
			playerphysics.add_physics_factor(self._driver, "speed", "flight", 0)
			self._flags.set_grav = true
		end
	end
	if not self._flags.ready and self._age < 1 then return end
	if self._itemstack then
		local wear = self._itemstack:get_wear()
		self._itemstack:set_wear(math.min(65534, wear + (65535 / sum_jetpack.max_use_time) * dtime))
		self._fuel = sum_jetpack.max_use_time - (wear / sum_jetpack.wear_per_sec)
		if wear >= 65534 then
			sum_jetpack.on_death(self, nil)
			self.object:remove()
			return false
		elseif wear >= sum_jetpack.wear_warn_level and (not self._flags.warn) then
			local warn_sound = minetest.sound_play("sum_jetpack_warn", {gain = 0.5, object = self.object})
			if warn_sound and minetest.sound_fade ~= nil then
				minetest.sound_fade(warn_sound, 0.1, 0) end
			self._flags.warn = true
		end
	end

	if not self._flags.visible then
		self.object:set_properties({is_visible = true})
		self._flags.visible = true
	end

	if self._sounds then
		sum_jetpack.sound_timer_update(self, dtime)
		sum_jetpack.do_sounds(self)
	end

	sum_jetpack.do_particles(self, dtime)

  local p = self.object:get_pos()
  local fly_node = minetest.get_node(vector.offset(p, 0, 0.3, 0))
  local exit = (self._driver and self._driver:get_player_control().sneak)
            or (self._age > 1 and not self._driver)
	exit = exit or (self._driver and self._driver:get_attach())
	exit = exit or (minetest.get_item_group(fly_node.name, "liquid") ~= 0)
  if exit then
    sum_jetpack.on_death(self, nil)
    self.object:remove()
    return false
  end

  if self._driver then
    self.object:set_yaw(minetest.dir_to_yaw(self._driver:get_look_dir()))
  end

  local a = vector.new()
	local move_mult = move_speed * dtime
	if self._disabled then move_mult = move_mult / 10 end

	local move_vect = sum_jetpack.get_movement(self)
  a = vector.multiply(move_vect, move_mult)

  local vel = self._driver:get_velocity()
  vel = vector.multiply(vel, -0.04)
	if vel.y > 0 then
		vel.y = vel.y * 1.5
	end
	vel = vector.add(a, vel)
  self._driver:add_velocity(vel)
end

local cbsize = 0.3
local jetpack_ENTITY = {
	physical = false,
	timer = 0,
  -- backface_culling = false,
	visual = "mesh",
	mesh = "sum_jetpack.b3d",
	textures = {"sum_jetpack_texture.png"},
	visual_size = {x=1, y=1, z=1},
	collisionbox = {-cbsize, -0, -cbsize,
                   cbsize,  cbsize*6,  cbsize},
	pointable = false,

	get_staticdata = sum_jetpack.get_staticdata,
	on_activate = sum_jetpack.on_activate,
  on_step = sum_jetpack.on_step,
	_anim = {
		idle = {x = 0, y = 10},
		up = {x = 20, y = 30},
	},
	is_visible = false,
	_thrower = nil,
  _pilot = nil,
  _age = 0,
	_sounds = nil,
	_itemstack = nil,
	_disabled = false,
	_flags = {},
	_fuel = sum_jetpack.max_use_time,
	_on_detach = sum_jetpack.on_death,

	_lastpos={},
}

minetest.register_entity("hero_jetpack:jetpack_ENTITY", jetpack_ENTITY)