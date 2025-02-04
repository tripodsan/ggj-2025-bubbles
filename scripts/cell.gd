## base class for cell objects
class_name Cell
extends Node2D

## states of cells.
# TODO: bubble states do not really belong here
enum State { IDLE, MOVING, TURNING, ABSORBING, ENTERING, BURSTING, BOUNCING, FALLING, REMOVED }

@export
var state:State = State.IDLE: set = set_state

var processed:bool

var pos:Vector2i

## direction
@export
var dir:Global.DIR = 0: set = set_dir

## internal flag indicating that the visual needs updating.
var _queue_update:bool = false

## if a cell is solid, its tile cannot occupy another cell.
## eg: wall, player, rock
var is_solid:bool = true

## if a cell is movable, it can be moved.
var is_movable:bool = false

## if a cell is heavy, it will trigger the pressure plate
var is_heavy:bool = false

## if a cell is soft, it will absorb the impuls of a bubble (eg kelp)
var is_soft:bool = false

var next_pos:Vector2i

var next_state:State = State.IDLE

var next_dir:int = 0

func _ready() -> void:
  _queue_update = true
  if !Engine.is_editor_hint():
    pos = Global.cart2grid(position)

func set_state(s:State)->void:
  if state != s:
    state = s
    _queue_update = true

func set_dir(v:int):
  if dir != v:
    dir = v
    _queue_update = true

func set_pos(v:Vector2):
  pos = v
  position = Global.grid2cart(pos)

## checks if the cell is blocked at the given position by a solid cell, like wall or door
func is_blocked(world:World, pos:Vector2i)->bool:
  var t:StringName = world.get_type(pos)
  if t == &"wall" or t == &"kelp": return true
  # special case for player that can walk into the goal
  if t == &"goal" and not self is Player: return true
  # special case for player that it can't fall into abyss
  if self is Player and not world.is_ground(pos): return true
  var c:Cell = world.get_next_cell(pos, self)
  if c && c.is_solid && !c.is_movable: return true
  return false

## sets the state to IDLE and resets next_pos and next_dir
func tick_stop()->void:
  next_state = State.IDLE
  next_pos = pos
  next_dir = dir

func prepare_tick(world:World)->void:
  if state == State.BOUNCING:
    state = State.MOVING
  processed = false
  next_pos = pos
  next_dir = dir
  next_state = state

## moves all the moving cells
func tick_move(world:World)->void:
  if state == State.MOVING:
    next_pos = pos + Global.DIRS[next_dir]
    if is_blocked(world, next_pos):
      if self is Bubble && world.get_type(next_pos) != &"kelp":
        tick_stop()
        (self as Bubble).bounce()
      else:
        tick_stop()
      processed = true

## updates the state and validates new positions
func tick(world:World)->void:
  if processed: return
  processed = true
  if state == State.IDLE:
    if is_heavy && !world.is_ground(pos):
      next_state = State.FALLING
      return
  if state == State.FALLING:
    next_state = State.REMOVED
    return
  if state == State.MOVING:
    var c:Cell = world.get_next_cell(next_pos, self)
    if !c: return
    # special case: player and bubble
    if self is Player and c is Bubble:
      (self as Player).tick_pickup(world, c)
      return
    if c.state == State.MOVING:
      # TODO: special case
      return
    if c.is_movable:
      # check if the movable can be pushed to the new place
      c.next_pos  = c.pos + Global.DIRS[next_dir]
      c.next_dir = next_dir
      c.processed = true
      if c.is_blocked(world, c.next_pos):
        c.tick_stop()
        tick_stop()
        if self is Bubble: (self as Bubble).bounce()
      else:
        # movable absorbs the momentum
        if self is Bubble:
          tick_stop()
      return
    # check if can bounce (currently only bubbles)
    if self is Bubble:
      (self as Bubble).bounce()
      return



func apply_tick(world:World)->void:
  set_pos(next_pos)
  set_dir(next_dir)
  set_state(next_state)
  if state == State.REMOVED:
    visible = false # freed in next tick
