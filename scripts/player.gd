class_name Player
extends Cell

@onready var visual: Sprite2D = $visual

## the bubble the player is holding
var bubble:Bubble

## desired direction tp move
var input_dir:int = -1

func _ready():
  super()
  is_movable = false
  is_solid = false
  is_heavy = true

func set_dir(v:int):
  super(v)
  visual.rotation_degrees = dir * 90
  visual.flip_v = dir != 0

func pop_bubble()->Bubble:
  var ret:Bubble = bubble
  bubble = null
  return ret

func push_bubble(b:Bubble)->bool:
  if bubble == null:
    return false
  bubble = b
  return true

func reset():
  bubble = null

func tick_pickup(world:World, b:Bubble)->void:
  if bubble:
    if b.state == Cell.State.MOVING:
      b.tick_stop()
      b.bounce()
    else:
      tick_stop()
  else:
    b.processed = true
    b.next_state = State.ENTERING
    b.visible = false
    bubble = b

func prepare_tick(world:World)->void:
  super(world)
  if input_dir >= 0:
    state = State.MOVING
    next_dir = input_dir
    input_dir = -1

func apply_tick(world:World)->void:
  super(world)
  # player only moves 1 tile
  state = State.IDLE
