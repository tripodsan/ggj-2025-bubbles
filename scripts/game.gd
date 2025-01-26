class_name Game
extends Node2D

@onready var world: World = %world
@onready var level_select: LevelSelect = $gui/level_select
@onready var title: MarginContainer = $gui/title

@onready var play: Button = $gui/title/VBoxContainer/play
@onready var win: MarginContainer = $gui/win

var current_level: int = 0

func _ready():
  Global.select_level.connect(load_level)
  show_title()
  #show_level_select()

func show_title():
  world.hide()
  world.process_mode = Node.PROCESS_MODE_DISABLED
  level_select.hide()
  win.hide()
  title.show()
  play.grab_focus()

func show_level_select():
  world.hide()
  world.process_mode = Node.PROCESS_MODE_DISABLED
  level_select.show()
  title.hide()
  win.hide()
  level_select.focus_level()


func load_level(nr:int):
  current_level = nr
  level_select.hide()
  win.hide()
  world.show()
  world.process_mode = Node.PROCESS_MODE_INHERIT
  world.load_level(nr, level_select.levels[nr])

func show_win():
  win.show()
  world.hide()
  world.process_mode = Node.PROCESS_MODE_DISABLED
  level_select.hide()
  title.hide()

func _on_play_pressed() -> void:
  show_level_select()


func _on_nextlevel_pressed() -> void:
  load_level(current_level+1)
