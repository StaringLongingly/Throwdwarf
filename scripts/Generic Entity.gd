extends Node2D

@export var isPlayer: bool = false
@export var enemyRarity: String
@export var hitParticles: PackedScene
@export var hpText: RichTextLabel
var cachedHPTextPosition: Vector2
@export var artifact: PackedScene
@export var hp: float = 100
@export var hpRegenRate: float = 0
@export var attackCooldown: float = 5
var startingHP
var currentCooldown
var currentDoTduration = 0
var latestDoTdps
signal lifeDrain

func _ready():
	startingHP = hp
	cachedHPTextPosition = hpText.position
	currentCooldown = attackCooldown
	
func _process(delta: float) -> void:
	if hp < startingHP:
		hp += hpRegenRate * delta
	var strHP: String = str(hp)
	if strHP.length() % 2 == 1 || strHP.length() <= 2:
		strHP += "."
	while strHP.length() <= 4:
		strHP += "0"
	var rarityColor = "[color=ff0000]"
	if !isPlayer:
		rarityColor = get_node("/root/Node2D/HUD").get_color_string(enemyRarity)
	hpText.text = "[code][center] " + rarityColor + strHP.left(4)
	if (currentDoTduration > 0):
		currentDoTduration -= delta
		hp -= latestDoTdps * delta
		if hp <= 0:
			death()
	if !isPlayer:
		if (currentCooldown > 0):
			currentCooldown -= delta
		else:
			# print("Attacking the player")
			currentCooldown = attackCooldown
			var spawnedArtifact = artifact.instantiate()
			add_child(spawnedArtifact)
	else:
		hpText.global_position = get_node("Helmet").global_position + cachedHPTextPosition 


func take_damage(damage: float, DoTdps: float, DoTduration: float, drainHP: float):
	# print("take_damage called")
	var particle = hitParticles.instantiate()
	add_child(particle)
	if isPlayer:
		particle.global_position = get_node("Helmet").global_position
	particle.global_scale = particle.scale
	particle.emitting = true
	
	currentDoTduration += DoTduration
	latestDoTdps = DoTdps
	hp -= damage
	emit_signal("lifeDrain", drainHP)
	if hp <= 0:
		death()


func _on_generic_enemy_life_drain(hpGain: float) -> void:
	if isPlayer:
		hp += hpGain

func death():
	if isPlayer:
		get_tree().reload_current_scene()
	else:
		queue_free()  # Remove the enemy if HP is 0 or below
