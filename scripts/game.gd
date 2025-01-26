class_name Game
extends Node2D

@onready var world: World = %world
@onready var level_select: LevelSelect = $gui/level_select
@onready var title: MarginContainer = $gui/title

@onready var play: Button = $gui/title/VBoxContainer/play
@onready var win: MarginContainer = $gui/win
@onready var nextlevel: Button = $gui/win/VBoxContainer/nextlevel
@onready var pause: MarginContainer = $gui/pause
@onready var restart: Button = $gui/pause/VBoxContainer/restart

var current_level: int = 0

func _ready():
  Global.select_level.connect(load_level)
  Global.level_complete.connect(show_win)
  show_title()
  #show_level_select()

func show_title():
  get_tree().paused = true
  pause.hide()
  world.hide()
  level_select.hide()
  win.hide()
  title.show()
  play.grab_focus()

func show_level_select():
  get_tree().paused = true
  world.hide()
  pause.hide()
  level_select.show()
  title.hide()
  win.hide()
  level_select.focus_level()

func load_level(nr:int):
  current_level = nr
  level_select.hide()
  win.hide()
  get_tree().paused = false
  world.show()
  world.load_level(nr, level_select.levels[nr])

func show_win():
  get_tree().paused = true
  win.show()
  nextlevel.grab_focus()
  world.hide()
  level_select.hide()
  title.hide()

func show_pause():
  pause.show()
  world.hide()
  restart.grab_focus()
  get_tree().paused = true

func hide_pause():
  pause.hide()
  world.show()
  get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed("pause"):
    get_viewport().set_input_as_handled()
    if pause.visible:
      hide_pause()
    elif world.visible:
      show_pause()
  if event.is_action_pressed("restart"):
    get_viewport().set_input_as_handled()
    _on_restart_pressed()

func _on_play_pressed() -> void:
  show_level_select()

func _on_nextlevel_pressed() -> void:
  load_level(current_level+1)

func _on_restart_pressed() -> void:
  hide_pause()
  load_level(current_level)

func _on_cont_pressed() -> void:
  hide_pause()

func _on_quit_level_pressed() -> void:
  hide_pause()
  show_level_select()
