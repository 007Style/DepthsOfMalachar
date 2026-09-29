#!/usr/bin/env python3
"""Generate all 16 enemy .tscn scene files for The Depths of Malachar."""

import os

ENEMIES = [
    {
        "name": "OrcGrunt",
        "script": "orc_grunt.gd",
        "sprite": "orc_grunt.svg",
        "uid": "uid://orc_grunt",
        "shape": "28 36",
    },
    {
        "name": "OrcShaman",
        "script": "orc_shaman.gd",
        "sprite": "orc_shaman.svg",
        "uid": "uid://orc_shaman",
        "shape": "24 36",
    },
    {
        "name": "SkeletonWarrior",
        "script": "skeleton_warrior.gd",
        "sprite": "skeleton_warrior.svg",
        "uid": "uid://skeleton_warrior",
        "shape": "24 38",
    },
    {
        "name": "SkeletonArcher",
        "script": "skeleton_archer.gd",
        "sprite": "skeleton_archer.svg",
        "uid": "uid://skeleton_archer",
        "shape": "22 36",
    },
    {
        "name": "DemonImp",
        "script": "demon_imp.gd",
        "sprite": "demon_imp.svg",
        "uid": "uid://demon_imp",
        "shape": "20 26",
    },
    {
        "name": "StoneGolem",
        "script": "stone_golem.gd",
        "sprite": "stone_golem.svg",
        "uid": "uid://stone_golem",
        "shape": "36 44",
    },
    {
        "name": "VineLurker",
        "script": "vine_lurker.gd",
        "sprite": "vine_lurker.svg",
        "uid": "uid://vine_lurker",
        "shape": "26 36",
    },
    {
        "name": "FrostWraith",
        "script": "frost_wraith.gd",
        "sprite": "frost_wraith.svg",
        "uid": "uid://frost_wraith",
        "shape": "24 36",
    },
    {
        "name": "ThunderHawk",
        "script": "thunder_hawk.gd",
        "sprite": "thunder_hawk.svg",
        "uid": "uid://thunder_hawk",
        "shape": "30 20",
    },
    {
        "name": "PoisonCrawler",
        "script": "poison_crawler.gd",
        "sprite": "poison_crawler.svg",
        "uid": "uid://poison_crawler",
        "shape": "40 18",
    },
    {
        "name": "ShadowStalker",
        "script": "shadow_stalker.gd",
        "sprite": "shadow_stalker.svg",
        "uid": "uid://shadow_stalker",
        "shape": "22 36",
    },
    {
        "name": "EarthElemental",
        "script": "earth_elemental.gd",
        "sprite": "earth_elemental.svg",
        "uid": "uid://earth_elemental",
        "shape": "34 40",
    },
    {
        "name": "CursedKnight",
        "script": "cursed_knight.gd",
        "sprite": "cursed_knight.svg",
        "uid": "uid://cursed_knight",
        "shape": "28 38",
    },
    {
        "name": "BloodBat",
        "script": "blood_bat.gd",
        "sprite": "blood_bat.svg",
        "uid": "uid://blood_bat",
        "shape": "28 18",
    },
    {
        "name": "AirDjinn",
        "script": "air_djinn.gd",
        "sprite": "air_djinn.svg",
        "uid": "uid://air_djinn",
        "shape": "28 38",
    },
    {
        "name": "WaterSerpent",
        "script": "water_serpent.gd",
        "sprite": "water_serpent.svg",
        "uid": "uid://water_serpent",
        "shape": "30 26",
    },
]

TEMPLATE = '''\
[gd_scene load_steps=5 format=3 uid="{uid}"]

[ext_resource type="Script" path="res://scripts/enemies/{script}" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/sprites/characters/enemies/{sprite}" id="2_sprite"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2({shape})

[sub_resource type="Animation" id="Animation_idle"]
resource_name = "idle"
length = 1.0
loop_mode = 1

[node name="{name}" type="CharacterBody2D"]
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_sprite")
scale = Vector2(1, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_1")

[node name="NavigationAgent2D" type="NavigationAgent2D" parent="."]
path_desired_distance = 4.0
target_desired_distance = 4.0
avoidance_enabled = true

[node name="AttackArea" type="Area2D" parent="."]

[node name="AttackAreaShape" type="CollisionShape2D" parent="AttackArea"]
shape = SubResource("RectangleShape2D_1")

[node name="HealthBar" type="ProgressBar" parent="."]
offset_left = -20.0
offset_top = -36.0
offset_right = 20.0
offset_bottom = -28.0
min_value = 0.0
max_value = 100.0
value = 100.0
show_percentage = false

[node name="HitFlashTimer" type="Timer" parent="."]
wait_time = 0.12
one_shot = true

[node name="StatusTimer" type="Timer" parent="."]
wait_time = 1.0

[node name="WeakPoint" type="Node2D" parent="."]
visible = false
'''

out_dir = "DepthsOfMalachar/scenes/enemies"
os.makedirs(out_dir, exist_ok=True)

for enemy in ENEMIES:
    content = TEMPLATE.format(**enemy)
    path = os.path.join(out_dir, f"{enemy['name']}.tscn")
    with open(path, "w") as f:
        f.write(content)
    print(f"Created {path}")

print("All 16 enemy scenes generated.")
