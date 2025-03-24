class_name Player
extends Cell

@onready var visual: Sprite2D = $visual

## the bubble the player is holding
var bubble:Bubble

## the bubble to be picked up
var next_bubble:Bubble

## desired direction tp move
var input_dir:int = -1

## desire to shoot a bubble
var input_shoot:bool = false

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

func push_bubble(b:Bubble)->bool:
  if bubble == null:
    return false
  bubble = b
  return true

func reset():
  bubble = null

## tries if the player can immediately move to the new location, speeding
## up the gameplay
func try_move(world:World, dir:int)->bool:
  if state != State.IDLE:
    return false
  if next_bubble:
    return false
  next_pos = pos + Global.DIRS[dir]
  var bt:BlockType = is_blocked(world, next_pos)
  if bt:
    return false
  var cells:Array[Cell] = world.get_next_cells(next_pos, self)
  if cells.size() > 0:
    return false
  next_state = State.MOVING
  next_dir = dir
  apply_tick(world)
  return true

func can_merge(other:Cell)->Cell:
  var b:Bubble = other as Bubble
  if !b or bubble: return null
  return self

func can_shoot(world:World)->bool:
  return bubble and not bubble.is_blocked(world, pos + Global.DIRS[dir])

func tick_merge(other:Cell)->void:
  assert(other is Bubble)
  other.processed = true
  other.next_state = State.ENTERING
  next_bubble = other

func tick_prepare(world:World)->void:
  super(world)
  next_bubble = null
  if input_shoot && bubble:
    # sanity check
    if bubble.is_blocked(world, pos + Global.DIRS[dir]):
      return
    world.dispatch_bubble(bubble)
    bubble.leave(pos)
    bubble.set_dir(dir)
    bubble.next_dir = dir
    bubble.tick_prepare(world)
    bubble = null
    return
  if input_dir >= 0:
    next_state = State.MOVING
    next_dir = input_dir

func apply_tick(world:World)->void:
  super(world)
  if next_bubble:
    assert(not bubble)
    bubble = next_bubble
    bubble.visible = false

  # player only moves 1 tile
  input_dir = -1
  input_shoot = false
  state = State.IDLE
