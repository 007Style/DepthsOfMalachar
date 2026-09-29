## TestRunner — Headless Unit Test Runner Node
## Runs in project scene tree with all Autoloads active.

extends Node

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0
var current_suite: String = ""

func _ready() -> void:
	print("\n=======================================================")
	print("       THE DEPTHS OF MALACHAR - UNIT TEST SUITE        ")
	print("=======================================================\n")

	_run_suite("Globals & Math", _test_globals)
	_run_suite("Stats & Calculations", _test_stats)
	_run_suite("SaveManager & Slots", _test_save_manager)
	_run_suite("ProgressionManager", _test_progression_manager)
	_run_suite("RecruitData & Leveling", _test_recruits)
	_run_suite("CraftingManager", _test_crafting)
	_run_suite("PetFusion", _test_pet_fusion)
	_run_suite("LootTable & Rarity", _test_loot_tables)
	_run_suite("AchievementManager", _test_achievements)
	_run_suite("GameManager State & Flow", _test_game_manager)

	print("\n-------------------------------------------------------")
	print("TOTAL TESTS : %d" % total_tests)
	print("PASSED      : %d" % passed_tests)
	print("FAILED      : %d" % failed_tests)
	print("-------------------------------------------------------")

	if failed_tests == 0:
		print(">> ALL UNIT TESTS PASSED SUCCESSFULLY! <<\n")
		get_tree().quit(0)
	else:
		print(">> %d TEST(S) FAILED! <<\n" % failed_tests)
		get_tree().quit(1)

func _run_suite(suite_name: String, callable: Callable) -> void:
	current_suite = suite_name
	print("▶ Suite: %s" % suite_name)
	callable.call()
	print("")

func assert_true(condition: bool, msg: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  ✓ PASS: %s" % msg)
	else:
		failed_tests += 1
		print("  ✗ FAIL: %s (Expected true)" % msg)

func assert_false(condition: bool, msg: String) -> void:
	total_tests += 1
	if not condition:
		passed_tests += 1
		print("  ✓ PASS: %s" % msg)
	else:
		failed_tests += 1
		print("  ✗ FAIL: %s (Expected false)" % msg)

func assert_eq(actual, expected, msg: String) -> void:
	total_tests += 1
	if actual == expected:
		passed_tests += 1
		print("  ✓ PASS: %s" % msg)
	else:
		failed_tests += 1
		print("  ✗ FAIL: %s (Expected %s, got %s)" % [msg, str(expected), str(actual)])

func assert_approx_eq(actual: float, expected: float, tolerance: float, msg: String) -> void:
	total_tests += 1
	if abs(actual - expected) <= tolerance:
		passed_tests += 1
		print("  ✓ PASS: %s" % msg)
	else:
		failed_tests += 1
		print("  ✗ FAIL: %s (Expected ~%f, got %f)" % [msg, expected, actual])

# ---------------------------------------------------------------------------
# Test Suites
# ---------------------------------------------------------------------------

func _test_globals() -> void:
	# Coin conversions
	var display_1 = Globals.coins_to_display(10523)
	assert_eq(display_1["gold"], 1, "10523 copper gives 1 gold")
	assert_eq(display_1["silver"], 5, "10523 copper gives 5 silver")
	assert_eq(display_1["copper"], 23, "10523 copper gives 23 copper")

	# Biome floor mapping
	assert_eq(Globals.get_biome_for_floor(10), Globals.BiomeType.CATACOMBS, "Floor 10 is Catacombs")
	assert_eq(Globals.get_biome_for_floor(35), Globals.BiomeType.VOLCANIC_CAVES, "Floor 35 is Volcanic Caves")
	assert_eq(Globals.get_biome_for_floor(60), Globals.BiomeType.FROZEN_DEPTHS, "Floor 60 is Frozen Depths")
	assert_eq(Globals.get_biome_for_floor(85), Globals.BiomeType.SHADOW_REALM, "Floor 85 is Shadow Realm")
	assert_eq(Globals.get_biome_for_floor(120), Globals.BiomeType.DEMON_SANCTUM, "Floor 120 is Demon Sanctum")

	# Elemental multipliers
	var mult_water_light = Globals.get_elemental_multiplier(Globals.ElementType.WATER, Globals.ElementType.LIGHTNING)
	assert_eq(mult_water_light, 2.0, "Lightning vs Water deals 2.0x damage")

	var mult_none = Globals.get_elemental_multiplier(Globals.ElementType.FIRE, Globals.ElementType.NONE)
	assert_eq(mult_none, 1.0, "None vs Fire deals 1.0x neutral damage")

	# Elemental reactions
	var reaction = Globals.check_elemental_reaction(Globals.ElementType.FIRE, Globals.ElementType.ICE)
	assert_eq(reaction, Globals.StatusEffect.STEAM, "Fire + Ice produces Steam reaction")

	var reaction_elec = Globals.check_elemental_reaction(Globals.ElementType.LIGHTNING, Globals.ElementType.WATER)
	assert_eq(reaction_elec, Globals.StatusEffect.ELECTROCUTE, "Lightning + Water produces Electrocute")

func _test_stats() -> void:
	var s := Stats.new()
	assert_eq(s.max_hp, 100.0, "Default max_hp is 100")
	assert_eq(s.current_hp, 100.0, "Default current_hp matches max_hp")

	s.add_flat("max_hp", 50.0)
	assert_eq(s.max_hp, 150.0, "Adding flat max_hp works")

	s.add_flat("crit_chance", 0.15)
	assert_approx_eq(s.crit_chance, 0.20, 0.001, "Crit chance adds and clamps accurately")

	s.multiply("base_damage", 1.5)
	assert_approx_eq(s.base_damage, 15.0, 0.001, "Damage multiply scaling works")

	var cloned := s.clone()
	assert_eq(cloned.max_hp, 150.0, "Cloned stats have identical max_hp")
	assert_eq(cloned.base_damage, 15.0, "Cloned stats have identical base_damage")

	# Modify clone without affecting original
	cloned.add_flat("base_damage", 10.0)
	assert_eq(s.base_damage, 15.0, "Original stats unaffected by clone modifications")
	assert_eq(cloned.base_damage, 25.0, "Clone has updated base_damage")

func _test_save_manager() -> void:
	SaveManager.select_slot(2)
	assert_eq(SaveManager.current_slot, 2, "Slot 2 selected successfully")

	SaveManager.set_setting("auto_loot", true)
	assert_true(SaveManager.get_setting("auto_loot", false), "Setting stored in active profile")

	ProgressionManager.base_coins_copper = 500
	SaveManager.save()
	assert_true(SaveManager.has_save(2), "Save slot 2 file created on disk")

	var info = SaveManager.get_slot_info(2)
	assert_true(info["exists"], "Slot 2 info exists")
	assert_eq(info["coins"], 500, "Slot 2 info reflects saved coin amount")

	# Clean up test slot
	SaveManager.delete_save_slot(2)
	assert_false(SaveManager.has_save(2), "Slot 2 deleted from disk")
	SaveManager.select_slot(1)

func _test_progression_manager() -> void:
	ProgressionManager.reset_progress()
	assert_eq(ProgressionManager.upgrade_points, 0, "Upgrade points start at 0")
	assert_eq(ProgressionManager.base_coins_copper, 0, "Base coins start at 0")

	ProgressionManager.add_base_coins(250)
	assert_eq(ProgressionManager.base_coins_copper, 250, "Added 250 base copper coins")

	var spent = ProgressionManager.spend_base_coins(100)
	assert_true(spent, "Spent 100 copper coins successfully")
	assert_eq(ProgressionManager.base_coins_copper, 150, "150 copper coins remain")

	var overspent = ProgressionManager.spend_base_coins(500)
	assert_false(overspent, "Cannot spend more coins than available")

	ProgressionManager.add_upgrade_points(10)
	var bought = ProgressionManager.purchase_upgrade("hp_1", 3)
	assert_true(bought, "Purchased hp_1 upgrade node")
	assert_true(ProgressionManager.has_upgrade("hp_1"), "Has hp_1 upgrade registered")
	assert_eq(ProgressionManager.upgrade_points, 7, "Remaining upgrade points calculated correctly")

func _test_recruits() -> void:
	var r := RecruitData.new()
	r.recruit_name = "Kaelen"
	r.stats = Stats.new()

	assert_eq(r.level, 1, "Recruit starts at level 1")
	assert_eq(r.runs_survived, 0, "Recruit starts with 0 runs")

	r.increase_bond("Aelion", 15)
	assert_eq(r.get_bond_level("Aelion"), 15, "Bond level increased to 15")

	var leveled = r.gain_xp(150)
	assert_true(leveled, "Recruit leveled up on gaining 150 XP")
	assert_eq(r.level, 2, "Recruit is now level 2")
	assert_eq(r.xp, 50, "Remaining XP carried over")

	r.runs_survived = 5
	r._on_level_up()
	assert_true("Survivor" in r.veteran_titles, "Earned Survivor veteran title at 5 runs")

	var dict = r.to_dict()
	var restored = RecruitData.from_dict(dict)
	assert_eq(restored.recruit_name, "Kaelen", "Recruit restored from dict with accurate name")
	assert_eq(restored.level, 2, "Recruit restored from dict with accurate level")

func _test_crafting() -> void:
	var cm := CraftingManager.new()
	var recipe = CraftingManager.POTION_RECIPES[0] # Health Potion: LifePlant Petal + Water Vial

	assert_false(cm.can_craft(recipe), "Cannot craft without ingredients")

	cm.add_ingredient(CraftingManager.IngredientType.LIFE_PLANT_PETAL, 2)
	cm.add_ingredient(CraftingManager.IngredientType.WATER_VIAL, 1)
	assert_true(cm.can_craft(recipe), "Can craft when ingredients are present in inventory")

	# Dummy player node for effect testing
	var node := Node.new()
	var crafted = cm.craft(recipe, node)
	assert_true(crafted, "Craft operation succeeded")
	assert_eq(cm.ingredient_inventory[CraftingManager.IngredientType.LIFE_PLANT_PETAL], 1, "Ingredient consumed properly")
	node.free()
	cm.free()

func _test_pet_fusion() -> void:
	var pet_a := PetData.new()
	pet_a.species_name = "Ember Fox"
	pet_a.hp_bonus = 20.0
	pet_a.damage_bonus = 15.0
	pet_a.element = Globals.ElementType.FIRE
	pet_a.bond_level = 10
	pet_a.personality = Globals.PetPersonality.AGGRESSIVE

	var pet_b := PetData.new()
	pet_b.species_name = "Frostling"
	pet_b.hp_bonus = 30.0
	pet_b.damage_bonus = 5.0
	pet_b.element = Globals.ElementType.ICE
	pet_b.bond_level = 20
	pet_b.personality = Globals.PetPersonality.DEFENSIVE

	var hybrid = PetFusion.fuse(pet_a, pet_b)
	assert_eq(hybrid.species_name, "Ember Fox-Frostling Hybrid", "Hybrid species name merged")
	assert_approx_eq(hybrid.hp_bonus, 30.0, 0.01, "Hybrid HP bonus averaged with fusion factor")
	assert_eq(hybrid.element, Globals.ElementType.FIRE, "Dominant fire element inherited from higher damage parent")
	assert_eq(hybrid.personality, Globals.PetPersonality.DEFENSIVE, "Personality inherited from higher bond parent")
	assert_eq(hybrid.bond_level, 15, "Bond level averaged")

func _test_loot_tables() -> void:
	var lt := LootTable.new()
	lt.coin_drop_min = 5
	lt.coin_drop_max = 10
	lt.coin_type = Globals.CoinType.GOLD

	var drop = lt.roll_coins()
	assert_eq(drop["coin_type"], Globals.CoinType.GOLD, "Rolled correct coin type")
	assert_true(drop["amount"] >= 5 and drop["amount"] <= 10, "Coin amount rolled within configured range")

	var weights_f1 = Globals.get_rarity_weight_for_floor(1)
	var weights_f100 = Globals.get_rarity_weight_for_floor(100)
	assert_true(weights_f100[Globals.ItemRarity.LEGENDARY] > weights_f1[Globals.ItemRarity.LEGENDARY], "Higher floors give higher legendary drop chances")

func _test_achievements() -> void:
	assert_true(AchievementManager.ACHIEVEMENTS.size() > 0, "Achievement definitions present")
	var first_ach = AchievementManager.ACHIEVEMENTS[0]
	assert_true(first_ach.has("id"), "Achievement has ID")
	assert_true(first_ach.has("target"), "Achievement has target requirement")

func _test_game_manager() -> void:
	assert_eq(GameManager.current_state, Globals.GameState.MENU, "Initial state is MENU")
	assert_true(GameManager.run_stats.has("floors_reached"), "Run stats tracks floors_reached")
	assert_true(GameManager.run_stats.has("enemies_killed"), "Run stats tracks enemies_killed")
	assert_true(GameManager.run_stats.has("coins_collected"), "Run stats tracks coins_collected")
