## BiomeManager — Manages biome assignment, enemy pools, tileset, and atmospheric effects.
## Called by DungeonGenerator to configure each floor's biome.

class_name BiomeManager
extends Node

# ---------------------------------------------------------------------------
# Enemy scene pools per biome (paths to enemy scenes)
# ---------------------------------------------------------------------------
const BIOME_ENEMY_POOLS: Dictionary = {
	Globals.BiomeType.CATACOMBS: [
		"res://scenes/enemies/SkeletonWarrior.tscn",
		"res://scenes/enemies/SkeletonArcher.tscn",
		"res://scenes/enemies/OrcGrunt.tscn",
		"res://scenes/enemies/OrcShaman.tscn",
		"res://scenes/enemies/VineLurker.tscn",
		"res://scenes/enemies/PoisonCrawler.tscn",
	],
	Globals.BiomeType.VOLCANIC_CAVES: [
		"res://scenes/enemies/DemonImp.tscn",
		"res://scenes/enemies/OrcShaman.tscn",
		"res://scenes/enemies/StoneGolem.tscn",
		"res://scenes/enemies/EarthElemental.tscn",
		"res://scenes/enemies/CursedKnight.tscn",
	],
	Globals.BiomeType.FROZEN_DEPTHS: [
		"res://scenes/enemies/FrostWraith.tscn",
		"res://scenes/enemies/SkeletonArcher.tscn",
		"res://scenes/enemies/ThunderHawk.tscn",
		"res://scenes/enemies/AirDjinn.tscn",
		"res://scenes/enemies/WaterSerpent.tscn",
	],
	Globals.BiomeType.SHADOW_REALM: [
		"res://scenes/enemies/ShadowStalker.tscn",
		"res://scenes/enemies/FrostWraith.tscn",
		"res://scenes/enemies/SkeletonWarrior.tscn",
		"res://scenes/enemies/CursedKnight.tscn",
		"res://scenes/enemies/BloodBat.tscn",
	],
	Globals.BiomeType.DEMON_SANCTUM: [
		"res://scenes/enemies/DemonImp.tscn",
		"res://scenes/enemies/CursedKnight.tscn",
		"res://scenes/enemies/ShadowStalker.tscn",  # VoidHerald.tscn does not exist — use ShadowStalker
		"res://scenes/enemies/BloodBat.tscn",
		"res://scenes/enemies/AirDjinn.tscn",
		"res://scenes/enemies/WaterSerpent.tscn",
	],
}

# ---------------------------------------------------------------------------
# Biome atmosphere colours (modulate tints for CanvasModulate)
# ---------------------------------------------------------------------------
const BIOME_TINT: Dictionary = {
	Globals.BiomeType.CATACOMBS:      Color(0.85, 0.80, 0.75, 1.0),  # Warm grey stone
	Globals.BiomeType.VOLCANIC_CAVES: Color(1.0,  0.70, 0.50, 1.0),  # Orange heat
	Globals.BiomeType.FROZEN_DEPTHS:  Color(0.70, 0.85, 1.0,  1.0),  # Cold blue
	Globals.BiomeType.SHADOW_REALM:   Color(0.55, 0.45, 0.65, 1.0),  # Purple shadow
	Globals.BiomeType.DEMON_SANCTUM:  Color(0.80, 0.40, 0.40, 1.0),  # Blood red
}

# ---------------------------------------------------------------------------
# Biome names for display
# ---------------------------------------------------------------------------
const BIOME_NAMES: Dictionary = {
	Globals.BiomeType.CATACOMBS:      "The Catacombs",
	Globals.BiomeType.VOLCANIC_CAVES: "Volcanic Caves",
	Globals.BiomeType.FROZEN_DEPTHS:  "The Frozen Depths",
	Globals.BiomeType.SHADOW_REALM:   "The Shadow Realm",
	Globals.BiomeType.DEMON_SANCTUM:  "Demon Sanctum",
}

# ---------------------------------------------------------------------------
# Weather system
# ---------------------------------------------------------------------------
enum WeatherType {
	NONE,
	RAIN,        # Slight slow to all movement
	ASH_FALL,   # Reduced visibility (darken screen)
	LIGHTNING_STORM,  # Random lightning strikes — deal damage
	BLIZZARD,   # Slow + periodic ice damage
	HELLFIRE,   # Periodic fire zones on ground
}

const BIOME_WEATHER_POOLS: Dictionary = {
	Globals.BiomeType.CATACOMBS:      [WeatherType.NONE, WeatherType.NONE, WeatherType.RAIN],
	Globals.BiomeType.VOLCANIC_CAVES: [WeatherType.ASH_FALL, WeatherType.HELLFIRE, WeatherType.NONE],
	Globals.BiomeType.FROZEN_DEPTHS:  [WeatherType.BLIZZARD, WeatherType.RAIN, WeatherType.NONE],
	Globals.BiomeType.SHADOW_REALM:   [WeatherType.ASH_FALL, WeatherType.NONE, WeatherType.NONE],
	Globals.BiomeType.DEMON_SANCTUM:  [WeatherType.HELLFIRE, WeatherType.LIGHTNING_STORM, WeatherType.ASH_FALL],
}

var current_weather: int = WeatherType.NONE
var weather_timer: float = 0.0
const WEATHER_TICK_INTERVAL: float = 3.0  # Seconds between weather events

# ---------------------------------------------------------------------------
# Seasonal biome overlay (reads system date)
# ---------------------------------------------------------------------------
func get_seasonal_override() -> int:
	var month: int = Time.get_date_dict_from_system()["month"]
	match month:
		12, 1, 2:  return Globals.BiomeType.FROZEN_DEPTHS   # Winter
		3, 4, 5:   return -1  # Spring — bloom variant (no override, handled visually)
		6, 7, 8:   return -1  # Summer — normal
		9, 10, 11: return -1  # Autumn — darker catacombs (no override)
		_:         return -1

func has_seasonal_bloom() -> bool:
	var month: int = Time.get_date_dict_from_system()["month"]
	return month in [3, 4, 5]

# ---------------------------------------------------------------------------
# Apply biome to the dungeon
# ---------------------------------------------------------------------------
func apply_biome(biome: int, canvas_modulate: CanvasModulate) -> void:
	var tint: Color = BIOME_TINT.get(biome, Color.WHITE)
	if canvas_modulate:
		canvas_modulate.color = tint

func get_random_enemy_scene(biome: int, rng: RandomNumberGenerator) -> String:
	var pool: Array = BIOME_ENEMY_POOLS.get(biome, BIOME_ENEMY_POOLS[Globals.BiomeType.CATACOMBS])
	if pool.is_empty():
		return ""
	return pool[rng.randi() % pool.size()]

func get_biome_name(biome: int) -> String:
	return BIOME_NAMES.get(biome, "Unknown")

# ---------------------------------------------------------------------------
# Weather
# ---------------------------------------------------------------------------
func roll_weather(biome: int, rng: RandomNumberGenerator) -> int:
	var pool: Array = BIOME_WEATHER_POOLS.get(biome, [WeatherType.NONE])
	current_weather = pool[rng.randi() % pool.size()]
	return current_weather

func _process(delta: float) -> void:
	if current_weather == WeatherType.NONE:
		return
	weather_timer -= delta
	if weather_timer <= 0.0:
		weather_timer = WEATHER_TICK_INTERVAL
		_apply_weather_effect()

func _apply_weather_effect() -> void:
	match current_weather:
		WeatherType.LIGHTNING_STORM:
			# Random lightning strike position — deal damage to anything nearby
			var strike_pos: Vector2 = Vector2(randf_range(50, 430), randf_range(50, 800))
			for body in get_tree().get_nodes_in_group("player"):
				if body.global_position.distance_to(strike_pos) < 60.0:
					if body.has_method("take_damage"):
						body.take_damage(18.0, Globals.ElementType.LIGHTNING)
			EventBus.notification_requested.emit("⚡ Lightning!", Color(1.0, 1.0, 0.0))
		WeatherType.HELLFIRE:
			# Periodic fire damage to player
			for body in get_tree().get_nodes_in_group("player"):
				if body.has_method("take_damage"):
					body.take_damage(8.0, Globals.ElementType.FIRE)
		WeatherType.BLIZZARD:
			for body in get_tree().get_nodes_in_group("player"):
				if body.has_method("apply_status_effect"):
					body.apply_status_effect(Globals.StatusEffect.SLOW, 3.0)
		WeatherType.RAIN:
			pass  # Handled visually
		WeatherType.ASH_FALL:
			pass  # Handled visually
