class_name Player
extends Cell

@onready var visual: Sprite2D = $visual

## the bubble the player is holding
var bubble:Bubble

## the bubble to be picked up
var next_bubble:Bubble

## desired direction tp move
var input_dir:int = -1

func _ready():
  super()
  is_movable = false
  is_solid = false
  is_heavy = true
  can_push = true

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

func can_merge(other:Cell)->Cell:
  var b:Bubble = other as Bubble
  if !b or bubble: return null
  return self

func tick_merge(other:Cell)->void:
  assert(other is Bubble)
  other.processed = true
  other.next_state = State.ENTERING
  #other.visible = false
  next_bubble = other

func prepare_tick(world:World)->void:
  super(world)
  next_bubble = null
  if input_dir >= 0:
    state = State.MOVING
    next_dir = input_dir
    input_dir = -1

func apply_tick(world:World)->void:
  super(world)
  if next_bubble:
    assert(not bubble)
    bubble = next_bubble
    bubble.visible = false

  # player only moves 1 tile
  state = State.IDLE
