## base class for cell objects
class_name Cell
extends Node2D

## states of cells.
# TODO: bubble states do not really belong here
enum State { IDLE, MOVING, TURNING, ABSORBING, ENTERING, BURSTING, BOUNCING, FALLING, REMOVED }

enum BlockType { NONE, HARD, SOFT, BUBBLE }

@export
var state:State = State.IDLE: set = set_state

## the procesed tick step
var processed:bool

## position of cell
var pos:Vector2i

## direction
@export
var dir:Global.DIR = 0: set = set_dir

## internal flag indicating that the visual needs updating.
var _queue_update:bool = false

## if a cell is solid, its tile cannot occupy another cell.
## eg: wall, player, rock
var is_solid:bool = true

## if a cell is movable, it can be pushed.
var is_movable:bool = false

##
var can_push:bool = false

## if a cell is heavy, it will trigger the pressure plate
var is_heavy:bool = false

## if a cell is soft, it will absorb the impuls of a bubble (eg kelp or rock)
var is_soft:bool = false

var next_pos:Vector2i

var next_state:State = State.IDLE

var next_dir:int = 0

var influencers:Array[Cell] = []

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

## return the cell that is not "self"
func other(c0:Cell, c1:Cell)->Cell:
  return c0 if c1 == self else c1

## prepares the cell for the next tick and handles simple states
func tick_prepare(world:World)->void:
  processed = false
  next_pos = pos
  next_dir = dir
  next_state = state
  influencers.clear()
  if state == State.IDLE:
    if is_heavy && !world.is_ground(pos):
      next_state = State.FALLING
    return
  if state == State.FALLING:
    next_state = State.REMOVED
    return

## process moving cells and handle early stops
func tick_move(world:World)->void:
  if next_state == State.MOVING:
    next_pos = next_pos + Global.DIRS[next_dir]
    var bt:BlockType = is_blocked(world, next_pos)
    if bt:
      processed = true
      tick_stop()
      if bt == BlockType.HARD:
        tick_bounce(null)

## checks if the cell is blocked at the given position by a solid cell, like wall or door
func is_blocked(world:World, pos:Vector2i)->BlockType:
  var t:StringName = world.get_type(pos)
  if t == &"wall": return BlockType.HARD
  if t == &"kelp": return BlockType.SOFT
  # special case for player that can walk into the goal
  if t == &"goal" and not self is Player: return BlockType.HARD
  # special case for player that it can't fall into abyss
  if self is Player and not world.is_ground(pos): return BlockType.HARD
  for c:Cell in world.get_next_cells(pos, self):
    if c && c.is_solid && !c.is_movable: return BlockType.HARD
  return BlockType.NONE

## sets the state to IDLE and resets next_pos and next_dir
func tick_stop()->void:
  next_state = State.IDLE
  next_pos = pos
  next_dir = dir
  for c in influencers:
    c.tick_stop()
    c.tick_bounce(null)

## check if this cell can be merged with the other and returns the "winning" one.
## this is also used to check player pickup
func can_merge(other:Cell)->Cell:
  return null

func tick_merge(other:Cell)->void:
  pass

func tick_push(c:Cell)->void:
  c.influencers.append(self)
  c.next_state = State.MOVING
  c.next_dir = next_dir
  c.processed = false

func tick_bounce(other:Cell)->void:
  pass

# check if a cell at next_pos swapped place with this cell at pos
func get_swap(world:World)->Cell:
  ## get cell at our previous location
  var c:Cell = world.get_next_cell(pos, self)
  ## if the cells previous pos is this cells next_pos, they swapped
  if c && c.pos == next_pos: return c
  return null

func tick(world:World)->void:
  if processed: return
  processed = true
  if next_state == State.MOVING:
    var cells:Array[Cell] = world.get_next_cells(next_pos, self)
    if cells.is_empty():
      return
    if cells.size() > 1:
      # stop all cells
      tick_stop()
      tick_bounce(cells[0])
      for c:Cell in cells:
        c.tick_stop()
        c.tick_bounce(self)
      return

    var c:Cell = cells[0]
    if !c:
      c = get_swap(world)
    if !c:
      return
    if can_push && c.is_movable && c.next_state != State.MOVING:
      ## move away
      tick_push(c)
      c.tick_move(world)
      return
    var p:Cell = can_merge(c)
    if p:
      p.tick_merge(p.other(self, c))
      return
    tick_stop()
    tick_bounce(c)

func apply_tick(world:World)->void:
  set_pos(next_pos)
  set_dir(next_dir)
  set_state(next_state)
  if state == State.REMOVED:
    visible = false # freed in next tick
