# The Depths of Malachar — Full Game Plan

---

## Game Identity

| Field | Value |
|-------|-------|
| **Title** | The Depths of Malachar |
| **Main Character** | Ethari |
| **Engine** | Godot 4 (GDScript) |
| **Perspective** | Top-Down 2D |
| **Primary Platform** | iOS |
| **Also Export To** | Android, Desktop (Windows/Mac/Linux), Web |
| **Genre** | Roguelite Dungeon Crawler with Deep Meta-Progression |
| **Multiplayer** | Local and Online Co-op (architected now, implemented later) |

---

## Lore & Story

### The Age of the Aurelian Kingdom
The **Aurelian Kingdom** was the greatest civilisation ever built by mortal hands — golden spires, mastery of all schools of magic, and a thousand years of peace under wise kings.

### The Coming of Malachar
**Malachar, the Demon King**, rose from the abyss — not with an army at first, but as a whisper. He corrupted nobles, twisted beasts, and poisoned the ley lines of magic. By the time the king understood, half his court had fallen. Malachar's true army then surfaced — endless demons, corrupted knights, elemental abominations, and ancient dragons. City after city fell.

### The Last Act of the Priests
In the final days, seven high priests gathered in the deepest chamber of the last standing temple and performed the **Rite of the Eternal Call** — a forbidden ritual to summon a god. **Aelion, the Formless Light** answered. He clashed with Malachar in a battle that split mountains and boiled oceans. But even a god could not win alone.

### The Secret of the Eighth Priest
*(Discovered naturally through lore collectibles — never revealed early)*
There were actually **eight priests**, not seven. The eighth betrayed the others and opened the gate for Malachar. Finding this truth is part of the hidden ending.

### Aelion's Last Breath
With his last divine power, Aelion forged **Ethari** — a being of infinite potential, capable of mastering any class or form. His final words:
> *"The king still lives, imprisoned in the depths. The demon holds him as a trophy of his greatest victory. Find the king. Free him. End this."*

### The King's Secret
*(Discovered deep in the dungeon)*
The imprisoned king **chose** to stay imprisoned — leaving would break a seal keeping something even older and more powerful than Malachar locked away. Ethari must decide: free the king and risk the seal, or find another way.

### Malachar's True Nature
*(Deep lore, New Game+ revelation)*
Malachar was not always evil. He was once a god like Aelion, corrupted by the ancient force the king's imprisonment seals away. The true enemy is something older than either of them.

### Post-Malachar
After Malachar falls, the seal weakens. New Game+ reveals the ancient force stirring — a sequel hook for a larger story.

### Ethari's Voice
- Early runs: silent and confused
- Later runs: Ethari speaks, reflects on past runs through the Legacy System, comments on the world
- Malachar's voice echoes through the dungeon — taunting, warning, reacting to player progress

---

## Core Gameplay Loop

```
Start Run → Choose Class → Enter Dungeon → Fight Enemies → Collect Loot/Coins/Resources
→ Visit Towns (optional) → Face Mini/Major/Secret Bosses → Die or Complete Run
→ Resources collected on death kept and sent to base
→ Return to Base → Funeral cutscene (if recruit died) → Keep 1 Weapon
→ Spend XP on Upgrade Points at Altar → Spend Coins at Base Shop
→ Start New Run
```

---

## Project Architecture

```
res://
├── scenes/
│   ├── player/
│   │   └── Ethari.tscn
│   ├── classes/
│   │   └── [one .tscn per class]
│   ├── enemies/
│   │   ├── BaseEnemy.tscn
│   │   └── [one .tscn per enemy type]
│   ├── bosses/
│   │   ├── BaseBoss.tscn
│   │   ├── MiniBoss/
│   │   ├── MajorBoss/
│   │   └── SecretBoss/
│   ├── recruits/
│   │   └── Recruit.tscn
│   ├── pets/
│   │   └── BasePet.tscn
│   ├── rooms/
│   │   ├── Room.tscn
│   │   ├── BossRoom.tscn
│   │   ├── TownRoom.tscn
│   │   ├── PuzzleRoom.tscn
│   │   ├── ArenaRoom.tscn
│   │   ├── CurseRoom.tscn
│   │   ├── MirrorRoom.tscn
│   │   └── DungeonGenerator.tscn
│   ├── base/
│   │   ├── Base.tscn
│   │   ├── Altar.tscn
│   │   ├── WeaponCabinet.tscn
│   │   ├── RecruitQuarters.tscn
│   │   ├── BaseShop.tscn
│   │   ├── Forge.tscn
│   │   ├── Library.tscn
│   │   ├── Tavern.tscn
│   │   ├── TrainingGrounds.tscn
│   │   ├── Gardens.tscn
│   │   ├── DungeonMapRoom.tscn
│   │   ├── Monument.tscn
│   │   ├── HallOfLegends.tscn
│   │   └── SpyNetwork.tscn
│   ├── ui/
│   │   ├── HUD.tscn
│   │   ├── MainMenu.tscn
│   │   ├── ClassSelect.tscn
│   │   ├── UpgradeTree.tscn
│   │   ├── WeaponKeepScreen.tscn
│   │   ├── GameOver.tscn
│   │   ├── RunStats.tscn
│   │   ├── TownUI.tscn
│   │   ├── LoreLog.tscn
│   │   ├── FuneralCutscene.tscn
│   │   ├── DreamSequence.tscn
│   │   ├── RunJournal.tscn
│   │   └── Settings.tscn
│   └── items/
│       ├── Weapon.tscn
│       ├── Artifact.tscn
│       ├── Loot.tscn
│       └── CoinDrop.tscn
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd         ← Autoload singleton
│   │   ├── progression_manager.gd  ← Autoload singleton
│   │   ├── save_manager.gd         ← Autoload singleton
│   │   ├── event_bus.gd            ← Autoload singleton
│   │   ├── friend_system.gd        ← Autoload singleton
│   │   └── daily_dungeon.gd        ← Autoload singleton
│   ├── player/
│   │   ├── ethari.gd
│   │   ├── class_controller.gd
│   │   └── stats.gd
│   ├── classes/
│   │   └── [one .gd per class]
│   ├── enemies/
│   │   ├── enemy_base.gd
│   │   └── [one .gd per enemy type]
│   ├── recruits/
│   │   └── recruit.gd
│   ├── pets/
│   │   └── pet_base.gd
│   ├── dungeon/
│   │   ├── dungeon_generator.gd
│   │   ├── room.gd
│   │   ├── town.gd
│   │   └── biome_manager.gd
│   └── items/
│       ├── item_data.gd
│       ├── weapon_data.gd
│       ├── artifact_data.gd
│       └── loot_table.gd
└── assets/
    ├── sprites/
    ├── tilesets/
    ├── audio/
    │   ├── music/
    │   └── sfx/
    └── fonts/
```

---

## Sub-Tasks

---

### Sub-Task 1 — Project Setup & Godot Structure

**Status:** `[x] done`

**Intent:**
Bootstrap the Godot 4 project with the correct folder structure, mobile display settings, autoload singletons, and iOS export configured.

**Expected Outcomes:**
- Godot 4 project opens without errors
- Full folder structure matches architecture above
- Display configured for mobile (480x854, stretch: canvas_items, aspect: keep)
- iOS export preset configured
- Six autoload singletons registered: GameManager, ProgressionManager, SaveManager, EventBus, FriendSystem, DailyDungeon
- Placeholder Main.tscn set as startup scene

**Todo List:**
1. Create new Godot 4 project named `DepthsOfMalachar`
2. Create full folder structure as defined in architecture above
3. Set project display resolution to 480x854, stretch mode: canvas_items, aspect: keep
4. Download and install iOS export templates via Godot Editor
5. Configure iOS export preset (bundle ID placeholder, team ID placeholder)
6. Create six empty autoload scripts in `scripts/core/`
7. Register all six as Autoload singletons in Project Settings
8. Create placeholder `Main.tscn` as startup scene
9. Configure portrait and landscape orientation support (player selectable in settings)

**Relevant Context:**
- Godot 4 Project Settings → Display → Window
- Godot 4 Project Settings → Autoload
- iOS export: Project → Export → Add → iOS

---

### Sub-Task 2 — Core Data Structures & Resource Classes

**Status:** `[x] done`

**Intent:**
Define all core data types as Godot Resource classes before building scenes. This grounds every system in a shared data contract and avoids tight coupling.

**Expected Outcomes:**
- All core data resource classes defined and usable in the editor
- All global enums defined in a shared location
- Loot table logic implemented and testable in isolation

**Todo List:**
1. Create `globals.gd` autoload — define all enums: ItemRarity, ElementType, CoinType, ClassType, TraitType, StatusEffect, BiomeType
2. Create `scripts/items/item_data.gd` — base Resource: name, rarity, description, lore text
3. Create `scripts/items/weapon_data.gd` — extends item_data: damage, attack speed, element, special effect, class restriction, blueprint bool
4. Create `scripts/items/artifact_data.gd` — extends item_data: effect type, effect value, stackable bool, set name
5. Create `scripts/items/pet_treat_data.gd` — extends item_data: effect type, effect value, element affinity
6. Create `scripts/player/stats.gd` — Resource: all stat fields (HP, damage, speed, crit chance, elemental bonuses, etc.)
7. Create `scripts/classes/class_data.gd` — Resource: class name, base stats, passive, abilities, ultimate, unlock condition, mastery count, lore text, prestige class ref
8. Create `scripts/enemies/enemy_data.gd` — Resource: name, element, HP, damage, speed, loot table, lore text, evolution threshold
9. Create `scripts/items/loot_table.gd` — weighted random item/coin selection, floor-depth adjusted rarity
10. Create `scripts/recruits/recruit_data.gd` — Resource: name, class, stats, traits, level, XP, bond levels, backstory, veteran titles, mentor ref, disciple refs, birthday
11. Create `scripts/pets/pet_data.gd` — Resource: name, element, stat boosts, ability, heal ability, bond level, evolution stage, personality trait, treat XP

**Enums to Define:**
- `ItemRarity`: Common, Uncommon, Rare, Epic, Mythical, Legendary, Secret
- `ElementType`: Fire, Earth, Air, Water, Lightning, Poison, Ice, Dark, Light, Rock, Steel, LifePlant, LifeSteal
- `CoinType`: Copper, Silver, Gold (100 Copper = 1 Silver, 100 Silver = 1 Gold)
- `StatusEffect`: Burn, Freeze, Stun, Slow, Poison, Bleed, Curse, Charm, Electrocute, ToxicExplosion, Steam
- `BiomeType`: Catacombs, VolcanicCaves, FrozenDepths, ShadowRealm, DemonSanctum

**Relevant Context:**
- Godot 4 `@export` annotations on Resource classes for editor editing
- All `.tres` data files stored in `assets/data/`

---

### Sub-Task 3 — Class System

**Status:** `[ ] pending`

**Intent:**
Build the full class system — 15 starter classes, unlockable classes, prestige classes, dual class, class mastery, class-specific quests, and Ethari's True Form.

**Expected Outcomes:**
- 15 starter classes fully defined with stats, passives, 2 abilities, and 1 ultimate each
- Additional classes flagged as locked with unlock conditions
- ClassController loads selected class, applies stats and abilities to Ethari
- Class mastery tracked (runs played per class), mastery bonus unlocked at threshold
- Class-specific secret quests defined (e.g. Necromancer: raise 500 enemies total)
- Prestige classes unlock after mastering base class
- Dual class unlock available via upgrade tree (blend two classes)
- Ethari's True Form unlocks after mastering ALL classes — all abilities combined
- Class Select UI shows class cards with stats, abilities, lore, lock status

**Starter Classes:**

| Class | HP | Damage | Speed | Playstyle |
|-------|----|--------|-------|-----------|
| Warrior | High | High | Medium | Melee tank, shield bash, Attack/Defence stances |
| Mage | Low | Very High | Low | Elemental spells, area damage, stance: Offensive/Arcane |
| Rogue | Medium | High | High | Fast attacks, stealth, crits, stance: Shadow/Assassin |
| Necromancer | Medium | Medium | Low | Raises fallen enemies as undead minions |
| Paladin | High | Medium | Low | Holy attacks, self-heal, buffs recruits |
| Archer | Medium | High | High | Ranged, piercing arrows, traps |
| Druid | Medium | Medium | Medium | LifePlant element, summon vines, nature healing |
| Assassin | Low | Very High | Very High | One-shot potential, invisible dashes |
| Berserker | Very High | Very High | High | Rage mechanic, more damage at low HP |
| Elementalist | Low | Extreme | Low | Combines two elements for hybrid reactions |
| Monk | High | Medium | Very High | Unarmed combat, ki abilities, momentum dash |
| Bard | Medium | Low | High | Buffs recruits, debuffs enemies, songs |
| Summoner | Low | Low | Low | Summons grow stronger over time |
| Witch Hunter | Medium | High | Medium | Bonus damage vs demons/undead, traps |
| Knight | Very High | Medium | Low | Heavy armour, counter-attack, fortify |

**Additional Unlockable Classes (examples):**
Vampire, Pirate, Gunslinger, Time Mage, Shadow Dancer, Alchemist, Pyromancer, Cryomancer, Storm Caller, Blood Mage, Tinkerer, Bounty Hunter, Gladiator, Shapeshifter, Seer/Prophet

**Todo List:**
1. Create `scripts/player/class_controller.gd` — loads ClassData, applies stats, registers abilities
2. Create ClassData `.tres` files for all 15 starter classes in `assets/data/classes/`
3. Implement ability system — abilities as nodes attached/detached based on active class
4. Implement stance system — some classes toggle between two stances changing active abilities
5. Implement class mastery tracking in `progression_manager.gd`
6. Implement class mastery bonus unlock at threshold
7. Define class-specific secret quests in ClassData, track progress in `progression_manager.gd`
8. Implement prestige class unlock when base class mastery maxed
9. Implement dual class — blend two selected classes at the Altar (upgrade tree unlock required)
10. Implement Ethari's True Form — unlocks when all classes mastered, combines all abilities
11. Create `scenes/ui/ClassSelect.tscn` — grid of class cards, locked classes shown as silhouettes
12. Wire Altar to open ClassSelect screen

**Relevant Context:**
- `scripts/player/class_controller.gd`
- `scenes/ui/ClassSelect.tscn`
- `scenes/base/Altar.tscn`

---

### Sub-Task 4 — Ethari (Player Character)

**Status:** `[ ] pending`

**Intent:**
Build Ethari — movement, combat, health, abilities, inventory, coin tracking, revive system, and voice/personality progression.

**Expected Outcomes:**
- Ethari moves with virtual joystick (top-down 2D)
- Stats driven by active ClassData + meta upgrades + legacy bonuses
- Primary attack, secondary ability, ultimate (with cooldown) all functional
- Inventory: 1 weapon slot, 4 artifact slots (upgradeable to 5), 1 pet slot
- Coin purse tracks Copper/Silver/Gold with auto-conversion
- Revive Crystal mechanic: revive on same floor, loot intact, resources collected on death sent to base
- Death flow: emit player_died, trigger run-end sequence
- Ethari's voice lines develop over legacy runs
- Ethari's journal auto-fills with key moments

**Todo List:**
1. Create `scenes/player/Ethari.tscn` — CharacterBody2D, Sprite2D, CollisionShape2D, AnimationPlayer
2. Write `scripts/player/ethari.gd` — movement, health, death signal, coin tracking, resource tracking
3. Implement attack system — primary, secondary, ultimate routing through class_controller.gd
4. Implement stance toggle input for classes that support it
5. Implement combo system — chain attacks without getting hit to build damage multiplier
6. Implement parry/counter — precise timing window blocks attack, opens counter window
7. Implement rage mode — fill rage bar by taking damage, activate for power boost
8. Implement momentum attack — dashing into enemy deals bonus collision damage
9. Implement inventory system — weapon slot, 4 artifact slots, pet slot
10. Implement coin purse with auto-conversion (100 copper → 1 silver, 100 silver → 1 gold)
11. Implement Revive Crystal use — revive on same floor, all loot and inventory intact
12. On death without crystal: collect all resources gathered during run and flag for base transfer
13. Implement Ethari's journal — auto-write entries on key events (first boss kill, recruit death, floor milestone)
14. Implement Ethari's voice line system — voice lines unlock and evolve based on legacy run count

**Relevant Context:**
- `scripts/player/ethari.gd`
- `scripts/player/class_controller.gd`
- `scripts/core/event_bus.gd`

---

### Sub-Task 5 — Mobile Touch Controls & HUD

**Status:** `[x] done`

**Intent:**
Build the full on-screen touch control layer and in-run HUD for iOS, fully playable with touch input.

**Expected Outcomes:**
- Virtual joystick (bottom-left) controls movement
- Attack, Ability 1, Ability 2, Ultimate buttons (right side)
- Ultimate has cooldown arc indicator
- HP bar (player), HP bar (active recruit, hidden when none)
- Coin display (Copper/Silver/Gold), floor counter, pet icon
- Stance toggle button (visible only for stance-based classes)
- Combo multiplier display
- Rage bar display (visible only for Berserker and rage-capable classes)
- Recruit send-back-to-base button
- Inventory panel (slide-up) showing weapon + artifact slots
- Portrait and landscape layout both supported
- Haptic feedback on hits, boss deaths, loot pickups, level up

**Todo List:**
1. Create `scenes/ui/HUD.tscn` with CanvasLayer
2. Add virtual joystick (Godot Asset Library: Virtual Joystick plugin)
3. Add TouchScreenButton nodes: Attack, Ability1, Ability2, Ultimate, StanceToggle
4. Add Ultimate cooldown arc indicator over Ultimate button
5. Add HP bar (player), HP bar (recruit — hidden when no recruit active)
6. Add coin display with three icons and counts
7. Add floor counter, pet icon slot, combo multiplier label, rage bar
8. Add recruit send-back-to-base button (visible only when recruit is active)
9. Add slide-up inventory panel
10. Implement portrait and landscape layout switching
11. Implement haptic feedback via Godot Input.vibrate_handheld()
12. Wire all inputs to EventBus signals

**Relevant Context:**
- `scenes/ui/HUD.tscn`
- Godot TouchScreenButton, InputEventScreenTouch
- Virtual Joystick plugin from Godot Asset Library

---

### Sub-Task 6 — Enemy System

**Status:** `[x] done`

**Intent:**
Build a scalable enemy system with 15+ unique enemy types, elemental weaknesses, status effects, weak points, aerial enemies, and an enemy evolution mechanic.

**Expected Outcomes:**
- BaseEnemy handles HP, element, AI state machine, take_damage, death, loot drop, coin drop, status effects
- Enemies scale with floor depth
- Elemental weakness/strength table implemented
- Weak points on select enemies (glowing spot, bonus damage on hit)
- Aerial enemies only hittable by ranged or jump attacks
- Status effects: Burn, Freeze, Stun, Slow, Poison, Bleed, Curse, Charm, Electrocute, ToxicExplosion, Steam
- Elemental combo reactions: Fire+Ice=Steam, Lightning+Water=Electrocute, Poison+Fire=ToxicExplosion
- Enemy evolution: if player dies repeatedly to same enemy type it gains a new attack or stat boost
- Dynamic difficulty: subtle adjustments if player is struggling or dominating
- Environmental kills: knock enemies into pits, lava, spikes for instant kills
- Execution mechanic: enemies below 10% HP can be executed for bonus coins
- Destructible environment elements in rooms

**Starter Enemy Roster (16 types):**

| Enemy | Element | Behavior |
|-------|---------|----------|
| Orc Grunt | Steel | Melee charge |
| Orc Shaman | Fire | Ranged fireballs, status: Burn |
| Skeleton Warrior | Dark | Melee, revives once |
| Skeleton Archer | Dark | Ranged bone arrows |
| Demon Imp | Fire | Fast erratic movement, swarm |
| Stone Golem | Rock | Slow, high HP, shockwave stomp |
| Vine Lurker | LifePlant | Immobilises player with roots |
| Frost Wraith | Ice | Slows player on hit, teleports |
| Thunder Hawk | Lightning | Dive bomb, area shock — aerial |
| Poison Crawler | Poison | Leaves poison trail on ground |
| Shadow Stalker | Dark | Turns invisible, ambushes |
| Earth Elemental | Earth | Burrows underground, surprise attack |
| Cursed Knight | Steel | Mimics player attack patterns |
| Blood Bat | LifeSteal | Heals from player damage dealt — aerial |
| Air Djinn | Air | Pushes player back, tornado spin — aerial |
| Water Serpent | Water | Floods area, slows movement |

**Todo List:**
1. Create `scenes/enemies/BaseEnemy.tscn` — CharacterBody2D, Sprite2D, CollisionShape2D, NavigationAgent2D, HealthBar
2. Write `scripts/enemies/enemy_base.gd` — HP, damage, element, AI state machine, status effect handler
3. Implement floor-scaling formula: `scaled_hp = base_hp * (1 + floor * 0.08)`
4. Implement elemental weakness/strength table
5. Implement elemental combo reaction system via EventBus
6. Implement status effect system — each effect has duration, tick damage/slow/etc.
7. Implement weak point nodes on applicable enemies
8. Implement aerial enemy flag — only hittable by ranged attacks
9. Implement enemy evolution tracker in `progression_manager.gd`
10. Implement dynamic difficulty system in `game_manager.gd`
11. Implement execution mechanic — prompt appears at 10% enemy HP
12. Add destructible environment objects (barrels, pillars) as separate scenes
13. Create all 16 starter enemy scenes extending BaseEnemy

**Relevant Context:**
- `scripts/enemies/enemy_base.gd`
- `scripts/items/loot_table.gd`
- Godot NavigationAgent2D

---

### Sub-Task 7 — Boss System

**Status:** `[x] done`

**Intent:**
Build three tiers of boss encounters with multi-phase fights, cinematic intros, lore reveals, artifact drops, and the legendary Floor 666 secret boss.

**Expected Outcomes:**
- Mini Boss every 10 floors, Major Boss every 25 floors, Secret Boss every 100 floors
- Floor 666 has a unique secret boss appearing randomly, not tied to the tier system
- All bosses: multi-phase (transitions at 66% and 33% HP), cinematic name card intro, guaranteed artifact drop, lore unlock
- Boss tells — telegraph big attacks with visible wind-up
- Boss rooms have sealed doors during fight
- Malachar reacts to boss defeats with taunting voice lines

**Boss Roster (examples):**

| Boss | Tier | Element | Mechanic |
|------|------|---------|---------|
| The Rotting Warlord | Mini | Steel/Dark | Summons skeleton adds at 50% HP |
| Ignareth the Flame Titan | Mini | Fire | Floor becomes lava in phase 2 |
| Glacius, Frozen Sovereign | Major | Ice | Freezes arena, break ice pillars |
| The Void Herald | Major | Dark | Splits into shadow clones |
| Rival Adventurer 1 (corrupted) | Major | Varies | Mirrors player class abilities |
| Rival Adventurer 2 (corrupted) | Major | Varies | Mirrors player class abilities |
| Malachar, Demon King | Secret | All Elements | Final boss, 5 phases |
| The Ancient — Floor 666 Boss | Secret | Dark/LifeSteal | Unique mechanics, hidden lore |

**Todo List:**
1. Create `scenes/bosses/BaseBoss.tscn` extending BaseEnemy — larger scale, phase system, intro sequence
2. Write boss base script — phase transitions, intro name card, artifact drop, lore unlock trigger
3. Implement phase transition: visual effect, new attack pattern at 66% and 33% HP
4. Create boss intro UI — name card with lore quote, fade-in animation
5. Design and implement 5 Mini Bosses
6. Design and implement 4 Major Bosses
7. Design and implement Malachar (5-phase final boss, all elements, world-ending scale)
8. Design and implement Floor 666 secret boss — unique enemy type not found elsewhere
9. Implement Rival Adventurer boss fights — mirror player class, choice to save or fight
10. Wire boss death to artifact drop, lore unlock, Malachar voice taunt, transition to next floor
11. Implement boss tell system — visual wind-up indicator before big attacks

**Relevant Context:**
- `scenes/bosses/`
- `scripts/enemies/enemy_base.gd`
- `scripts/items/artifact_data.gd`

---

### Sub-Task 8 — Dungeon Generation & Biomes

**Status:** `[x] done`

**Intent:**
Procedurally generate infinite dungeon floors with connected rooms, biome themes every 25 floors, special room types, environmental storytelling, and seasonal biomes.

**Expected Outcomes:**
- Each floor is a fresh procedurally generated grid of connected rooms
- 5 biome themes, each with unique tilesets, enemies, and atmosphere: Catacombs (1–25), Volcanic Caves (26–50), Frozen Depths (51–75), Shadow Realm (76–99), Demon Sanctum (100+)
- Room types: Combat, Empty, Chest, Town, Puzzle, Trap, Curse, Mirror, Arena, Shrine, Flooded, Secret (breakable walls), CorruptedTown, Mini Boss, Major Boss, Secret Boss
- Environmental storytelling: pre-fall Aurelian flashback tiles, remnant objects (child's toy, broken throne)
- Seasonal biome: special biome appears during real-world seasons (frost in winter, bloom in spring)
- Floor 666 always generates the secret boss room
- Weather system: certain floors have rain, ash fall, or magical storms affecting gameplay

**Todo List:**
1. Import or create stone dungeon tileset for each biome theme
2. Create `scenes/rooms/Room.tscn` — TileMapLayer, spawn markers, door nodes, enemy spawner
3. Write `scripts/dungeon/dungeon_generator.gd` — BSP room placement on grid
4. Implement room type assignment — weighted random with floor-based rules
5. Implement corridor carving between rooms
6. Implement `scripts/dungeon/biome_manager.gd` — assign biome based on floor range, apply tileset and enemy pool
7. Implement enemy spawner — reads floor depth and biome, picks weighted enemy pool
8. Implement door transitions — fade out, load next room, fade in
9. Implement floor completion — all enemies dead → doors unlock
10. Implement special room scenes: Puzzle, Trap, Curse, Mirror, Arena, Shrine, Flooded, Secret
11. Implement corrupted town rooms — former town overtaken by enemies, loot inside
12. Implement pre-fall flashback tiles — step on trigger tile → ghost vision of room in its former glory
13. Implement Aelion's echo triggers — ghostly vision appears at key floor milestones
14. Implement weather system — weather type applied per floor, affects gameplay (lightning strikes, reduced visibility)
15. Implement seasonal biome detection using system date
16. Implement Floor 666 special generation rule

**Relevant Context:**
- `scripts/dungeon/dungeon_generator.gd`
- `scripts/dungeon/biome_manager.gd`
- Godot TileMapLayer (Godot 4.x)

---

### Sub-Task 9 — Surviving Towns

**Status:** `[x] done`

**Intent:**
Build surviving town rooms — dynamic safe zones with shops, healing, recruits, lore, and raid defence events. Towns grow more hopeful as player progresses.

**Expected Outcomes:**
- Entering town restores Ethari to full HP immediately
- Town contains: Shop, Artifact Vendor (temporary), Upgrade Station, Recruitable NPC, Lore NPC, Healer, Gambling Den, Black Market (rare)
- ~15% of non-boss rooms are town rooms
- Raid events: ~20% chance on town entry — defend waves for reward
- NPC dialogue reflects world state — early runs: fearful, later runs: hopeful
- Reactive world: as major bosses fall, towns become more lively and populated
- Towns grow visually with player progress (more torches lit, more people)

**Todo List:**
1. Create `scenes/rooms/TownRoom.tscn` — larger room with NPC nodes, shop areas, visual areas
2. Write `scripts/dungeon/town.gd` — auto-heal on enter, NPC interactions, raid trigger, world state reactivity
3. Create `scenes/ui/TownUI.tscn` — shop, artifact vendor, upgrade, gambling panels
4. Implement Town Shop — buy weapons, potions, scrolls with run coins
5. Implement Artifact Vendor — 3 random temporary run artifacts for sale
6. Implement Upgrade Station — spend run coins to upgrade equipped weapon (+damage, +element)
7. Implement Gambling Den — risk coins for chance at rare loot
8. Implement Black Market — rare vendor offering cursed/illegal items at steep price
9. Implement Recruitable NPC — one random recruit per town, option to send to base
10. Implement Lore NPC — speaks random lore fragment from pool (20+ fragments)
11. Implement Raid Event — spawn enemy waves, defend timer, victory reward
12. Implement world state tracking in `game_manager.gd` — track major bosses defeated, update town dialogue
13. Implement shrine rooms — random blessing or curse gambling mechanic

**Relevant Context:**
- `scenes/rooms/TownRoom.tscn`
- `scripts/dungeon/town.gd`

---

### Sub-Task 10 — Loot, Weapons, Artifacts & Crafting

**Status:** `[x] done`

**Intent:**
Build the full loot system — 7 rarity tiers, weapons, artifacts (stackable, sets, runes, cursed), alchemy, blueprint crafting, poison/scroll crafting, and the end-of-run weapon keep mechanic.

**Expected Outcomes:**
- 7 rarity tiers: Common, Uncommon, Rare, Epic, Mythical, Legendary, Secret
- Weapons: rarity, element, damage, speed, special effect, class restriction, blueprint option
- Artifacts: stackable, set bonuses (collect full set for bonus), rune slots, cursed variants
- Revive Crystal: craftable from LifePlant garden, farmable from mobs, buyable (Epic tier)
- Alchemy: brew custom potions from dungeon ingredients
- Poison crafting: coat weapon in poison for limited attacks
- Scroll crafting: single-use scrolls (teleport, identify, temporary invincibility)
- Blueprint system: find blueprints in dungeon, craft at Forge
- Item identification: some drops are "Unknown Item" — identify at cost or with scroll
- Loot set system: collect all pieces of a named set for set bonus
- End-of-run: choose 1 weapon to keep → Weapon Cabinet

**Todo List:**
1. Create `scenes/items/Loot.tscn` — Area2D world pickup, auto-collect on player overlap
2. Create `scenes/items/CoinDrop.tscn` — coin pickup with type
3. Implement loot table — weighted rolls by rarity tier, floor-depth adjusted
4. Create starter weapon set: at least 3 weapons per element type across rarity tiers
5. Create starter artifact set: at least 20 artifacts with varying passives
6. Implement artifact stacking — duplicate artifact increases effect value
7. Implement loot set detection — check for full set in inventory, apply bonus
8. Implement rune system — attach runes to weapons in Forge for elemental/stat bonuses
9. Implement cursed weapon flag — powerful but with defined downside
10. Implement item identification system — unknown items must be identified
11. Implement alchemy/potion brewing — combine ingredients at Forge
12. Implement poison crafting and scroll crafting at Forge
13. Implement blueprint system — find blueprint → bring to Forge → craft weapon
14. Create `scenes/ui/WeaponKeepScreen.tscn` — post-run weapon selection UI
15. Wire kept weapon to SaveManager → stored in Weapon Cabinet
16. Create in-run inventory panel (slide-up from HUD)

**Loot Examples:**

| Name | Type | Rarity | Effect |
|------|------|--------|--------|
| Iron Sword | Weapon | Common | Basic melee, no element |
| Frostbite Dagger | Weapon | Rare | Ice element, slows on hit |
| Void Reaper | Weapon | Legendary | Dark element, life steal on kill |
| Ring of Embers | Artifact | Uncommon | +15% fire damage |
| Soul Anchor | Artifact | Epic | Revive once per run at 1 HP |
| Aelion's Tear | Artifact | Secret | All stats +25%, unique lore |
| Revive Crystal | Consumable | Epic | Revive Ethari or a recruit |

**Relevant Context:**
- `scripts/items/loot_table.gd`
- `scripts/items/weapon_data.gd`
- `scripts/items/artifact_data.gd`

---

### Sub-Task 11 — Recruit System

**Status:** `[x] done`

**Intent:**
Build the full recruit companion system — finding, managing, training, fighting alongside, retiring, mentoring, grieving, and the disciple party mechanic.

**Expected Outcomes:**
- Recruits found in town rooms — one recruitable NPC per town
- Recruits: name, class, random stats, 1–3 traits, level, XP, birthday, backstory, veteran titles
- Recruit cap starts at 50, upgradeable to 250 via Altar upgrade points
- Companion slots: 1 at start, upgradeable to 3 via upgrade tree
- Recruit AI fights alongside Ethari with its own pathfinding
- No friendly fire — player AOE does not damage recruits
- Permadeath: recruit HP reaches zero → permanent death
- On recruit death: surviving recruits leave dungeon carrying the fallen, wait at base for player choice
- Player continues run alone (or with remaining recruits) or ends the run
- Revive Crystal can revive a dead recruit at base
- Funeral: automatic cutscene on return (skippable), memorial placed at base
- Grief mechanic: bonded recruits ask to help find revive crystal (+75% overall boost)
- Send-back-to-base button: recruit teleports out safely before death
- Recruits gain XP from kills, level up, gain stat increases
- Recruit can be equipped with weapons from Weapon Cabinet
- Recruit relationships: friendships, rivalries, romances, unique paired abilities when paired in run
- Recruit children: two highly bonded recruits eventually have a child NPC born at base, grows up, becomes recruitable with inherited traits
- Veteran titles: recruits who survive many runs earn titles with passive bonuses
- Recruit council: 5 most senior recruits give one free hint per run
- Morale system: morale affects recruit performance; losses/deaths/raids lower it, victories/tavern/festivals raise it
- Legendary recruits: extremely rare named characters with unique classes and deep lore
- Recruit funerals add memorial markers at base
- Two Rival Adventurers: found as corrupted boss fights or saveable/recruitable, player chooses

**Retirement & Mentorship System:**
- Retired recruits become mentors at base — passively train disciples (up to 4 per mentor)
- Disciples gain XP faster than solo training
- Mentor traits and abilities can transfer to disciples over time
- Strong bond between mentor and disciple → disciple evolves learned abilities
- Mentor can be recalled from retirement max 5 times
- When mentor is recalled, disciples temporarily lose mentor bonus
- Disciple party rule: if all 4 disciples of the same mentor go into dungeon together with player, they are all allowed even past the companion cap, and receive +40% to all stats, skills, and abilities

**Todo List:**
1. Create `scenes/recruits/Recruit.tscn` — CharacterBody2D, AI, same structure as Ethari
2. Write `scripts/recruits/recruit.gd` — stats, traits, AI, level-up, bond tracking, veteran title logic
3. Implement trait system — TraitData resources, applied as stat modifiers
4. Implement synergy check — detect trait synergy pairs on party load
5. Implement recruit relationship system — friendship/rivalry/romance tracking, paired ability unlock
6. Implement recruit children system — bond threshold triggers child NPC birth at base
7. Implement companion slot system — 1 slot base, upgradeable to 3 via upgrade tree
8. Implement disciple party override rule — 4 disciples of same mentor get +40% and bypass cap
9. Implement retirement system — retire recruit, assign as mentor, assign disciples
10. Implement mentor passive training — disciples gain XP multiplier while player is on runs
11. Implement trait/ability transfer from mentor to disciple over bond levels
12. Implement mentor recall system — max 5 recalls per retired recruit
13. Implement permadeath — on recruit HP zero, trigger survivor exodus sequence
14. Implement survivor exodus — remaining recruits leave dungeon, carry fallen, wait at base
15. Implement revive choice at base — use Revive Crystal or hold funeral
16. Implement funeral cutscene — `scenes/ui/FuneralCutscene.tscn`, skippable, place memorial
17. Implement grief mechanic — bonded recruits offer to help find crystal, +75% boost
18. Implement send-back-to-base button and teleport effect
19. Implement recruit cap upgrade in Altar (50 → 250 via upgrade points)
20. Create `scenes/base/RecruitQuarters.tscn` — visual area showing all recruits
21. Implement recruit management UI — stats, equip weapon, assign to run party
22. Implement veteran title system — track runs survived, assign titles at thresholds
23. Implement recruit council — 5 senior recruits, one hint per run
24. Implement morale system — base morale value, affects recruit stats, modified by events
25. Implement Rival Adventurer encounters — boss fight or rescue, player choice

**Relevant Context:**
- `scenes/recruits/Recruit.tscn`
- `scripts/recruits/recruit.gd`
- `scenes/base/RecruitQuarters.tscn`

---

### Sub-Task 12 — Pet System

**Status:** `[x] done`

**Intent:**
Build the full pet system — collecting, evolving, fusing, bonding, naming, personality, legendary pets, and garden-crafted treats.

**Expected Outcomes:**
- Pets found as rare drops or bought at base shop
- Each pet: name (player-named), element affinity, stat boost, combat ability, heal ability, bond level, evolution stage, personality trait (Aggressive/Defensive/Supportive)
- Pet follows Ethari, auto-attacks nearby enemies
- Pet cannot die — retreats and returns after cooldown if hit too much
- One pet slot active per run (upgradeable via upgrade tree)
- Bond system: more runs with a pet → stronger bond → more powerful
- Evolution: feed pet garden-crafted treats to evolve into stronger forms
- Fusion: combine two pets to create hybrid with both abilities
- Legendary pets: extremely rare, game-changing (e.g. baby dragon, ghost of fallen king, light wisp)
- Pet treats: crafted in gardens from grown ingredients, wide variety of elemental and stat effects

**Pet Treat Examples:**

| Treat | Ingredients | Effect |
|-------|------------|--------|
| Fire Treat | Fire Herb + Ember Crystal | +Fire damage, fire breath ability boost |
| Frost Treat | Frost Berry + Ice Shard | +Ice damage, freeze chance on attack |
| Vitality Treat | Healing Root + Honey | +Pet healing ability, +HP |
| Shadow Treat | Dark Moss + Void Dust | +Dark damage, pet invisibility dash |
| Lightning Treat | Storm Seed + Thunder Crystal | +Lightning damage, chain attack |
| Life Treat | Lifebloom + Spring Water | +Bond XP gain, +HP regen aura |
| Stone Treat | Rock Salt + Iron Ore | +Pet defence, stomp shockwave |
| Poison Treat | Toxic Mushroom + Venom Sap | +Poison damage, poison trail |
| Holy Treat | Sunflower + Light Dust | +Light damage, small party heal |
| Chaos Treat | Mixed rare ingredients | Random powerful effect |

**Todo List:**
1. Create `scenes/pets/BasePet.tscn` — follower with Sprite2D, simple AI, no death
2. Write `scripts/pets/pet_base.gd` — follow player, auto-attack, heal trigger, retreat logic, bond XP
3. Create PetData resource files for starter pets (5+) and legendary pets
4. Implement bond level system — bond XP gained each run, levels increase stat boosts
5. Implement evolution system — treat consumption triggers evolution, visual change, stat boost
6. Implement pet fusion — combine two pets, merge abilities, create hybrid sprite
7. Implement pet naming UI
8. Implement personality trait effect on AI behavior
9. Create treat crafting system — recipe list, ingredient matching, create treat item
10. Implement legendary pet drop conditions
11. Add pet slot to HUD and base management UI

**Relevant Context:**
- `scenes/pets/BasePet.tscn`
- `scripts/pets/pet_base.gd`
- `scenes/base/Gardens.tscn`

---

### Sub-Task 13 — The Base (Visual Hub)

**Status:** `[x] done`

**Intent:**
Build the full visual base — a walkable ruined temple of Aelion that grows and expands as the player progresses, with all interactive systems accessible from this area.

**Expected Outcomes:**
- Base is a walkable top-down 2D area
- Distinct visual style: ruined temple, warm lighting, Aurelian Kingdom banners
- Base expands physically as player progresses — new areas of the ruined temple unlock
- All interactive areas accessible: Altar, Weapon Cabinet, Recruit Quarters, Shop, Forge, Library, Tavern, Training Grounds, Gardens, Dungeon Map Room, Spy Network, Monument area, Hall of Legends
- Recruits visible walking around the base
- Base festivals triggered after major victories
- Base raids by Malachar — defend with recruits (buildings can be damaged, need repair)
- The Last Survivor NPC — always present, never fights, remembers everything, tells the story of your legacy
- Ethari's dreams: occasionally trigger a short dream sequence at the base showing Aelion's memories
- Ambient music distinct from dungeon music (calmer, hopeful tone)

**Base Buildings:**

| Building | Function |
|----------|---------|
| Altar of Aelion | Class select, upgrade tree, recruit cap upgrade |
| Weapon Cabinet | Store and equip kept weapons |
| Recruit Quarters | View, manage, equip recruits |
| Base Shop | Buy permanent artifacts with base coins |
| Forge | Craft weapons from blueprints, brew potions, add runes |
| Library | Lore log access, passive +XP per run bonus |
| Tavern | Boost recruit morale, visit for passive bonuses |
| Training Grounds | Recruits passively train; mentors train disciples here |
| Gardens | Grow ingredients for pet treats, potions, Revive Crystals (LifePlant) |
| Dungeon Map Room | Reveals more floor layout on next run |
| Spy Network | Spend coins to scout next floor enemy types |
| Monument Area | Build monuments after great victories for passive bonuses |
| Hall of Legends | Record of every Ethari from every legacy run |

**Todo List:**
1. Design base layout — all buildings placed logically in the ruined temple space
2. Create `scenes/base/Base.tscn` — TileMapLayer with base tileset, interactive zones
3. Place Area2D interaction zones on each building — show prompt on player overlap
4. Implement base expansion — new building areas unlock as progression milestones are reached
5. Spawn recruit sprites in Recruit Quarters based on current roster
6. Implement base festival event — triggered after major boss defeat, morale boost, special merchant
7. Implement base raid event — Malachar sends waves, recruits and Ethari defend, buildings damageable
8. Implement building repair system — damaged buildings need coins to repair
9. Implement The Last Survivor NPC — dialogue reflects full legacy history
10. Implement dream sequence trigger — occasional at base rest, shows Aelion memory fragment
11. Create base-specific ambient music
12. Wire dungeon entrance to GameManager.start_run() with class confirm

**Relevant Context:**
- `scenes/base/Base.tscn`
- `scripts/core/game_manager.gd`

---

### Sub-Task 14 — Meta Progression & Upgrade Tree

**Status:** `[x] done`

**Intent:**
Build the persistent upgrade tree — every 1,000 XP earned in a run grants 1 upgrade point; points spent at the Altar on permanent stat bonuses, unlocks, and quality-of-life upgrades. Recruit cap upgradeable from 50 to 250.

**Expected Outcomes:**
- XP earned during run does NOT carry over — only converts to upgrade points at run end
- Every 1,000 XP earned in a run = 1 upgrade point added to permanent pool
- Upgrade tree has visual node graph with prerequisite connections
- Upgrades persist via SaveManager
- Recruit cap upgradeable from 50 → 250 in stages
- Companion slots upgradeable 1 → 2 → 3
- Ancestor abilities: if a previous Ethari (legacy) mastered a class, descendants get a small bonus for that class

**Upgrade Tree Categories:**

| Category | Examples |
|----------|---------|
| Combat | +Max HP, +Base Damage, +Attack Speed, +Crit Chance |
| Mobility | +Move Speed, +Dodge, +Dash Distance |
| Companions | Companion Slot 2, Companion Slot 3, Recruit Cap upgrades |
| Inventory | Artifact Slot 5, Pet Slot 2 |
| Economy | +Coin Drop Rate, +Shop Discount, +Crafting Speed |
| Class Unlocks | Unlock new classes (each has individual cost) |
| Dungeon | +Chest Rate, Town Frequency Boost, Secret Room Chance |
| Legacy | Ancestor Ability bonuses per mastered class |

**Todo List:**
1. Create `scenes/ui/UpgradeTree.tscn` — visual node graph, connected by lines, prereq lock display
2. Write `scripts/core/progression_manager.gd` — track lifetime XP, upgrade points, purchased nodes
3. Implement XP-to-upgrade-point conversion: `points += floor(run_xp / 1000)`
4. Define all upgrade tree nodes with costs, effects, and prerequisites
5. Implement recruit cap upgrade nodes (50→100→150→200→250)
6. Implement node unlock logic — prerequisite nodes must be purchased first
7. Apply upgrade bonuses to Ethari stats on run start
8. Implement ancestor ability bonuses from legacy system
9. Persist upgrade tree state via SaveManager

**Relevant Context:**
- `scripts/core/progression_manager.gd`
- `scenes/ui/UpgradeTree.tscn`
- `scenes/base/Altar.tscn`

---

### Sub-Task 15 — Currency, Base Shop & Weapon Cabinet

**Status:** `[x] done`

**Intent:**
Build the three-tier currency system, the base shop for permanent artifacts, and the Weapon Cabinet for managing kept weapons.

**Expected Outcomes:**
- Copper, Silver, Gold tracked separately, auto-conversion display
- Coins collected during run are KEPT after run ends
- Run coins and base coins are separate pools — run coins merge into base pool at run end
- Base Shop sells permanent artifacts (stack with run artifacts), inventory rotates each run
- Weapon Cabinet displays all kept weapons, player selects run-start weapon
- Revive Crystals available for purchase at Epic rarity price

**Todo List:**
1. Create `scenes/base/BaseShop.tscn` — visual shop area with NPC shopkeeper
2. Write currency manager in `progression_manager.gd` — track base coin pool separately from run coins
3. Implement coin merge on run end — add run coins to base coin pool
4. Create permanent artifact inventory — stored in SaveManager, applied on run start
5. Implement shop rotation — new 4–6 artifacts available after each run
6. Create `scenes/base/WeaponCabinet.tscn` — display all kept weapons, select run-start weapon
7. Implement weapon equip from cabinet — chosen weapon is Ethari's starting weapon next run
8. Add Revive Crystal to shop at Epic price

**Relevant Context:**
- `scripts/core/progression_manager.gd`
- `scripts/core/save_manager.gd`
- `scenes/base/BaseShop.tscn`
- `scenes/base/WeaponCabinet.tscn`

---

### Sub-Task 16 — Save System

**Status:** `[x] done`

**Intent:**
Build a robust save/load system persisting all meta-progression data across sessions.

**Expected Outcomes:**
- All persistent data saves automatically after each run ends
- Save data: upgrade tree, upgrade points, weapon cabinet, base coin pool, recruit roster, pets, permanent artifacts, lore unlocked, legacy history, friend list, run journal entries, Hall of Legends entries
- Saved to `user://save_data.json` via Godot FileAccess
- Auto-load on game launch
- Corrupt save detected gracefully — defaults to fresh state
- Cloud save syncs to iCloud/backend (mobile)

**Todo List:**
1. Write `scripts/core/save_manager.gd` — `save()` and `load()` functions
2. Define save data schema as Dictionary with all persistent fields
3. Implement auto-save trigger — called by GameManager after run ends
4. Implement auto-load on game launch in Main.tscn
5. Implement save corruption guard — if parse fails, log error and load defaults
6. Implement cloud save integration for iOS (iCloud via Godot plugin or HTTP backend)
7. Test save/load round-trip for all data types

**Relevant Context:**
- `scripts/core/save_manager.gd`
- Godot FileAccess for `user://` path

---

### Sub-Task 17 — Lore, Bestiary & Story Systems

**Status:** `[x] done`

**Intent:**
Build a lore log, bestiary, Ethari's journal, and all story delivery systems — environmental storytelling, NPC dialogue, Aelion echoes, Malachar taunts, and dream sequences.

**Expected Outcomes:**
- Lore entries unlocked by: first enemy kill, boss defeat, town visit, floor milestone
- Bestiary: all enemy/boss types with lore, stats, element, unlock status
- Story journal: narrative fragments from town NPCs, floor milestone texts
- Malachar's journal: pages scattered in dungeons, telling story from his perspective
- Seventh/Eighth Priest lore fragments discovered naturally across many runs
- Lost King's memories found as depth increases
- Aelion's echoes appear as ghostly visions at key milestones
- Pre-fall flashback tiles in deep floors
- Dream sequences at base showing Aelion's memories
- Ethari's personal journal auto-fills from key events
- Rival Adventurers' journals found in dungeon
- Hidden ending unlocked by collecting all lore fragments

**Todo List:**
1. Add `lore_text` field to EnemyData, BossData, ClassData, ArtifactData
2. Write lore unlock logic in `progression_manager.gd`
3. Create `scenes/ui/LoreLog.tscn` — tabs: Story, Bestiary, Classes, Artifacts, Ethari's Journal
4. Populate all starter enemy lore entries (16+ enemies)
5. Write boss lore for all designed bosses
6. Write 20+ town NPC story fragments referencing kingdom's fall
7. Write Malachar's journal entries (10+ pages, scattered across floors)
8. Write Seven Priests fate entries (one per biome zone)
9. Write Eighth Priest betrayal fragments (discovered naturally, late game)
10. Write Lost King's memory fragments (deeper floors)
11. Implement floor milestone lore popups (floors 10, 25, 50, 100+)
12. Implement Aelion's echo vision system — ghostly overlay at trigger tiles
13. Implement pre-fall flashback tile system
14. Implement dream sequence scene — `scenes/ui/DreamSequence.tscn`
15. Implement Malachar taunt voice line triggers — boss defeat, floor depth, rival adventurer saved
16. Implement Ethari's auto-journal — write entries on: first boss kill, recruit death, new class mastery, floor 100 reached, legacy transition
17. Implement hidden ending unlock condition — all lore fragments collected

**Relevant Context:**
- `scenes/ui/LoreLog.tscn`
- `scripts/core/progression_manager.gd`

---

### Sub-Task 18 — Legacy System & Hall of Legends

**Status:** `[x] done`

**Intent:**
Build the generational legacy system — after completing New Game+, start as Ethari's descendant inheriting bonuses and lore, with the Hall of Legends recording every run permanently.

**Expected Outcomes:**
- After New Game+ completion, player can begin a Legacy Run as Ethari's descendant
- Descendant inherits: small stat bonuses from previous Ethari's mastered classes, a lore entry, The Last Survivor NPC remembers them
- Each legacy generation has a unique identifier and is recorded in the Hall of Legends
- Hall of Legends: wall at base displaying every Ethari — class, deepest floor, greatest kill, how they died
- Ancestor abilities: if previous Ethari mastered a class, current Ethari gets a small unique bonus for that class
- The True Ending: only achievable after multiple legacy runs — final secret chapter reveals full truth about Aelion, Malachar, and what Ethari truly is
- Photo mode / run journal: auto-screenshot after each run showing floor reached, class, recruits

**Todo List:**
1. Implement legacy transition — on New Game+ completion, prompt to begin legacy run
2. Create legacy character data — inherits from previous Ethari's progression record
3. Implement ancestor ability bonuses in upgrade tree
4. Create `scenes/base/HallOfLegends.tscn` — scrollable wall of all past Ethari entries
5. Implement run record saving — after each run save: class, deepest floor, enemies killed, recruits who died, how Ethari died
6. Display run records in Hall of Legends with visual cards
7. Implement The Last Survivor NPC dialogue referencing full legacy history
8. Implement True Ending unlock condition — multiple legacy runs + all lore collected
9. Implement photo mode — auto-capture run summary screenshot, save to device gallery
10. Create `scenes/ui/RunJournal.tscn` — visual history of all run photos and stats

**Relevant Context:**
- `scripts/core/progression_manager.gd`
- `scripts/core/save_manager.gd`
- `scenes/base/HallOfLegends.tscn`

---

### Sub-Task 19 — New Game Plus

**Status:** `[x] done`

**Intent:**
Build New Game+ — harder difficulty tiers after Malachar's defeat, new exclusive loot, more lore revealed, expanded story, and the post-Malachar threat hook.

**Expected Outcomes:**
- New Game+ unlocks after defeating Malachar
- NG+ enemies and bosses scaled to a new difficulty tier (faster, more HP, new attack patterns)
- Exclusive NG+ loot — weapons and artifacts not available in base game
- More lore revealed: Malachar's true nature, the Ancient force, the king's full secret
- Expanded story chapter: post-Malachar, the seal weakens, the Ancient stirs
- NG+ can be repeated (NG++, NG+++ etc.) with further scaling
- Each NG+ tier has a visual indicator in the HUD

**Todo List:**
1. Implement NG+ unlock trigger — fires after Malachar is defeated
2. Implement NG+ difficulty scaling — enemy HP/damage multiplier per NG+ tier
3. Implement NG+ exclusive loot pool — new weapons and artifacts added to drop tables
4. Implement NG+ lore unlock — new story fragments available after NG+ begins
5. Create expanded story chapter scenes for post-Malachar narrative
6. Implement NG+ tier counter and HUD indicator
7. Add NG+ tier to run records in Hall of Legends

**Relevant Context:**
- `scripts/core/game_manager.gd`
- `scripts/core/progression_manager.gd`

---

### Sub-Task 20 — Daily Dungeon & Global Leaderboard

**Status:** `[x] done`

**Intent:**
Build the daily dungeon mode — a fixed daily seed dungeon with a global online leaderboard and personal best tracking.

**Expected Outcomes:**
- Daily Dungeon uses a fixed seed generated from the current date (same for all players worldwide)
- Daily Dungeon available once per day per account
- Score based on: deepest floor, enemies killed, time taken, boss kills
- Global leaderboard shows top 100 players with score and class used
- Personal best tracked and displayed
- Daily Dungeon requires internet connection; rest of game fully playable offline
- Daily Dungeon completion gives a special daily reward (exclusive cosmetic or rare artifact)

**Todo List:**
1. Write `scripts/core/daily_dungeon.gd` — generate daily seed from date, track completion
2. Implement daily dungeon mode in DungeonGenerator — seeded random generation
3. Implement score calculation system
4. Implement global leaderboard backend (Godot HTTP requests to a simple REST API or a service like LootLocker/PlayFab)
5. Create leaderboard UI — scrollable top 100, personal rank highlighted
6. Implement daily reward on completion
7. Implement offline guard — daily dungeon only accessible with internet connection
8. Add Daily Dungeon button to Main Menu

**Relevant Context:**
- `scripts/core/daily_dungeon.gd`
- `scripts/dungeon/dungeon_generator.gd`

---

### Sub-Task 21 — Friend System & Async Multiplayer

**Status:** `[x] done`

**Intent:**
Build the in-game friend system and asynchronous multiplayer features — async co-op messages, ghost runs visible only to friends, and co-op base visits.

**Expected Outcomes:**
- Players have a unique in-game friend code
- Friends can be added by code
- Friend list visible in main menu and base
- Async co-op: leave a message or helpful item at a location in your dungeon — friends can find it in their own run
- Ghost runs: your ghost (replay of movements) can appear in a friend's dungeon as a shadow showing how far you got
- Co-op base visits: invite a friend to visit your base, see recruits, Hall of Legends, Weapon Cabinet
- All async features require internet connection

**Todo List:**
1. Write `scripts/core/friend_system.gd` — friend code generation, add/remove friends, friend list persistence
2. Implement async message/item placement — player places message or item, saved to backend, appears in friend's run
3. Implement ghost run recording — record player movement path per run, save to backend
4. Implement ghost run playback — load friend's ghost run data, replay as a shadow entity in dungeon
5. Implement co-op base visit — load friend's base state as a read-only visit scene
6. Create Friend List UI accessible from Main Menu and Base
7. Create async message placement UI in dungeon (hold on location, write message)

**Relevant Context:**
- `scripts/core/friend_system.gd`
- Backend service required (LootLocker, PlayFab, or custom REST API)

---

### Sub-Task 22 — Co-op Multiplayer (Architecture)

**Status:** `[x] done`

**Intent:**
Architect and implement co-op multiplayer — local and online, player 2 can play as a recruit or a second Ethari (with debuff), using Godot 4 MultiplayerAPI.

**Expected Outcomes:**
- Co-op works both locally and online
- Player 2 choice: play as an active recruit OR a second Ethari (both players get permanent -25% debuff for that run)
- Dungeon rooms sized to accommodate 2 players
- All game systems (loot, coins, enemies) aware of multiplayer state
- Network transport: Godot 4 ENet (peer-to-peer for friends)
- Recruit party slots can be used as co-op player slots

**Todo List:**
1. Refactor all player input through EventBus signals (prerequisite for multiplayer)
2. Design Ethari.tscn as a generic "player entity" — second instance spawnable for co-op
3. Implement Godot 4 MultiplayerAPI with ENet transport
4. Implement host/join lobby system
5. Implement player 2 class/role selection — recruit or second Ethari
6. Implement -25% debuff when both players are Ethari instances
7. Synchronise dungeon state, enemy positions, loot across network
8. Implement local co-op (split-screen or shared screen) option
9. Test co-op end-to-end with two devices

**Relevant Context:**
- Godot 4 MultiplayerAPI, ENet transport
- `scripts/core/game_manager.gd`
- `scripts/core/event_bus.gd`

---

### Sub-Task 23 — Achievements, Challenges & Seasonal Events

**Status:** `[x] done`

**Intent:**
Build the achievement system, challenge run modes, seasonal events, and endless mode for maximum replayability.

**Expected Outcomes:**
- Achievement system: milestones (first boss kill, 1000 enemies killed, floor 100 reached, all classes mastered, etc.)
- Challenge runs: Ironman (one life), Pacifist (non-lethal only), Speedrun (timer displayed), custom self-imposed modifiers
- Seasonal events: limited time themed dungeons using system date (frost biome in winter, bloom in spring, haunted in autumn)
- Seasonal events have unique enemies, exclusive cosmetic rewards, special boss
- Endless mode unlocks after New Game+ — no story, pure survival, leaderboard score
- Floor 666 always accessible regardless of mode

**Todo List:**
1. Define achievement list (50+ achievements) with unlock conditions and rewards
2. Implement achievement tracking in `progression_manager.gd`
3. Create achievement notification UI — pop-up on unlock
4. Implement challenge run mode selection UI
5. Implement Ironman mode — permadeath for Ethari (no revive crystals), run ends on death
6. Implement Speedrun mode — timer overlay, final time recorded in run stats
7. Implement seasonal event detection using system date
8. Create seasonal dungeon biome scenes and enemy variants
9. Implement endless mode — remove story gates, pure floor progression with leaderboard

**Relevant Context:**
- `scripts/core/progression_manager.gd`
- `scripts/dungeon/biome_manager.gd`

---

### Sub-Task 24 — Cosmetics, Settings & Polish

**Status:** `[x] done`

**Intent:**
Build the settings system, accessibility options, cosmetic systems, photo mode, auto-loot, and all quality-of-life features.

**Expected Outcomes:**
- Settings: music volume, SFX volume, screen shake toggle, portrait/landscape toggle, auto-loot toggle, colourblind mode, larger UI option, reduced screen shake
- Cosmetic skins for Ethari and recruits (visual only, no gameplay advantage)
- Base themes: alternate visual themes (Elven Ruins, Volcanic Forge, Crystal Sanctum)
- Dungeon themes: alternate tileset skins
- Emotes for Ethari and recruits (useful in multiplayer)
- Premium cosmetics only — never paywalled gameplay
- Auto-loot toggle — automatically collects coins and common items
- Quick swap — double tap weapon in inventory to equip instantly
- Run history — detailed log of every run
- Tutorial dungeon — guided first run teaching mechanics without being intrusive
- Context-sensitive tips system — first time encountering a mechanic
- Photo mode — pause, apply filter, take screenshot saved to device gallery
- Portrait and landscape mode both fully supported

**Todo List:**
1. Create `scenes/ui/Settings.tscn` — all toggles and sliders
2. Implement audio bus system — music and SFX on separate buses with volume control
3. Implement screen shake toggle — all camera shake respects this setting
4. Implement colourblind mode — elemental indicators use shapes in addition to colours
5. Implement larger UI option — scales all HUD elements up
6. Implement auto-loot toggle — player preference saved
7. Implement quick swap — double-tap gesture on inventory weapon
8. Create run history log — save detailed stats per run, display in UI
9. Create tutorial dungeon — special first-run guided level with tooltips
10. Implement context-sensitive tips system
11. Implement photo mode — pause game, apply filter options, save to gallery
12. Implement cosmetic skin system — skin selection in base, applied to sprites
13. Implement base theme selection — alternate tileset loaded for base scene
14. Create emote selection wheel (long press Ethari)

**Relevant Context:**
- `scenes/ui/Settings.tscn`
- Godot AudioBus, AudioStreamPlayer

---

### Sub-Task 25 — Main Menu, Game Flow & Audio

**Status:** `[x] done`

**Intent:**
Wire everything together with the main menu, full game loop state machine, all scene transitions, and complete audio (music + SFX).

**Expected Outcomes:**
- Main menu: Play, Daily Dungeon, Friends, Lore Log, Settings, Quit
- Full game loop state machine: MENU → BASE → CLASS_SELECT → RUN → GAME_OVER → WEAPON_KEEP → BASE
- Smooth fade transitions between all scenes
- Background music per scene: Main Menu theme, Base theme (calm/hopeful), Dungeon theme (intensity scales with floor depth and biome), Boss theme, Town theme, Base Raid theme
- SFX: attack, hit, death, coin pickup, loot pickup, ability cast, boss roar, raid alarm, town raid alarm, level up, recruit death, funeral bells
- Malachar's voice lines delivered as spatial audio from below
- Game over screen shows run stats: floor reached, enemies killed, gold earned, recruits lost
- All music crossfades smoothly on scene change

**Todo List:**
1. Create `scenes/ui/MainMenu.tscn` — title with game logo, all menu buttons
2. Write `scripts/core/game_manager.gd` — full state machine with all states
3. Implement scene transition system — fade out/in via CanvasLayer overlay
4. Create `scenes/ui/GameOver.tscn` — run stats display, Weapon Keep button, Return to Base button
5. Add Settings accessible from main menu and pause menu
6. Implement pause menu — accessible during run, shows settings and quit option
7. Implement background music system — AudioStreamPlayer with track crossfade per scene/biome
8. Implement dynamic dungeon music intensity — scales with floor depth
9. Add SFX bus — all sound effects routed through shared SFX pool
10. Implement Malachar voice line system — triggered by game events, played as distant echo
11. Source or create placeholder audio assets for all required tracks and SFX
12. Test full game loop end-to-end on desktop then iOS simulator

**Relevant Context:**
- `scripts/core/game_manager.gd`
- `scenes/ui/MainMenu.tscn`
- Godot AudioStreamPlayer, AudioBus

---

## Key Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Engine | Godot 4 | Free, excellent 2D, iOS export, active community |
| Perspective | Top-Down 2D | Best for mobile touch, classic dungeon crawler |
| Combat | Real-time action | More engaging on mobile |
| Dungeon | Procedural infinite floors with biomes | High replayability, visual variety |
| Progression | Hybrid roguelite — XP → upgrade points, coins persist | Rewards repeated play without pure frustration |
| Recruit death | Permadeath with escape option and revive crystal | High stakes but fair |
| Friendly fire | Disabled | Better mobile experience, no accidental recruit kills |
| Multiplayer | Architecture supports it — co-op implemented in Sub-Task 22 | Future-proofed without scope creep |
| Save | JSON via FileAccess + cloud save | Simple, extensible, cross-device |
| Classes | 15 at launch + many unlockable | Depth without overwhelming new players |
| Recruit cap | 50 base → 250 max via Altar upgrades | Progression feels rewarding |
| Leaderboard | Global online (friends-only ghost runs) | Community engagement, privacy respected |
| Monetisation | Cosmetics only, never gameplay | Player trust, no pay-to-win |

---

## Multiplayer Architecture Notes
*(Designed now to avoid rewrites later)*

- All player input routed through EventBus signals, never direct function calls
- Ethari.tscn is a generic "player entity" — second instance spawnable for co-op
- GameManager tracks player count (default 1, expandable)
- Dungeon rooms sized to accommodate 2–4 players
- Recruit party slots (up to 3) repurposed as co-op player slots in multiplayer
- Network layer: Godot 4 MultiplayerAPI with ENet transport
- All game state changes emitted as signals, making network synchronisation straightforward

---

## Implementation Order Recommendation

1. Sub-Task 1 — Project Setup
2. Sub-Task 2 — Data Structures
3. Sub-Task 3 — Class System
4. Sub-Task 4 — Ethari (Player)
5. Sub-Task 5 — Touch Controls & HUD
6. Sub-Task 6 — Enemy System
7. Sub-Task 7 — Boss System
8. Sub-Task 8 — Dungeon Generation
9. Sub-Task 9 — Towns
10. Sub-Task 10 — Loot & Crafting
11. Sub-Task 11 — Recruit System
12. Sub-Task 12 — Pet System
13. Sub-Task 13 — The Base
14. Sub-Task 14 — Meta Progression
15. Sub-Task 15 — Currency & Shop
16. Sub-Task 16 — Save System
17. Sub-Task 17 — Lore & Story
18. Sub-Task 18 — Legacy System
19. Sub-Task 19 — New Game Plus
20. Sub-Task 20 — Daily Dungeon & Leaderboard
21. Sub-Task 21 — Friend System & Async Multiplayer
22. Sub-Task 22 — Co-op Multiplayer
23. Sub-Task 23 — Achievements & Seasonal Events
24. Sub-Task 24 — Cosmetics & Polish
25. Sub-Task 25 — Main Menu & Audio
