## EventBus — Global Signal Hub
## All cross-system signals are declared here and emitted/connected via this singleton.
## This decouples systems and makes multiplayer synchronisation straightforward later.

extends Node

# ---------------------------------------------------------------------------
# Player signals
# ---------------------------------------------------------------------------
signal player_died()
signal player_revived(floor_num: int)
signal player_took_damage(amount: float, element: int)
signal player_healed(amount: float)
signal player_leveled_up(new_level: int)
signal player_xp_gained(amount: int)
signal player_class_changed(class_type: int)

# ---------------------------------------------------------------------------
# Combat signals
# ---------------------------------------------------------------------------
signal enemy_died(enemy_node: Node, position: Vector2)
signal enemy_took_damage(enemy_node: Node, amount: float)
signal boss_phase_changed(boss_node: Node, phase: int)
signal boss_died(boss_node: Node)
signal execution_triggered(enemy_node: Node)
signal enemy_stomp(position: Vector2, radius: float)
signal combo_updated(multiplier: float)
signal rage_bar_changed(current: float, maximum: float)
signal elemental_reaction_triggered(reaction: int, position: Vector2)
signal status_effect_applied(target: Node, effect: int, duration: float)

# ---------------------------------------------------------------------------
# Loot and coin signals
# ---------------------------------------------------------------------------
signal coin_collected(coin_type: int, amount: int)
signal loot_collected(item_resource: Resource)
signal revive_crystal_collected()
signal weapon_equipped(weapon_resource: Resource)
signal artifact_equipped(artifact_resource: Resource, slot_index: int)

# ---------------------------------------------------------------------------
# Dungeon signals
# ---------------------------------------------------------------------------
signal floor_changed(new_floor: int)
signal room_cleared(room_node: Node)
signal room_entered(room_node: Node, room_type: int)
signal door_unlocked(door_node: Node)
signal dungeon_run_started(floor_num: int)
signal dungeon_run_ended(reason: String, stats: Dictionary)
signal boss_room_entered(boss_tier: int)
signal boss_intro_requested(intro_data: Dictionary)
signal malachar_voice_taunt(taunt_text: String)
signal rival_save_choice_requested(rival_node: Node)
signal town_entered(town_node: Node)
signal town_raid_started(town_node: Node)
signal town_raid_won(reward: Resource)
signal secret_room_discovered(room_node: Node)
signal flashback_triggered(position: Vector2)

# ---------------------------------------------------------------------------
# Recruit signals
# ---------------------------------------------------------------------------
signal recruit_died(recruit_data: Resource, position: Vector2)
signal recruit_sent_to_base(recruit_data: Resource)
signal recruit_leveled_up(recruit_data: Resource)
signal recruit_joined_party(recruit_data: Resource)
signal recruit_left_party(recruit_data: Resource)
signal recruit_revived(recruit_data: Resource)
signal recruit_retired(recruit_data: Resource)
signal disciple_party_activated(mentor_data: Resource)
signal funeral_cutscene_requested(recruit_data: Resource)

# ---------------------------------------------------------------------------
# Pet signals
# ---------------------------------------------------------------------------
signal pet_equipped(pet_data: Resource)
signal pet_unequipped()
signal pet_evolved(pet_data: Resource, new_stage: int)
signal pet_bond_leveled_up(pet_data: Resource, new_level: int)
signal pet_treat_used(treat_data: Resource, pet_data: Resource)

# ---------------------------------------------------------------------------
# Base signals
# ---------------------------------------------------------------------------
signal base_raid_started()
signal base_raid_ended(victory: bool)
signal base_building_damaged(building_name: String)
signal base_building_repaired(building_name: String)
signal base_festival_started()
signal monument_built(monument_name: String)
signal dream_sequence_triggered()

# ---------------------------------------------------------------------------
# Progression signals
# ---------------------------------------------------------------------------
signal upgrade_point_gained(new_total: int)
signal upgrade_purchased(node_id: String)
signal class_unlocked(class_type: int)
signal class_mastery_gained(class_type: int, new_count: int)
signal achievement_unlocked(achievement_id: String)
signal legacy_run_started(generation: int)

# ---------------------------------------------------------------------------
# UI signals
# ---------------------------------------------------------------------------
signal hud_update_hp(current: float, maximum: float)
signal hud_update_recruit_hp(current: float, maximum: float, visible: bool)
signal hud_update_coins(copper: int, silver: int, gold: int)
signal hud_update_floor(floor_num: int)
signal hud_update_combo(multiplier: float)
signal hud_update_ultimate_cooldown(fraction: float)
signal hud_move_direction(direction: Vector2)
signal notification_requested(message: String, color: Color)
signal lore_entry_unlocked(entry_id: String)

# ---------------------------------------------------------------------------
# Multiplayer / async signals (future use)
# ---------------------------------------------------------------------------
signal friend_message_found(message: String, position: Vector2)
signal ghost_run_loaded(ghost_data: Dictionary)
signal daily_dungeon_score_submitted(score: int)
