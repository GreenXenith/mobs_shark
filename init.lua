local base_def = {
	type = "monster",
	group_attack = true,
	owner_loyal = true,
	attack_animals = true,
	hp_min = 10,
	hp_max = 15,
	collisionbox = {-2,-0.5,-2,2,0.5,2},
	visual = "mesh",
	visual_size = {x=10, y=10},
	mesh = "shark.b3d",
	textures = {
		{"mobs_shark.png"},
	},
	makes_footstep_sound = false,
	view_range = 10,
	walk_velocity = 2,
	run_velocity = 3,
	stepheight = 2,
	jump = false,
	fly = true,
	fly_in = "default:water_source",
	knock_back = false,
	damage = 6,
	drops = {
		{name = "mobs_shark:fin", chance = 2, min = 1, max = 1},
		{name = "mobs_shark:tooth", chance = 5, min = 1, max = 4},
	},
	armor = 100,
	water_damage = 0,
	lava_damage = 10,
	light_damage = 0,
	attack_type = "dogfight",
	reach = 4,
	animation = {
		stand_speed = 24,
		walk_speed = 40,
		run_speed = 60,
		stand_start = 1,
		stand_end = 40,
		walk_start = 50,
		walk_end = 130,
		run_start = 50,
		run_end = 130,
		punch_start = 140,
		punch_end = 220,
	},
	do_custom = function(self)
		if self.state == "attack" and self.object:get_animation().x ~= 140 then
			self.object:set_animation({x=self.animation.punch_start,y=self.animation.punch_end}, self.animation.run_speed)
		end
	end,
	after_activate = function(self)
		self.object:set_properties({backface_culling = false})
	end,
}

local meg_def, shark_def = table.copy(base_def), table.copy(base_def)

shark_def.on_spawn = function(self)
	local pos = table.copy(self.object:get_pos())
	if pos.y < -30 and math.random(1, 25) == 1 then
		self.object:remove()
		minetest.add_entity(pos, "mobs_shark:megalodon")
	end
end

meg_def.visual_size = {x = 50, y = 50}
meg_def.collisionbox = {-20, -10, -20, 20, 10, 20}
meg_def.hp_min = 800
meg_def.hp_max = 1000
meg_def.damage = 20
meg_def.armor = 300
meg_def.view_range = 20
meg_def.reach = 15
meg_def.stepheight = 7
meg_def.drops = {
	{name = "mobs_shark:fin", chance = 1, min = 3, max = 3},
	{name = "mobs_shark:tooth", chance = 1, min = 5, max = 15},
}
meg_def.do_punch = function(self, hitter)
	if minetest.is_player(hitter) then
		self.last_puncher = hitter:get_player_name()
	end
end
meg_def.on_die = function(self)
	if self.last_puncher and minetest.get_modpath("awards") and minetest.get_player_by_name(self.last_puncher) then
		awards.unlock(self.last_puncher, "mobs_shark:megalodon")
	end
end

if minetest.global_exists("awards") then
	awards.register_award("mobs_shark:megalodon", {
		title = "Megalodon Hunter",
		description = "Kill a megalodon.",
		icon = "mobs_shark_tooth.png",
		secret = true,
	})
end

mobs:register_mob("mobs_shark:shark", shark_def)
mobs:register_mob("mobs_shark:megalodon", meg_def)

mobs:register_egg("mobs_shark:shark", "Shark", "wool_grey.png", 1)
mobs:register_egg("mobs_shark:megalodon", "Megalodon", "wool_grey.png", 1)

mobs:spawn({
	name = "mobs_shark:shark",
	nodes = {"default:sand", "default:desert_sand", "default:clay"},
	neighbors = {"default:water_source"},  -- "default:water_flowing"},
	chance = 75000,
	max_light = 14,
	max_height = -10,
	min_height = -60,
})

local farming_redo = minetest.get_modpath("farming") and farming.mod == "redo"
local ethereal = minetest.get_modpath("ethereal")

minetest.register_craftitem("mobs_shark:tooth", {
	description = "Shark Tooth",
	inventory_image = "mobs_shark_tooth.png",
})

if minetest.get_modpath("3d_armor") and minetest.get_modpath("farming") then
	table.insert(armor.elements, "necklace")

	armor:register_armor("mobs_shark:shark_tooth_necklace", {
		description = "Shark Tooth Necklace",
		inventory_image = "mobs_shark_tooth_necklace_inv.png",
		groups = {armor_necklace=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=0.1},
	})

	minetest.register_craft({
		output = "mobs_shark:shark_tooth_necklace",
		recipe = {
			{"mobs_shark:tooth", "farming:cotton", "mobs_shark:tooth"},
			{"farming:cotton", "", "farming:cotton"},
			{"mobs_shark:tooth", "farming:cotton", "mobs_shark:tooth"}
		}
	})
end

minetest.register_craftitem("mobs_shark:fin", {
	description = "Shark Fin",
	inventory_image = "mobs_shark_fin.png",
})

minetest.register_craftitem("mobs_shark:fin_cooked", {
	description = "Cooked Shark Fin",
	inventory_image = "mobs_shark_fin_cooked.png",
	on_use = minetest.item_eat(6),
})

if (farming_redo and ethereal) ~= false then
	minetest.register_craftitem(":farming:bowl", {
		description = "Wooden Bowl",
		inventory_image = "farming_bowl.png",
		groups = {food_bowl = 1, flammable = 2},
	})

	minetest.register_craft({
		output = "farming:bowl 4",
		recipe = {
			{"group:wood", "", "group:wood"},
			{"", "group:wood", ""},
		}
	})
end

minetest.register_craftitem("mobs_shark:shark_fin_soup", {
	description = "Shark Fin Soup",
	inventory_image = "mobs_shark_fin_soup.png",
	on_use = minetest.item_eat(16),
})

minetest.register_craft({
	type = "cooking",
	cooktime = 10,
	output = "mobs_shark:fin_cooked",
	recipe = "mobs_shark:fin"
})

local soup_recipe = {"group:food_bowl", "mobs_shark:fin_cooked"}
local soup_replacements = {}

if minetest.get_modpath("flowers") then
	table.insert(soup_recipe, "flowers:mushroom_brown")
end

if ethereal then
	table.insert(soup_recipe, "ethereal:bamboo")
end

if farming_redo then
	table.insert(soup_recipe, "farming:salt")
	table.insert(soup_replacements, {"farming:salt", "vessels:glass_bottle"})
end

minetest.register_craft({
	output = "mobs_shark:shark_fin_soup",
	type = "shapeless",
	recipe = soup_recipe,
	replacements = soup_replacements,
})
