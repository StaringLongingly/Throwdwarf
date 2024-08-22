extends Node

func _ready():
	# The path to the folder containing the .ogg files
	var folder_path = "res://sfx/Leaves"
	
	# Open the directory
	var dir = DirAccess.open(folder_path)
	
	if dir:
		# Begin listing files in the directory
		dir.list_dir_begin()
		var ogg_files = []
		
		# Iterate over all files in the directory
		var file_name = dir.get_next()
		while file_name != "":
			ogg_files.append(file_name)
			file_name = dir.get_next()
		
		# End listing of files
		dir.list_dir_end()
		
		# Select a random .ogg file from the list
		if ogg_files.size() > 0:
			var random_index = randi() % ogg_files.size()
			var selected_ogg = ogg_files[random_index]
			
			print("Selected file: ", selected_ogg)
			
			# Load and play the selected .ogg file
			var audio_stream = load(folder_path + "/" + selected_ogg) as AudioStream
			print(audio_stream)
			if audio_stream:
				var audio_player = AudioStreamPlayer3D.new()  # Use AudioStreamPlayer3D for 3D audio
				audio_player.stream = audio_stream
				audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
				audio_player.max_distance = 100000.0  # Set max distance to 100000 units
				audio_player.unit_size = 1.0  # Default unit size
				audio_player.play()  # Autoplay the sound
				add_child(audio_player)
	else:
		print("Failed to open directory: ", folder_path)
