class_name Player
extends Node2D

@onready var visual: Sprite2D = $visual

## position in grid
var pos:Vector2i: set = set_pos

## direction
var dir:int = 0: set = set_dir

var stack:Array[Bubble] = []

func set_dir(v:int):
  dir = v
  visual.rotation_degrees = dir * 90
  visual.flip_v = dir != 0

func move_to(v:Vector2):
  pos = v

func set_pos(v:Vector2):
  pos = v
  transform.origin = Global.grid2cart(v)

func pop_bubble()->Bubble:
  return stack.pop_back()

func push_bubble(b:Bubble)->bool:
  if stack.is_empty():
    stack.append(b)
    return true
  return false

func reset():
  stack.clear()
