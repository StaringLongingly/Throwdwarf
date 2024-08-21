extends Node

@export var spawnIntervalVariation: float
@export var spawningBoundaryMin: Vector2
@export var spawningBoundaryMax: Vector2

# Exported Dictionary containing folders and their respective base chances
@export var folder_chances = {
	"common": 0.7,   # 70% chance initially
	"rare": 0.2,     # 20% chance initially
	"legendary": 0.1 # 10% chance initially
}

# Exported Dictionary containing enemy paths for each folder
@export var enemies = {
	"common": [],
	"rare" : [],
	"legendary": []
}

# Exported parameters for time-related control
@export var time_interval: float = 1.0        # Initial time between spawns in seconds
@export var min_time_interval: float = 0.2    # Minimum time interval between spawns
@export var time_interval_decrease_rate: float = 0.001 # Rate at which time_interval decreases
@export var time_increase_rate: float = 0.001 # Rate at which higher-tier chances increase

# Time tracking variable (not exported, as it's not meant to be set in the editor)
var elapsed_time = 0.0

# Function to spawn an enemy
func spawn_enemy():
	var selected_folder = choose_folder()

	if selected_folder != "":
		var enemy_path = "res://enemies/" + selected_folder + "/" + enemies[selected_folder][randi_range(0, enemies[selected_folder].size() - 1)] + ".tscn"
		var enemy_scene = load(enemy_path)

		if enemy_scene:
			var enemy_instance = enemy_scene.instantiate()
			add_child(enemy_instance)
			var enemyPosition = lerp(spawningBoundaryMin, spawningBoundaryMax, randf() * 2 - 1)
			print("Spawned enemy from ", selected_folder, ": ", enemy_path)
			print("   Enemy Position X: "  + str(enemyPosition.x).left(6), ", Y: " + str(enemyPosition.y).left(6))
			print("    Time Interval: " + str(time_interval))
		# else:
		# print("Failed to load enemy scene from path: ", enemy_path)
	else:
		print("No folder selected, something went wrong.")

# Function to choose a folder based on the current chances
func choose_folder() -> String:
	var rand_value = randi() / 4294967295.0 # Normalize by dividing by 2^32 - 1
	var cumulative_chance = 0.0

	for folder in folder_chances.keys():
		cumulative_chance += folder_chances[folder]
		if rand_value < cumulative_chance:
			return folder

	return ""  # Should not reach here if chances are correctly normalized

# Function to update chances and spawn rate over time
func update_chances_and_spawn_rate():
	# Update folder chances over time
	folder_chances["common"] = max(0.5, folder_chances["common"] - time_increase_rate)
	folder_chances["rare"] = min(0.3, folder_chances["rare"] + time_increase_rate * 0.5)
	folder_chances["legendary"] = min(0.2, folder_chances["legendary"] + time_increase_rate * 0.5)

	# Normalize chances so they sum to 1
	var total_chance = 0.0
	for chance in folder_chances.values():
		total_chance += chance

	for folder in folder_chances.keys():
		folder_chances[folder] /= total_chance

	# Decrease time interval to spawn enemies more frequently
	time_interval = max(min_time_interval, time_interval - time_interval_decrease_rate / 100000)
	time_interval += (randf() * 2 - 1) * spawnIntervalVariation

# Main loop for spawning enemies
func _process(delta):
	elapsed_time += delta

	if elapsed_time >= time_interval:
		spawn_enemy()
		update_chances_and_spawn_rate()
		elapsed_time = 0.0  # Reset the timer
