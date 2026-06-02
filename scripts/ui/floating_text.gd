extends Node2D

@onready var text_label: RichTextLabel = $RichTextLabel

func setup(text: String) -> void:
	text_label.text = text
