extends Node

signal displayArtifactInfo(artifact: Dictionary, rarity: String, isNew: bool, id: String)

@export var searchLabel: RichTextLabel
@export var itemCountLabel: RichTextLabel
var HUD
@export var hueSpeed = 0.2
@export var cheatMode = false
var latestRarity: String
var latestArtifact: Dictionary
var hue = 0

@export var common_artifacts = {}
@export var rare_artifacts = {}
@export var legendary_artifacts = {}

var common_inventory = {}  # Dictionary to store common artifacts
var rare_inventory = {}    # Dictionary to store rare artifacts
var legendary_inventory = {}  # Dictionary to store legendary artifacts

var typed: String = ""
var searchResults: String = ""
var selectedArtifact: Dictionary = {}
var selectedArtifactRarity: String
var latestSearchedInventory: String

func _process(delta: float) -> void:
	#itemcount
	itemCountLabel.text = "[b][i]"
	itemCountLabel.text += " " + HUD.get_color_string("legendary") + str(count_items_in_inventory(legendary_inventory))
	itemCountLabel.text += " " + HUD.get_color_string("rare") + str(count_items_in_inventory(rare_inventory))
	itemCountLabel.text += " " + HUD.get_color_string("common") + str(count_items_in_inventory(common_inventory))
	
	var common_keyword = HUD.get_color_string("common") + "Q[/color]"
	var rare_keyword = HUD.get_color_string("rare") + "E[/color]"
	var legendary_keyword = HUD.get_color_string("legendary") + "R[/color]"
	
	#search
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
		
	match typed.left(common_keyword.length()):
		common_keyword:
			searchResults = get_artifact_names_and_ids("common")
		rare_keyword:
			searchResults = get_artifact_names_and_ids("rare")
		legendary_keyword:
			searchResults = get_artifact_names_and_ids("legendary")
			
	if (typed.length() < 2 + common_keyword.length() && typed.length() >= common_keyword.length()):
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
	elif (typed.length() == 2 + common_keyword.length()):
		var colorStringToRemove = HUD.get_color_string(latestSearchedInventory)
		var typedClean = typed.replace(colorStringToRemove, "")
		typedClean = typedClean.replace("[/color]", "")
		var foundArtifact = find_artifact_by_id(typedClean)[0]
		if (foundArtifact != {}): 
			if selectedArtifact == find_artifact_by_id(typedClean)[0]:
				selectedArtifact = {}
			else:
				selectedArtifact = find_artifact_by_id(typedClean)[0]
				selectedArtifactRarity = find_artifact_by_id(typedClean)[1]
			# print("Selected artifact: " + selectedArtifact.name)
		typed = ""
	hue += hueSpeed * delta
	if (hue >= 1):
		hue -= 1
	# print(typedClean + ", " + colorStringToRemove)
	var colorStringToRemove = HUD.get_color_string(latestSearchedInventory)
	var typedClean = typed.replace(colorStringToRemove, "")
	typedClean = typedClean.replace("[/color]", "")
	var filteredLines = filter_lines(searchResults, typedClean)
	searchLabel.text = "Search with ID: [i]" + typed + "[/i]" + "\n"
	if filteredLines:
		searchLabel.text += filteredLines
	else:
		if typed == "":
			searchLabel.text += "[i] Press " + HUD.get_color_string("common") + "Q[/color], " + HUD.get_color_string("rare") + "E[/color], or " + HUD.get_color_string("legendary") + "R[/color] to search the matching inventory\n" 
			if selectedArtifact:
				if selectedArtifact.name:
					searchLabel.text += " Selected Artifact: " + HUD.get_color_string(selectedArtifactRarity) + str(selectedArtifact.name) + "[/color], " + str(selectedArtifact.count) + " use"
					if selectedArtifact.count > 1:
						searchLabel.text += "s"
					searchLabel.text += " remaining."
		else:
			searchLabel.text += "[i] No Artifacts found on " + HUD.get_color_string(latestSearchedInventory) + latestSearchedInventory + " inventory[/color]!"
	
	#artifact usage
	if (Input.is_action_just_pressed("Fire Artifact") && selectedArtifact != {}):
		var artifactScene = load("res://artifacts/scenes/" + selectedArtifact["name"] + ".tscn")
		var spawnedArtifact = artifactScene.instantiate()
		get_node("../Player/Drill & Colliders").add_child(spawnedArtifact) 
		if selectedArtifact.count == 1:
			remove_artifact_from_inventory(selectedArtifact["name"], selectedArtifactRarity)
			selectedArtifact = {}
		else:
			selectedArtifact["count"] -= 1
	
func _ready():
	selectedArtifact = {}
	HUD = get_node("/root/Node2D/HUD")
	give_new_artifact("legendary")
	if cheatMode:
		for i in range(100):
			give_new_artifact()
	
func print_artifact_info(artifact: Dictionary):
	print("Selected Artifact: %s" % artifact.name)
	print("Extra HP: %d" % artifact.extra_hp)
	print("Sell Value: %d" % artifact.sell_value)
	print("Description: %s" % artifact.description)

func select_random_artifact(rarity: String) -> Dictionary:
	if (rarity == "random"):
		rarity = randomize_rarity()
	latestRarity = rarity
	
	match rarity:
		"common":
			var artifact_name = common_artifacts.keys()[randi() % common_artifacts.size()]
			return {"name": artifact_name, "id": common_artifacts[artifact_name]["id"], "extra_hp": common_artifacts[artifact_name]["extra_hp"], "sell_value": common_artifacts[artifact_name]["sell_value"], "description": common_artifacts[artifact_name]["description"]}
		"rare":
			var artifact_name = rare_artifacts.keys()[randi() % rare_artifacts.size()]
			return {"name": artifact_name, "id": rare_artifacts[artifact_name]["id"], "extra_hp": rare_artifacts[artifact_name]["extra_hp"], "sell_value": rare_artifacts[artifact_name]["sell_value"], "description": rare_artifacts[artifact_name]["description"]}
		"legendary":
			var artifact_name = legendary_artifacts.keys()[randi() % legendary_artifacts.size()]
			return {"name": artifact_name, "id": legendary_artifacts[artifact_name]["id"], "extra_hp": legendary_artifacts[artifact_name]["extra_hp"], "sell_value": legendary_artifacts[artifact_name]["sell_value"], "description": legendary_artifacts[artifact_name]["description"]}
		_:
			return {"name": "Unknown", "extra_hp": 0, "sell_value": 0, "description": "No description available."}

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
			if artifact.name in common_inventory:
				common_inventory[artifact.name]["count"] += 1
			else:
				common_inventory[artifact.name] = artifact
				common_inventory[artifact.name]["count"] = 1
		"rare":
			if artifact.name in rare_inventory:
				rare_inventory[artifact.name]["count"] += 1
			else:
				rare_inventory[artifact.name] = artifact
				rare_inventory[artifact.name]["count"] = 1
		"legendary":
			if artifact.name in legendary_inventory:
				legendary_inventory[artifact.name]["count"] += 1
			else:
				legendary_inventory[artifact.name] = artifact
				legendary_inventory[artifact.name]["count"] = 1
		_:
			print("Unknown rarity: %s" % rarity)
			return

func artifact_exists(artifact_name: String, rarity: String) -> bool:
	match rarity:
		"common":
			# print("Artifact exists in ", rarity)
			return common_inventory.has(artifact_name)
		"rare":
			# print("Artifact exists in ", rarity)
			return rare_inventory.has(artifact_name)
		"legendary":
			# print("Artifact exists in ", rarity)
			return legendary_inventory.has(artifact_name)
		_:
			print("Unknown rarity: %s" % rarity)
			return false

func count_items_in_inventory(inventory: Dictionary) -> int:
	var total_count = 0
	for artifact_name in inventory.keys():
		total_count += inventory[artifact_name]["count"]
	return total_count

func give_new_artifact(rarityOverride: String = "random"):
	var newArtifact = select_random_artifact(rarityOverride)
	var isArtifactNew = !artifact_exists(newArtifact.name, latestRarity)
	add_artifact_to_inventory(newArtifact,latestRarity)
	latestArtifact = newArtifact
	displayArtifactInfo.emit(newArtifact, latestRarity, isArtifactNew)

func get_artifact_names_and_ids(rarity: String) -> String:
	var result = ""

	var inventoryValues
	match rarity:
		"common":
			inventoryValues = common_inventory.values()
		"rare":
			inventoryValues = rare_inventory.values()
		"legendary":
			inventoryValues = legendary_inventory.values()
		_:
			print("Unknown rarity: %s" % rarity)
			return ""
	
	var resultRarity = "[u][b]" + HUD.get_color_string(rarity) 
	for artifact in inventoryValues:
		var countString = ""
		var selectedString = ""
		if (artifact["count"] > 1):
			countString = " x" + str(artifact["count"])
		if (artifact == selectedArtifact):
			var hsv_color = Color.from_hsv(hue, 1, 1,)
			selectedString += "[color=" + color_to_hex(hsv_color) + "] Selected![/color]"
		result += resultRarity + artifact["name"] + "[/color][/b][/u]" + countString + " (ID:" + artifact["id"] + ")" + " [color=#f2ee15]Total DE: " + str(artifact["sell_value"] * artifact["count"]) + "[/color]" +  selectedString +"\n"
	
	return result.strip_edges()

func filter_lines(input_string: String, keyword: String) -> String:
	var lines = input_string.split("\n")   # Split the string into lines
	var result = []

	for line in lines:
		if keyword in line:
			result.append(line)

	# Join the filtered lines back into a single string
	var joined_string = ""
	for line in result:
		joined_string += line + "\n"

	# Remove the trailing newline character if necessary
	if joined_string.length() > 0:
		joined_string = joined_string.substr(0, joined_string.length() - 1)

	return joined_string

func color_to_hex(color: Color) -> String:
	# Convert Color to RGB
	var r = int(color.r * 255)
	var g = int(color.g * 255)
	var b = int(color.b * 255)

	# Format as a hexadecimal string
	return String("%02X%02X%02X" % [r, g, b])

func find_artifact_by_id(id: String) -> Array:
	# Search in common inventory
	for artifact_name in common_inventory.keys():
		var artifact = common_inventory[artifact_name]
		if artifact["id"] == id:
			return [artifact, "common"]
	
	# Search in rare inventory
	for artifact_name in rare_inventory.keys():
		var artifact = rare_inventory[artifact_name]
		if artifact["id"] == id:
			return [artifact, "rare"]
	
	# Search in legendary inventory
	for artifact_name in legendary_inventory.keys():
		var artifact = legendary_inventory[artifact_name]
		if artifact["id"] == id:
			return [artifact, "legendary"]
	
	# Return an empty dictionary if the artifact is not found
	return [{}, ""]

func remove_artifact_from_inventory(artifactStr: String, rarity: String = "any") -> bool:
	var correctInventory: Dictionary
	var artifact: Dictionary 
	match rarity:
			"common":
				correctInventory = common_inventory
			"rare":
				correctInventory = rare_inventory
			"legendary":
				correctInventory = legendary_inventory
	if rarity == "any":
		for inventory in [common_inventory, rare_inventory, legendary_inventory]:
			var gotten = inventory.get(artifactStr, {})
			if gotten != {}:
				artifact = gotten
				correctInventory = inventory
	else:
		artifact = correctInventory.get(artifactStr)
	if artifact == {}:
		printerr("Did not find artifact!")
	if artifact.count > 1:
		artifact.count -= 1
		return false
	else:
		print("Erased artifact: "+str(artifact))
		if artifact == selectedArtifact:
			selectedArtifact = {}
		correctInventory.erase(artifact.name)
		return true

func calculate_total_sell_value() -> int:
	var total_sell_value = 0
	
	# Accumulate sell values from common_inventory
	for artifact_name in common_inventory.keys():
		var artifact = common_inventory[artifact_name]
		total_sell_value += artifact["sell_value"] * artifact["count"]
	
	# Accumulate sell values from rare_inventory
	for artifact_name in rare_inventory.keys():
		var artifact = rare_inventory[artifact_name]
		total_sell_value += artifact["sell_value"] * artifact["count"]
	
	# Accumulate sell values from legendary_inventory
	for artifact_name in legendary_inventory.keys():
		var artifact = legendary_inventory[artifact_name]
		total_sell_value += artifact["sell_value"] * artifact["count"]
	
	return total_sell_value

func remove_least_valuables(amount: int) -> bool:
	var valuables = get_least_valuables(amount)
	var numberOfLeastValuables = 0
	for valuable in valuables.values():
		numberOfLeastValuables += valuable.count 
	if numberOfLeastValuables < amount:
		return false
	var top: int = 0
	var artifact: String = valuables.keys()[0]
	for i in range(amount):
		if remove_artifact_from_inventory(artifact):
			top += 1
			if valuables.keys().size() > top:
				artifact = valuables.keys()[top]
	return true

func get_least_valuables(amount: int = 1) -> Dictionary:
	var result: Dictionary = {}
	for i in range(amount):
		var leastValuable = get_least_valuable(result)
		if leastValuable == {"sell_value": 9999999999}:
			break
		result[leastValuable.name] = leastValuable 
	return result

func get_least_valuable(exclude: Dictionary = {}) -> Dictionary:
	var minSell: Dictionary = {"sell_value": 9999999999} 
	var inventories = [common_inventory, rare_inventory, legendary_inventory]
	for inventory in inventories:
		for artifact in inventory.values():
			# print("Testing: " + str(artifact))
			# print("   with: " + str(min))
			if artifact.sell_value < minSell.sell_value and not artifact.name in exclude.keys():
				minSell = artifact
	return minSell
