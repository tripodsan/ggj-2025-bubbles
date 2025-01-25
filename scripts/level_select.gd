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
  preload("res://levels/level8.tscn")
]

func _ready():
  var template:Button
  for n in levels_grid.get_children():
    if n.name != '1':
      n.queue_free()
    else:
      template = n
      n.hide()
  var i:int = 0
  for lev in levels:
    var btn:Button = template.duplicate()
    btn.visible = true
    btn.text = str(i)
    btn.pressed.connect(_on_level_pressed.bind(i))
    levels_grid.add_child(btn)
    i += 1

func _on_level_pressed(nr:int):
  Global.select_level.emit(nr, levels[nr])
