class_name Game
extends Node2D

@onready var world: World = %world
@onready var level_select: LevelSelect = $gui/level_select
@onready var title: MarginContainer = $gui/title

func _ready():
  Global.select_level.connect(load_level)
  show_title()
  #show_level_select()

func show_title():
  world.hide()
  world.process_mode = Node.PROCESS_MODE_DISABLED
  level_select.hide()
  title.show()

func show_level_select():
  world.hide()
  world.process_mode = Node.PROCESS_MODE_DISABLED
  level_select.show()
  title.hide()

func load_level(nr:int, scn:PackedScene):
  level_select.hide()
  world.show()
  world.process_mode = Node.PROCESS_MODE_INHERIT
  world.load_level(nr, scn)


func _on_play_pressed() -> void:
  show_level_select()


func _on_nextlevel_pressed() -> void:
  pass # Replace with function body.
