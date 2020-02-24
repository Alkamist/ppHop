extends Control

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			hide()
			get_tree().paused = false
		else:
			show()
			get_tree().paused = true

func _on_Resume_pressed():
	hide()
	get_tree().paused = false

func _on_MainMenu_pressed():
	get_tree().paused = false
	GameSaver.save_enabled = false
	BiomeTitleText.hide_text()
	get_tree().change_scene("res://Menus/MainMenu.tscn")

func _on_ExitGame_pressed():
	get_tree().quit()
