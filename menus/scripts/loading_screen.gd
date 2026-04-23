extends Control

# Grab references to our nodes
@onready var loading_bar = $LoadingBar
@onready var hint_text = $HintText
@onready var text_timer = $TextTimer

# Create a list of different text strings
var hints = [
	"Loading... don't look behind you.",
	"Monsters run faster in the dark.",
	"Generating eerie fog...",
	"Remember to save your progress."
]

var current_hint_index = 0

func _ready():
	# Display the very first hint immediately when the scene starts
	hint_text.text = hints[0]

# We will connect the Timer to this function in the next step
func _on_text_timer_timeout():
	# Move to the next text in the list
	current_hint_index += 1
	
	# If we reach the end of the list, loop back to the beginning
	if current_hint_index >= hints.size():
		current_hint_index = 0
		
	# Update the Label with the new text
	hint_text.text = hints[current_hint_index]

# FAKING THE LOADING BAR (For visual testing)
func _process(delta):
	if loading_bar.value < 100:
		# Fills the bar by 15% every second
		loading_bar.value += 15 * delta
