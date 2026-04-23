extends Node3D

@onready var video_player = $SubViewport/VideoStreamPlayer

func _ready():
	# Play automatically if Autoplay is off
	video_player.play()

# Optional: loop the video
func _process(_delta):
	if not video_player.is_playing():
		video_player.play()

# Or use the finished signal instead of _process:
# video_player.finished.connect(video_player.play)
