## base class for cell objects
class_name Cell
extends Node2D

var processed:bool

## position in grid
var pos:Vector2i

var next_pos:Vector2i

## direction
@export
var dir:Global.DIR = 0: set = set_dir

## internal flag indicating that the visual needs updating.
var _queue_update:bool = false

var next_dir:int = 0

func _ready() -> void:
  _queue_update = true
  if !Engine.is_editor_hint():
    pos = Global.cart2grid(position)

func reset():
  processed = false
  next_pos = pos
  next_dir = dir

func set_dir(v:int):
  if dir != v:
    dir = v
    _queue_update = true

func apply():
  pos = next_pos
  dir = next_dir

func set_pos(v:Vector2):
  pos = v
  next_pos = v
  position = Global.grid2cart(v)
