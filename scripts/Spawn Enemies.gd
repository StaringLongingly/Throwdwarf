extends Node

@export var spawnIntervalVariation: float
@export var spawningBoundaryMin: Vector2
@export var spawningBoundaryMax: Vector2

@export var folder_chances = {
	"common": 0.7,
	"rare": 0.2,
	"legendary": 0.1
}

@export var enemies = {
	"common": [],
	"rare": [],
	"legendary": []
}

@export var time_interval: float = 1.0
@export var min_time_interval: float = 0.2
@export var time_interval_decrease_rate: float = 0.001
@export var time_increase_rate: float = 0.001

@export var base_group_spawn_size_min: int = 3  # Base minimum enemies in a group
@export var base_group_spawn_size_max: int = 7  # Base maximum enemies in a group
@export var group_size_increase_rate: float = 0.05  # Rate at which group size increases over time

@export var min_delay_between_enemies: float = 0.1  # Minimum delay between enemies in a group
@export var max_delay_between_enemies: float = 0.3  # Maximum delay between enemies in a group

var elapsed_time = 0.0
var spawning = false  # A flag to check if a group is currently being spawned

# Function to spawn a group of enemies with delays between each spawn
func spawn_enemy_group() -> void:
	spawning = true  # Set the spawning flag to true
	
	# Calculate the current group size based on elapsed time
	var current_group_spawn_size_min = base_group_spawn_size_min + int(elapsed_time * group_size_increase_rate)
	var current_group_spawn_size_max = base_group_spawn_size_max + int(elapsed_time * group_size_increase_rate)
	var group_size = randi_range(current_group_spawn_size_min, current_group_spawn_size_max)

	for i in range(group_size):
		var selected_folder = choose_folder()

		if selected_folder != "":
			var enemy_path = "res://enemies/" + selected_folder + "/" + enemies[selected_folder][randi_range(0, enemies[selected_folder].size() - 1)] + ".tscn"
			var enemy_scene = load(enemy_path)

			if enemy_scene:
				var enemy_instance = enemy_scene.instantiate()
				add_child(enemy_instance)
				var enemyPosition: Vector2 = get_node("Wall").get_valid_enemy_position()
				enemy_instance.position = enemyPosition 
				print("Spawned enemy from ", selected_folder, ": ", enemy_path)
				print("   Enemy Position X: " + str(enemyPosition.x).left(6), ", Y: " + str(enemyPosition.y).left(6))
		else:
			print("No folder selected, something went wrong.")

		# Add a random delay between enemies
		var delay = randf_range(min_delay_between_enemies, max_delay_between_enemies)
		await get_tree().create_timer(delay).timeout

	spawning = false  # Reset the spawning flag after the group is done

# Function to choose a folder based on the current chances
func choose_folder() -> String:
	var rand_value = randi() / 4294967295.0  # Normalize by dividing by 2^32 - 1
	var cumulative_chance = 0.0

	for folder in folder_chances.keys():
		cumulative_chance += folder_chances[folder]
		if rand_value < cumulative_chance:
			return folder

	return ""

# Function to update chances and spawn rate over time
func update_chances_and_spawn_rate() -> void:
	folder_chances["common"] = max(0.5, folder_chances["common"] - time_increase_rate)
	folder_chances["rare"] = min(0.3, folder_chances["rare"] + time_increase_rate * 0.5)
	folder_chances["legendary"] = min(0.2, folder_chances["legendary"] + time_increase_rate * 0.5)

	var total_chance = 0.0
	for chance in folder_chances.values():
		total_chance += chance

	for folder in folder_chances.keys():
		folder_chances[folder] /= total_chance

	time_interval = max(min_time_interval, time_interval - time_interval_decrease_rate / 100000)
	time_interval += (randf() * 2 - 1) * spawnIntervalVariation

# Main loop for spawning enemies
func _process(delta: float) -> void:
	elapsed_time += delta

	if elapsed_time >= time_interval and not spawning:  # Check if not currently spawning
		await spawn_enemy_group()
		update_chances_and_spawn_rate()

		# Randomize the next interval a bit more to make it less predictable
		elapsed_time = 0.0
		time_interval = time_interval + randf_range(-0.5, 0.5) * time_interval * 0.5
