class_name LevelSelect
extends MarginContainer


@onready var levels_grid: GridContainer = %levels_grid

var levels = [
  preload("res://levels/level0.tscn"),
  preload("res://levels/level1.tscn"),
  preload("res://levels/level2.tscn"),
  preload("res://levels/level3.tscn"),
  preload("res://levels/level4.tscn"),
  preload("res://levels/level5.tscn"),
  preload("res://levels/level6.tscn"),
  preload("res://levels/level7.tscn"),
  preload("res://levels/level8.tscn"),
  preload("res://levels/level9.tscn"),
  preload("res://levels/level10.tscn"),
  preload("res://levels/level11.tscn"),
  preload("res://levels/level12.tscn"),
  preload("res://levels/level13.tscn"),
  preload("res://levels/level14.tscn"),
  preload("res://levels/level15.tscn")
]

const MIN_LEVEL:int = 0

func _ready():
  var template:Button
  for n in levels_grid.get_children():
    if n.name != 'template':
      n.queue_free()
    else:
      template = n
      n.hide()
  for i in range(MIN_LEVEL, levels.size()):
    var btn:Button = template.duplicate()
    btn.visible = true
    btn.text = str(i)
    btn.pressed.connect(_on_level_pressed.bind(i))
    levels_grid.add_child(btn)

func focus_level():
  for n in levels_grid.get_children():
    if n.visible:
      n.grab_focus()
      return

func _on_level_pressed(nr:int):
  Global.select_level.emit(nr)
