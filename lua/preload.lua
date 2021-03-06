--<<

local T = wml.tag
local function sign(x)
	if x > 0 then return 1 end
	return -1
end
local abs=math.abs

function wesnoth.wml_conditionals.AE_is_rpg()
	local id = wesnoth.game_config.era.id or ""
	id = id:lower()
	if id:find("rpg") then
		return true
	else
		return false
	end
end

function wesnoth.wml_conditionals.AE_not_rpg()
	return not wesnoth.wml_conditionals.AE_is_rpg()
end

function wesnoth.wml_conditionals.AE_is_observer()
	local all_sides = wesnoth.get_sides()
	for index, side in ipairs(all_sides) do
		if side.controller == "human" and side.is_local then
			return false
		end
	end
	return true
end

function wesnoth.wml_conditionals.AE_is_active()
	return wesnoth.sides[wesnoth.current.side].controller == "human" and wesnoth.sides[wesnoth.current.side].is_local
end

function wesnoth.wml_conditionals.AE_not_active()
	return wesnoth.wml_conditionals.AE_is_observer() or not wesnoth.wml_conditionals.AE_is_active()
end

function wesnoth.wml_conditionals.Ravana()
	return wesnoth.have_file("~add-ons/DBG_Modification/_main.cfg")
end

function wesnoth.wml_conditionals.AE_beta()
	return wesnoth.wml_conditionals.Ravana() or AE_use_beta_features == "use_beta_features"
end

function wesnoth.wml_actions.AE_read_file(cfg)
	local V = wml.variables
	V[cfg.variable or "file"] = wesnoth.read_file(cfg.name)
end

function wesnoth.wml_actions.AE_dofile(cfg)
	wesnoth.dofile("~add-ons/Ageless_Era/lua/"..cfg.name)
end

function wesnoth.wml_actions.AE_efm_add_hex(cfg)
	local max_cth = 90
	local def_redu = 15
	local function map_def(defense)
		if not defense then return 100 end
		if abs(defense) > max_cth then return defense end
		if abs(defense) > (max_cth-def_redu) then return sign(defense)*max_cth end
		return sign(defense)*(abs(defense)+def_redu)
	end
	
	local units = wesnoth.get_units(cfg)
	for _,u in pairs(units) do
		local def = wml.get_child(u.__cfg, "defense")
		
		u:add_modification("object",{
			id="AE_efm_hex_object",
			T.effect{
				apply_to="defense",
				replace=true,
				T.defense{
					deep_water=map_def(def["deep_water"]),
					shallow_water=map_def(def["shallow_water"]),
					reef=map_def(def["reef"]),
					swamp_water=map_def(def["swamp_water"]),
					flat=map_def(def["flat"]),
					sand=map_def(def["sand"]),
					forest=map_def(def["forest"]),
					hills=map_def(def["hills"]),
					mountains=map_def(def["mountains"]),
					village=map_def(def["village"]),
					castle=map_def(def["castle"]),
					cave=map_def(def["cave"]),
					frozen=map_def(def["frozen"]),
					unwalkable=map_def(def["unwalkable"]),
					impassable=map_def(def["impassable"]),
					fungus=map_def(def["fungus"])
				}
			},
			T.effect{
				apply_to="overlay",
				add="utils/curse.png"
			}
		})
		u.status.AE_efm_curse = true
	end
end

function wesnoth.wml_actions.AE_efm_remove_hex(cfg)
	local units = wesnoth.get_units(cfg)
	for i,u in ipairs(units) do
		u:remove_modifications({id="AE_efm_hex_object"})
		wesnoth.wml_actions.remove_unit_overlay{id=u.id, image="utils/curse.png"}
		u.status.AE_efm_curse = false
	end
end

function wesnoth.wml_actions.AE_efm_shift_unit(cfg)
	local bear_contains = {"F","Uf","Uu","Uh","Aa^"}
	local human_contains = {"K","C","Vh","Ve"}
	local beaver_contains = {"W","w","Ss"}
	local boar_contains = {"D","Gg","Re","Rp","Gs","Re","Rd","Rr","Dd","Hd","Ur"}
	local wolf_contains = {"A","Ha"}
	local goat_contains = {"H","M","Dd^Dr"}
	-- else human
	local function get_variation(terrain)
		for _, t in pairs(bear_contains) do
			if terrain:find(t) then return "shifter_bear" end
		end
		for _, t in pairs(human_contains) do
			if terrain:find(t) then return "shifter_human" end
		end
		for _, t in pairs(beaver_contains) do
			if terrain:find(t) then return "shifter_beaver" end
		end
		for _, t in pairs(boar_contains) do
			if terrain:find(t) then return "shifter_warthog" end
		end
		for _, t in pairs(wolf_contains) do
			if terrain:find(t) then return "shifter_wolf" end
		end
		for _, t in pairs(goat_contains) do
			if terrain:find(t) then return "shifter_goat" end
		end
		return "shifter_human"
	end

	local units = wesnoth.get_units(cfg)
	for i,u in ipairs(units) do
		u:remove_modifications({id="AE_efm_shift_object"})
		local variation = get_variation(wesnoth.get_terrain(u.x, u.y))
		u:add_modification("object",{
			id="AE_efm_shift_object",
			T.effect{
				apply_to="variation",
				name=variation
			}
		})
	end
end

-->>
