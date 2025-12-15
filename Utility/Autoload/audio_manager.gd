extends Node

## AudioManager - Centralized audio control
## Add this as an autoload singleton in Project Settings -> Globals -> Autoload
## Name it "AudioManager"

const AUDIO_PATH = "res://Assets/Audio/"

# Audio players
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var player_sfx: AudioStreamPlayer  # Separate player for player sounds to avoid cutting off

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# Current music track
var current_music: String = ""

# Player attack sounds
var player_sounds: Dictionary = {
	"punch_light": "punch.wav",
	"punch_heavy": "punch.wav",
	"dodge": "dodge.wav",
	"duck": "duck.wav",
	"player_hit": "player_hit.wav",
	"player_death": "player_death.wav",
}

# UI sounds
var ui_sounds: Dictionary = {
	"menu_select": "menu_select.wav",
	"menu_confirm": "menu_confirm.wav",
	"menu_back": "menu_back.wav",
	"pause": "pause.wav",
}

# General game sounds
var game_sounds: Dictionary = {
	"victory": "victory.wav",
	"defeat": "defeat.wav",
	"round_start": "round_start.wav",
	"phase_change": "phase_change.wav",
	"combo_break": "combo_break.wav",
}


func _ready() -> void:
	_setup_audio_players()


func _setup_audio_players() -> void:
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	# General SFX player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	# Player-specific SFX player (so player sounds don't cut off enemy sounds)
	player_sfx = AudioStreamPlayer.new()
	player_sfx.name = "PlayerSFX"
	player_sfx.bus = "SFX"
	add_child(player_sfx)


# ===== MUSIC =====

func play_music(music_file: String, loop: bool = true) -> void:
	if music_file.is_empty():
		return
	
	# Don't restart if already playing same track
	if current_music == music_file and music_player.playing:
		return
	
	var music_path = AUDIO_PATH + music_file
	if ResourceLoader.exists(music_path):
		var music = load(music_path)
		if music:
			music_player.stream = music
			# Set loop mode if it's an AudioStreamWAV or AudioStreamOggVorbis
			if music is AudioStreamWAV:
				music.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
			elif music is AudioStreamOggVorbis:
				music.loop = loop
			music_player.play()
			current_music = music_file
	else:
		push_warning("Music not found: " + music_path)


func stop_music() -> void:
	music_player.stop()
	current_music = ""


func fade_out_music(duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, duration)
	tween.tween_callback(stop_music)
	tween.tween_callback(func(): music_player.volume_db = 0.0)


func fade_in_music(music_file: String, duration: float = 1.0) -> void:
	music_player.volume_db = -80.0
	play_music(music_file)
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", 0.0, duration)


# ===== SOUND EFFECTS =====

func play_sound(sound_file: String) -> void:
	if sound_file.is_empty():
		return
	
	var sound_path = AUDIO_PATH + sound_file
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if sound:
			sfx_player.stream = sound
			sfx_player.play()
	else:
		push_warning("Sound not found: " + sound_path)


func play_sound_at_volume(sound_file: String, volume_db: float) -> void:
	if sound_file.is_empty():
		return
	
	var sound_path = AUDIO_PATH + sound_file
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if sound:
			sfx_player.stream = sound
			sfx_player.volume_db = volume_db
			sfx_player.play()
			# Reset volume after playing
			await sfx_player.finished
			sfx_player.volume_db = 0.0
	else:
		push_warning("Sound not found: " + sound_path)


# ===== PLAYER SOUNDS =====

func play_player_sound(sound_key: String) -> void:
	if not player_sounds.has(sound_key):
		push_warning("Unknown player sound: " + sound_key)
		return
	
	var sound_file = player_sounds[sound_key]
	var sound_path = AUDIO_PATH + sound_file
	
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if sound:
			player_sfx.stream = sound
			player_sfx.play()
	else:
		push_warning("Player sound not found: " + sound_path)


func play_punch_light() -> void:
	play_player_sound("punch_light")


func play_punch_heavy() -> void:
	play_player_sound("punch_heavy")


func play_dodge() -> void:
	play_player_sound("dodge")


func play_duck() -> void:
	play_player_sound("duck")


func play_player_hit() -> void:
	play_player_sound("player_hit")


func play_player_death() -> void:
	play_player_sound("player_death")


# ===== UI SOUNDS =====

func play_ui_sound(sound_key: String) -> void:
	if not ui_sounds.has(sound_key):
		push_warning("Unknown UI sound: " + sound_key)
		return
	
	play_sound(ui_sounds[sound_key])


func play_menu_select() -> void:
	play_ui_sound("menu_select")


func play_menu_confirm() -> void:
	play_ui_sound("menu_confirm")


func play_menu_back() -> void:
	play_ui_sound("menu_back")


# ===== GAME SOUNDS =====

func play_game_sound(sound_key: String) -> void:
	if not game_sounds.has(sound_key):
		push_warning("Unknown game sound: " + sound_key)
		return
	
	play_sound(game_sounds[sound_key])


func play_victory() -> void:
	play_game_sound("victory")


func play_defeat() -> void:
	play_game_sound("defeat")


func play_round_start() -> void:
	play_game_sound("round_start")


func play_phase_change() -> void:
	play_game_sound("phase_change")


# ===== VOLUME CONTROL =====

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))


func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))


func mute_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)


func unmute_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func toggle_mute() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_idx, not AudioServer.is_bus_mute(master_idx))
