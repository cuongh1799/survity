# Survity - City Building Game

A city building and resource management game built in Godot 4.x where players must manage city infrastructure against environmental hazards (rain, plague, crime, crimson disasters) while maintaining resources and building a sustainable city.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Game Overview](#game-overview)
3. [Core Systems](#core-systems)
4. [Important Scripts](#important-scripts)
5. [Script Interactions](#script-interactions)
6. [Game Loop & Mechanics](#game-loop--mechanics)

---

## Project Structure

```
survity/
├── scenes/                      # Godot scene files (.tscn)
│   ├── city_building_game.tscn # Main game scene
│   ├── main_menu.tscn          # Menu UI
│   ├── building_scene.tscn     # Various building types
│   ├── base_prop.tscn          # Base building/prop template
│   ├── tree_body_2.tscn        # Tree resource prop
│   ├── rock_scene.tscn         # Rock resource prop
│   ├── world_*.tscn            # World resources (oil, gold, coal, etc.)
│   └── ...
├── scripts/                     # GDScript files (.gd)
│   ├── player_manager.gd       # Player stats, inventory, weather, progress bars
│   ├── player_city.gd          # Player movement with WASD rotation
│   ├── camera_node.gd          # Camera controls, building placement, selection
│   ├── building_recipe.gd      # Building recipe data structure
│   ├── prop_spawner.gd         # Spawns random world resources
│   ├── click_indicator.gd      # Visual feedback for movement
│   ├── main_menu.gd            # Menu logic
│   └── ...
├── assets/                      # Game assets
│   ├── font/                   # UI fonts
│   ├── icons/                  # UI icons
│   ├── sound/                  # Audio files
│   └── ui/                     # UI textures
├── glb/                         # 3D models (.glb files)
│   ├── tree_oak.glb
│   ├── stone_tallA.glb
│   └── building_*/              # Building models
├── tres/                        # Material definitions
└── project.godot               # Project configuration

```

---

## Game Overview

**Survity** is a survival city-building game where players:

- **Build cities** on a procedurally-generated terrain
- **Manage resources** through harvesting and crafting recipes
- **Monitor progress bars** representing city health threats:
  - **Corrosion** (increases during rain)
  - **Crime** (increases during crimson weather)
  - **Toxicity** (increases during plague)
- **Counter threats** by building specific structures that decrease progress bars
- **Lose** if any progress bar reaches 100%

---

## Core Systems

### 1. **Player Management System** (`player_manager.gd`)
Centralized manager for all game state:
- **Inventory**: Tracks 17 resource types (wood, stone, food, oil, gold, etc.)
- **Budget**: Currency for building construction
- **City Attraction**: Reputation/appeal metric
- **Weather Cycle**: 4-weather system (clear, rain, plague, crimson)
- **Day Timer**: Tracks in-game time with configurable day length
- **Progress Bars**: Three threat levels that increase/decrease based on weather and buildings

### 2. **Player Movement** (`player_city.gd`)
Player character controller with city-wide interaction:
- **WASD Movement**: Direct cardinal direction input (North/South/East/West + diagonals)
- **Player Rotation**: Model rotates to face walking direction
- **Harvesting**: Press F to harvest nearby resources (trees, rocks, etc.)
- **Floor Snapping**: Character stays aligned to the grass floor via raycasting

### 3. **Camera & Building System** (`camera_node.gd`)
Isometric-style camera with grid-based building placement:
- **Zoom**: Scroll wheel to zoom in/out
- **Pan**: Right-click drag to pan camera
- **Click to Build**: Left-click on grid to place buildings
- **Drag Selection**: Click-drag to select multiple props
- **Grid Snapping**: Buildings snap to a configurable grid (default 5.0 units)
- **Collision Detection**: Prevents overlapping buildings

### 4. **Weather System** (`player_manager.gd`)
Dynamic environmental hazard system:
- **Weather Types**: Clear, Rain, Plague, Crimson
- **Daily Rotation**: Weather changes each in-game day
- **Visual Effects**: Fog, lighting, and crow spawning based on weather
- **Progress Bar Impact**: Each weather type increases a specific threat bar

### 5. **Prop/Building System** (`base_prop.gd`)
All placeable objects inherit from the `Prop` class:
- **Cost**: Placement cost in currency
- **Effects**: Crime/toxicity/corrosion reduction
- **Harvesting**: Natural resources (trees, rocks) can be harvested for materials
- **Drop Types**: Resources (wood, stone, etc.) or building materials (bricks, glass)

### 6. **UI System**
- **Inventory UI**: Displays current resource quantities
- **Budget Display**: Shows remaining currency
- **Progress Bars**: Visual representation of corrosion, crime, toxicity (0-100%)
- **Menu**: Main menu with options and game manual

---

## Important Scripts

### `player_manager.gd` (Singleton/Global)
**Purpose**: Centralized game state manager

**Key Functions**:
- `_ready()`: Initialize weather and day cycle
- `_process(delta)`: Update time, weather bars, building effects
- `_update_weather_bars(delta)`: Increase/decrease progress bars based on weather
- `_apply_building_effects()`: Calculate and apply building defensive effects
- `_trigger_game_over()`: Show game over screen and pause game
- `add_to_inventory(key, amount)`: Add resources to player inventory
- `consume_ingredients(costs)`: Deduct recipe costs from inventory

**Key Variables**:
```gdscript
var inventory: Dictionary        # Resource quantities
var budget: int = 100            # Currency
var current_day: int = 1         # In-game day counter
var current_weather: String      # Current weather type
```

---

### `player_city.gd` (Player Character)
**Purpose**: Player movement, rotation, and harvesting

**Key Functions**:
- `_physics_process(delta)`: Handle WASD input and movement
- `_rotate_player_to_direction(direction)`: Rotate character to face 8 directions
- `_correct_vertical_to_floor()`: Keep player on terrain via raycasting
- `_try_harvest_nearest()`: Harvest nearby resources when F is pressed

**Input Mapping**:
- W: Move North, A: Move West, S: Move South, D: Move East
- F: Harvest nearest resource within range
- SHIFT: Sprint (2x speed)

---

### `camera_node.gd` (Camera & Building Placement)
**Purpose**: Isometric camera control and grid-based building system

**Key Functions**:
- `_unhandled_input(event)`: Handle zoom, pan, click, and drag
- `spawn_object_at_mouse(mouse_pos)`: Place building on grid with collision check
- `is_grid_slot_occupied(target_pos)`: Verify no overlapping buildings
- `delete_selected_props()`: Remove selected buildings (refunds cost)
- `highlight_items_in_rect(rect)`: Visual selection feedback

**Configuration**:
```gdscript
@export var grid_size: float = 5.0           # Building placement grid
@export var test_spawn: PackedScene          # Building to place
@export var player_budget: float = 1000.0    # Starting currency
```

---

### `base_prop.gd` (Building/Prop Base Class)
**Purpose**: Base class for all placeable objects (buildings, trees, rocks)

**Key Properties**:
```gdscript
@export var cost: float              # Placement/removal cost
@export var profitPerSecond: float   # Income per second
@export var attraction: float        # City appeal bonus
@export var crime_decrease: float    # Crime reduction per second
@export var toxic_decrease: float    # Toxicity reduction per second
@export var corrosion_decrease: float # Corrosion reduction per second
@export var drop_type: String        # Resource type when harvested
@export var drop_amount: int         # Quantity when harvested
```

**Key Functions**:
- `harvest()`: Collect resource and add to player inventory
- `set_highlight(active: bool)`: Show/hide selection outline

---

### `building_recipe.gd` (Data Structure)
**Purpose**: Define building blueprints with costs and results

**Properties**:
```gdscript
@export var id: String               # Unique identifier
@export var display_name: String     # UI name
@export var icon: Texture2D          # UI icon
@export var result_scene: PackedScene # Building to spawn
@export var ingredients: Dictionary  # Required materials
```

---

### `prop_spawner.gd` (World Generation)
**Purpose**: Populate the world with random trees and rocks

**Key Functions**:
- `spawn_props()`: Generate random world resources
- `_input(event)`: Press R to respawn all world props

---

### `main_menu.gd` (Menu Navigation)
**Purpose**: Handle main menu UI and transitions

**Key Functions**:
- `_on_play_button_pressed()`: Start game
- `_on_option_button_pressed()`: Show settings
- `_on_quit_button_pressed()`: Exit game

---

## Script Interactions

### Game Flow Diagram

```
Main Game Scene (city_building_game.tscn)
│
├─► CameraNode (camera_node.gd)
│   └─► Handles: Building placement, selection, deletion
│       └─► Communicates with: PlayerManager (budget)
│
├─► PlayerCity (player_city.gd)
│   └─► Handles: Movement, rotation, harvesting
│       └─► Communicates with: PlayerManager (inventory, harvest events)
│
├─► PlayerManager (player_manager.gd) [Global/Autoload]
│   └─► Manages: Inventory, budget, weather, progress bars
│       └─► Updates: UI elements, weather effects, game state
│
└─► Props/Buildings (base_prop.gd + derived classes)
    └─► Placed by: CameraNode (spawn_object_at_mouse)
        └─► Harvested by: PlayerCity (harvest functionality)
        └─► Counted by: PlayerManager (building effects calculation)

```

### Key Interactions

1. **Building Placement**
   - CameraNode detects left-click
   - Raycasts to ground to find position
   - Snaps to grid and checks for collisions
   - Deducts cost from PlayerManager.budget
   - Spawns Prop into scene

2. **Resource Harvesting**
   - PlayerCity detects F key press
   - Finds nearest Prop within range
   - Calls Prop.harvest()
   - Prop adds resources to PlayerManager.inventory
   - Prop is removed from scene

3. **Weather & Progress Bars**
   - PlayerManager tracks current weather
   - `_update_weather_bars()` increases threat based on weather type
   - `_apply_building_effects()` calculates total reduction from placed buildings
   - If any bar reaches 100%, calls `_trigger_game_over()`

4. **Building Effects**
   - Props have `crime_decrease`, `toxic_decrease`, `corrosion_decrease` values
   - PlayerManager queries all Props in the scene every second
   - Sums up effects and applies to progress bars
   - Creates feedback loop: more buildings = more protection

---

## Game Loop & Mechanics

### Main Update Loop

```
_process(delta) in PlayerManager:
1. Update day timer
2. Update weather bars (increase threat based on weather)
3. Every 1 second: Apply building effects (decrease threat)
4. If plague weather: Spawn plague crows
5. Check if any progress bar ≥ 100% → Game Over

_physics_process(delta) in PlayerCity:
1. Read WASD input
2. Move character
3. Rotate to face input direction
4. Snap to floor via raycast
5. Update harvest prompt visibility

_unhandled_input(event) in CameraNode:
1. Mouse scroll → Zoom camera
2. Right-click drag → Pan camera
3. Left-click → Build or select props
4. Left-click drag → Multi-select props
5. Delete key → Remove selected buildings
```

### Game Over Condition

The game ends when **any** progress bar reaches 100%:

```gdscript
if (corrosionBar >= 100 || crimeBar >= 100 || toxicBar >= 100):
    _trigger_game_over()
```

**Result:**
- "You Lost" panel becomes visible
- Game tree is paused (all input stops, physics stops)
- Player cannot interact

### Win Condition

Currently **no win condition**. The game is continuous survival mode.

---

## Weather System Details

### Weather Types & Effects

| Weather | Threat Bar | Fog Color | Increase Rate | Decrease with |
|---------|-----------|-----------|---------------|----------------|
| Clear | None | None | -0.1x/sec (recovery) | Time |
| Rain | Corrosion | Gray | 1.0/sec | Water management buildings |
| Plague | Toxicity | Green | 1.0/sec | Pollution control buildings |
| Crimson | Crime | Red | 1.0/sec | Police/security buildings |

### Weather Rotation

- At the start and each new day, a random weather is selected for next day
- Weather changes at midnight (after `SECONDS_PER_DAY` duration)
- Default `SECONDS_PER_DAY = 60` seconds (configurable)

---

## Building Strategy

### Effective Building Placement

1. **React to Weather**: Build counter-buildings when weather threatens a specific bar
2. **Harvest First**: Gather trees/rocks to fund better buildings
3. **Early Defense**: Place defensive buildings early to prevent bars from rising too quickly
4. **Efficiency**: Higher-tier buildings provide more effect reduction
5. **Spread**: Distribute buildings across the map for visual and mechanical variety

### Example Strategy

```
Day 1 (Clear): Harvest resources, build foundation
Day 2 (Rain): Build water/corrosion defense
Day 3 (Plague): Build pollution/health defense
Day 4 (Crimson): Build police/safety defense
```

---

## Configuration & Customization

### Player Manager Constants

```gdscript
const SECONDS_PER_DAY: float = 60.0  # Adjust day length
const WEATHERS = ["clear", "rain", "plague", "crimson"]  # Weather types
const CROW_SCENE = preload("res://scenes/crow.tscn")  # Plague crow
```

### Camera Settings

```gdscript
@export var grid_size: float = 5.0              # Building grid
@export var pan_speed: float = 0.05             # Camera pan sensitivity
@export var zoom_speed: float = 2.0             # Zoom sensitivity
@export var min_zoom: float = 5.0               # Max zoom in
@export var max_zoom: float = 300.0             # Max zoom out
```

### Player Movement

```gdscript
const MOVE_SPEED := 11.0       # Base movement speed
const HARVEST_RANGE := 6.0     # Harvest distance in units
const PROMPT_SHOW_RANGE := 6.0 # Interaction prompt distance
```

---

## Common Issues & Solutions

### Buildings Overlapping
- Reduce `grid_size` in CameraNode for finer control
- Check `is_grid_slot_occupied()` logic in camera_node.gd

### Progress Bars Rising Too Fast
- Increase building effects by adjusting Prop export values
- Place more defensive buildings
- Increase `SECONDS_PER_DAY` for longer days

### Player Not Moving
- Check WASD input mapping in project settings
- Verify NavigationMesh or movement physics layer is configured

---

## Future Enhancement Ideas

- [ ] Victory condition (reach specific city population/wealth)
- [ ] Multiple difficulty levels
- [ ] Building upgrading system
- [ ] Multiplayer mode
- [ ] Save/load game state
- [ ] More weather types and disasters
- [ ] NPC citizens and population management
- [ ] Economy system with trading

---

## Credits & Notes

- Built with **Godot 4.x** (GDScript)
- 3D models from GLB files
- Procedural weather and threat system
- Grid-based building placement inspired by Islanders/Endfield

