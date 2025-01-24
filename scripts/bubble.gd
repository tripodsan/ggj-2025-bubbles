class_name Bubble
extends Node2D

## position in grid
var pos:Vector2i

## next state
var next_pos:Vector2i

@onready var sub: Node2D = $sub

var tween:Tween

var left:Bubble
var right:Bubble

var is_moving:bool = false

## direction
var dir:int = 0: set = set_dir

func set_dir(v:int):
  dir = v
  #visual.rotation_degrees = dir * 90

func move_to(v:Vector2):
  pos = v

func apply(speed:float):
  pos = next_pos
  if tween:
    tween.stop()
  tween = create_tween()
  tween.tween_property(self, 'position', Global.grid2cart(pos), speed)

func set_pos(v:Vector2):
  pos = v
  next_pos = v
  transform.origin = Global.grid2cart(v)

func merge(b:Bubble)->bool:
  if left == null:
    left = b
    b.reparent(sub, false)
    b.position = Vector2.ZERO
    return true
  return false
