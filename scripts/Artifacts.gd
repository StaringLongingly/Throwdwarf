extends Node

signal displayArtifactInfo(artifact: Dictionary, rarity: String, isNew: bool, id: String)

@export var searchLabel: RichTextLabel
@export var itemCountLabel: RichTextLabel
var HUD: Node
@export var hueSpeed: float = 0.2
@export var cheatMode: bool = false
var latestRarity: String = ""
var latestArtifact: Dictionary = {}
var hue: float = 0.0

@export var common_artifacts: Dictionary = {}
@export var rare_artifacts: Dictionary = {}
@export var legendary_artifacts: Dictionary = {}

var common_inventory: Dictionary = {}    # Dictionary to store common artifacts
var rare_inventory: Dictionary = {}      # Dictionary to store rare artifacts
var legendary_inventory: Dictionary = {} # Dictionary to store legendary artifacts

var typed: String = ""
var searchResults: String = ""
var selectedArtifact: Dictionary = {}
var selectedArtifactRarity: String = ""
var latestSearchedInventory: String = ""

func _process(delta: float) -> void:
	# Item count display
	itemCountLabel.text = "[b][i]"
	itemCountLabel.text += " " + HUD.get_color_string("legendary") + str(count_items_in_inventory(legendary_inventory))
	itemCountLabel.text += " " + HUD.get_color_string("rare") + str(count_items_in_inventory(rare_inventory))
	itemCountLabel.text += " " + HUD.get_color_string("common") + str(count_items_in_inventory(common_inventory))
	
	var common_keyword = HUD.get_color_string("common") + "Q[/color]"
	var rare_keyword = HUD.get_color_string("rare") + "E[/color]"
	var legendary_keyword = HUD.get_color_string("legendary") + "R[/color]"
	
	# Search input handling
	if Input.is_action_just_pressed("Common Inventory"):
		latestSearchedInventory = "common"
		if typed == common_keyword:
			typed = ""
		else:
			typed = common_keyword 
	if Input.is_action_just_pressed("Rare Inventory"):
		latestSearchedInventory = "rare"
		if typed == rare_keyword:
			typed = ""
		else:
			typed = rare_keyword 
	if Input.is_action_just_pressed("Legendary Inventory"):
		latestSearchedInventory = "legendary"
		if typed == legendary_keyword:
			typed = ""
		else:
			typed = legendary_keyword 
	
	var keyword_length = common_keyword.length()
	var typed_substr = typed.substr(0, keyword_length)
	match typed_substr:
		common_keyword:
			searchResults = get_artifact_names_and_ids("common")
		rare_keyword:
			searchResults = get_artifact_names_and_ids("rare")
		legendary_keyword:
			searchResults = get_artifact_names_and_ids("legendary")
	
	if typed.length() < 2 + keyword_length and typed.length() >= keyword_length:
		if Input.is_action_just_pressed("Pressed 1"):
			typed += "1"
		if Input.is_action_just_pressed("Pressed 2"):
			typed += "2"
		if Input.is_action_just_pressed("Pressed 3"):
			typed += "3"
		if Input.is_action_just_pressed("Pressed 4"):
			typed += "4"
		if Input.is_action_just_pressed("Pressed 5"):
			typed += "5"
	elif typed.length() == 2 + keyword_length:
		var colorStringToRemove = HUD.get_color_string(latestSearchedInventory)
		var typedClean = typed.replace(colorStringToRemove, "")
		typedClean = typedClean.replace("[/color]", "")
		var find_result = find_artifact_by_id(typedClean)
		var foundArtifact = find_result[0]
		if foundArtifact != {}: 
			if selectedArtifact == foundArtifact:
				selectedArtifact = {}
			else:
				selectedArtifact = foundArtifact
				selectedArtifactRarity = find_result[1]
		typed = ""
	
	hue += hueSpeed * delta
	if hue >= 1.0:
		hue -= 1.0
	
	var colorStringToRemove = HUD.get_color_string(latestSearchedInventory)
	var typedClean = typed.replace(colorStringToRemove, "")
	typedClean = typedClean.replace("[/color]", "")
	var filteredLines = filter_lines(searchResults, typedClean)
	searchLabel.text = "Search with ID: [i]" + typed + "[/i]" + "\n"
	if filteredLines != "":
		searchLabel.text += filteredLines
	else:
		if typed == "":
			searchLabel.text += "[i] Press " + HUD.get_color_string("common") + "Q[/color], " + HUD.get_color_string("rare") + "E[/color], or " + HUD.get_color_string("legendary") + "R[/color] to search the matching inventory\n" 
			if selectedArtifact != {}:
				if "name" in selectedArtifact:
					searchLabel.text += " Selected Artifact: " + HUD.get_color_string(selectedArtifactRarity) + str(selectedArtifact["name"]) + "[/color], " + str(selectedArtifact["count"]) + " use"
					if selectedArtifact["count"] > 1:
						searchLabel.text += "s"
					searchLabel.text += " remaining."
		else:
			searchLabel.text += "[i] No Artifacts found in " + HUD.get_color_string(latestSearchedInventory) + latestSearchedInventory + " inventory[/color]!"
	
	# Artifact usage
	if Input.is_action_just_pressed("Fire Artifact") and selectedArtifact != {}:
		var artifactScene = load("res://artifacts/scenes/" + selectedArtifact["name"] + ".tscn")
		var spawnedArtifact = artifactScene.instantiate()
		get_node("../Player/Drill & Colliders").add_child(spawnedArtifact) 
		if selectedArtifact["count"] == 1:
			remove_artifact_from_inventory(selectedArtifact["name"], selectedArtifactRarity)
			selectedArtifact = {}
		else:
			selectedArtifact["count"] -= 1

func _ready() -> void:
	selectedArtifact = {}
	HUD = get_node("/root/Node2D/HUD")
	give_new_artifact("legendary")
	if cheatMode:
		for i in range(100):
			give_new_artifact()

func print_artifact_info(artifact: Dictionary):
	print("Selected Artifact: %s" % artifact["name"])
	print("Extra HP: %d" % artifact["extra_hp"])
	print("Sell Value: %d" % artifact["sell_value"])
	print("Description: %s" % artifact["description"])

func select_random_artifact(rarity: String) -> Dictionary:
	if rarity == "random":
		rarity = randomize_rarity()
	latestRarity = rarity
	
	match rarity:
		"common":
			var artifact_names = common_artifacts.keys()
			var artifact_name = artifact_names[randi() % artifact_names.size()]
			var artifact_data = common_artifacts[artifact_name]
			return {
				"name": artifact_name,
				"id": artifact_data["id"],
				"extra_hp": artifact_data["extra_hp"],
				"sell_value": artifact_data["sell_value"],
				"description": artifact_data["description"],
				"rarity": "common"
			}
		"rare":
			var artifact_names = rare_artifacts.keys()
			var artifact_name = artifact_names[randi() % rare_artifacts.size()]
			var artifact_data = rare_artifacts[artifact_name]
			return {
				"name": artifact_name,
				"id": artifact_data["id"],
				"extra_hp": artifact_data["extra_hp"],
				"sell_value": artifact_data["sell_value"],
				"description": artifact_data["description"],
				"rarity": "rare"
			}
		"legendary":
			var artifact_names = legendary_artifacts.keys()
			var artifact_name = artifact_names[randi() % legendary_artifacts.size()]
			var artifact_data = legendary_artifacts[artifact_name]
			return {
				"name": artifact_name,
				"id": artifact_data["id"],
				"extra_hp": artifact_data["extra_hp"],
				"sell_value": artifact_data["sell_value"],
				"description": artifact_data["description"],
				"rarity": "legendary"
			}
		_:
			return {"name": "Unknown", "extra_hp": 0, "sell_value": 0, "description": "No description available.", "rarity": "unknown"}

func randomize_rarity() -> String:
	var roll = randi() % 100
	if roll < 70:
		return "common"
	elif roll < 95:
		return "rare"
	else:
		return "legendary"

func add_artifact_to_inventory(artifact: Dictionary, rarity: String) -> void:
	match rarity:
		"common":
			if artifact["name"] in common_inventory:
				common_inventory[artifact["name"]]["count"] += 1
			else:
				common_inventory[artifact["name"]] = artifact
				common_inventory[artifact["name"]]["count"] = 1
		"rare":
			if artifact["name"] in rare_inventory:
				rare_inventory[artifact["name"]]["count"] += 1
			else:
				rare_inventory[artifact["name"]] = artifact
				rare_inventory[artifact["name"]]["count"] = 1
		"legendary":
			if artifact["name"] in legendary_inventory:
				legendary_inventory[artifact["name"]]["count"] += 1
			else:
				legendary_inventory[artifact["name"]] = artifact
				legendary_inventory[artifact["name"]]["count"] = 1
		_:
			print("Unknown rarity: %s" % rarity)
			return

func artifact_exists(artifact_name: String, rarity: String) -> bool:
	match rarity:
		"common":
			return artifact_name in common_inventory
		"rare":
			return artifact_name in rare_inventory
		"legendary":
			return artifact_name in legendary_inventory
		_:
			print("Unknown rarity: %s" % rarity)
			return false

func count_items_in_inventory(inventory: Dictionary) -> int:
	var total_count = 0
	for artifact in inventory.values():
		total_count += artifact["count"]
	return total_count

func give_new_artifact(rarityOverride: String = "random") -> void:
	var new_artifact = select_random_artifact(rarityOverride)
	var is_artifact_new = not artifact_exists(new_artifact["name"], new_artifact["rarity"])
	add_artifact_to_inventory(new_artifact, new_artifact["rarity"])
	latestArtifact = new_artifact
	displayArtifactInfo.emit(new_artifact, new_artifact["rarity"], is_artifact_new, new_artifact["id"])

func get_artifact_names_and_ids(rarity: String) -> String:
	var result = ""
	var inventory_values: Array
	
	match rarity:
		"common":
			inventory_values = common_inventory.values()
		"rare":
			inventory_values = rare_inventory.values()
		"legendary":
			inventory_values = legendary_inventory.values()
		_:
			print("Unknown rarity: %s" % rarity)
			return ""
	
	var result_rarity = "[u][b]" + HUD.get_color_string(rarity)
	for artifact in inventory_values:
		var count_string = ""
		var selected_string = ""
		if artifact["count"] > 1:
			count_string = " x" + str(artifact["count"])
		if artifact == selectedArtifact:
			var hsv_color = Color.from_hsv(hue, 1.0, 1.0)
			selected_string += "[color=#" + color_to_hex(hsv_color) + "] Selected![/color]"
		result += result_rarity + artifact["name"] + "[/color][/b][/u]" + count_string + " (ID:" + artifact["id"] + ")" + " [color=#f2ee15]Total DE: " + str(artifact["sell_value"] * artifact["count"]) + "[/color]" +  selected_string + "\n"
	
	return result.strip_edges()

func filter_lines(input_string: String, keyword: String) -> String:
	var lines = input_string.split("\n")
	var result: Array = []
	
	for line in lines:
		if keyword in line:
			result.append(line)
	
	return "\n".join(result)

func color_to_hex(color: Color) -> String:
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)
	return "%02X%02X%02X" % [r, g, b]

func find_artifact_by_id(id: String) -> Array:
	for artifact in common_inventory.values():
		if artifact["id"] == id:
			return [artifact, "common"]
	
	for artifact in rare_inventory.values():
		if artifact["id"] == id:
			return [artifact, "rare"]
	
	for artifact in legendary_inventory.values():
		if artifact["id"] == id:
			return [artifact, "legendary"]
	
	return [{}, ""]

func remove_artifact_from_inventory(artifact_name: String, rarity: String = "any") -> bool:
	var correct_inventory: Dictionary = {}
	var artifact: Dictionary = {}
	
	if rarity == "any":
		for inventory in [common_inventory, rare_inventory, legendary_inventory]:
			if artifact_name in inventory:
				artifact = inventory[artifact_name]
				correct_inventory = inventory
				break
	else:
		match rarity:
			"common":
				correct_inventory = common_inventory
			"rare":
				correct_inventory = rare_inventory
			"legendary":
				correct_inventory = legendary_inventory
			_:
				print("Unknown rarity: %s" % rarity)
				return false
		if artifact_name in correct_inventory:
			artifact = correct_inventory[artifact_name]
	
	if artifact == {}:
		printerr("Did not find artifact!")
		return false
	
	if artifact["count"] > 1:
		artifact["count"] -= 1
		return false
	else:
		print("Erased artifact: " + str(artifact))
		if artifact == selectedArtifact:
			selectedArtifact = {}
		correct_inventory.erase(artifact["name"])
		return true

func calculate_total_sell_value() -> int:
	var total_sell_value = 0
	
	for artifact in common_inventory.values():
		total_sell_value += artifact["sell_value"] * artifact["count"]
	
	for artifact in rare_inventory.values():
		total_sell_value += artifact["sell_value"] * artifact["count"]
	
	for artifact in legendary_inventory.values():
		total_sell_value += artifact["sell_value"] * artifact["count"]
	
	return total_sell_value

func remove_least_valuables(amount: int) -> bool:
	var valuables = get_least_valuables(amount)
	var number_of_least_valuables = 0

	# Calculate the total count of least valuables
	for valuable in valuables.values():
		number_of_least_valuables += valuable["count"]

	# If there are not enough valuables to remove, return false
	if number_of_least_valuables < amount:
		return false

	var top: int = 0
	var artifact_names = valuables.keys()
	if artifact_names.size() == 0:
		return false  # No artifacts to remove

	var artifact_name: String = artifact_names[top]

	# Attempt to remove 'amount' number of least valuable artifacts
	for i in range(amount):
		if remove_artifact_from_inventory(artifact_name, valuables[artifact_name]["rarity"]):
			top += 1
			# If there are more artifacts in the list, move to the next one
			if top < artifact_names.size():
				artifact_name = artifact_names[top]
			else:
				break  # No more artifacts to remove

	return true

func get_least_valuables(amount: int = 1) -> Dictionary:
	var result: Dictionary = {}
	for i in range(amount):
		var least_valuable = get_least_valuable(result)
		if least_valuable == {}:
			break
		result[least_valuable["name"]] = least_valuable
	return result

func get_least_valuable(exclude: Dictionary = {}) -> Dictionary:
	var min_sell_artifact: Dictionary = {}
	var min_sell_value: float = INF  # Use INF for initial comparison
	for inventory in [common_inventory, rare_inventory, legendary_inventory]:
		for artifact in inventory.values():
			if artifact["sell_value"] < min_sell_value and not artifact["name"] in exclude:
				min_sell_artifact = artifact
				min_sell_value = artifact["sell_value"]
	return min_sell_artifact
