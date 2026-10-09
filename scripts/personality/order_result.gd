class_name OrderResult
extends RefCounted

## Typed container for the result of a companion leadership order evaluation.
## Conforms to PROJECT.md interface contract.

var status: int = 0                  # OrderStatus enum (OBEY = 0, HESITATE = 1, REFUSE = 2)
var delay_sec: float = 0.0          # Delay in seconds before executing order action
var voice_line: String = ""         # Contract line from PROJECT.md
var dialogue_line: String = ""      # Direct alias for voice_line
var bbcode_color: Color = Color.WHITE
var raw_score: float = 100.0
var reason: String = ""
var speaker_name: String = ""

func _init(
	p_status: int = 0,
	p_delay: float = 0.0,
	p_line: String = "",
	p_color: Color = Color.WHITE,
	p_score: float = 100.0,
	p_speaker: String = "",
	p_reason: String = ""
) -> void:
	status = p_status
	delay_sec = p_delay
	voice_line = p_line
	dialogue_line = p_line
	bbcode_color = p_color
	raw_score = p_score
	speaker_name = p_speaker
	reason = p_reason
