## base class for cell objects
class_name Cell
extends Node2D

var processed:bool

## position in grid
var pos:Vector2i

var next_pos:Vector2i

## direction
var dir:int = 0

var next_dir:int = 0

func _ready() -> void:
  pos = Global.cart2grid(position)

func reset():
  processed = false
  next_pos = pos
  next_dir = dir

func set_dir(v:int):
  dir = v

func apply(speed:float):
  pos = next_pos
  dir = next_dir

func set_pos(v:Vector2):
  pos = v
  next_pos = v
  position = Global.grid2cart(v)
