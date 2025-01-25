class_name World
extends Node2D

const BUBBLE = preload('res://bubble.tscn')

@onready var player: Player = %player
@onready var objects: Node2D = %objects

@onready var floor: TileMapLayer = $level/floor
@onready var walls: TileMapLayer = $level/walls

var tick_speed:float = 0.8

var bubbles:Array[Bubble] = []

var time:float = 0

var ticks:int = 0

func _ready():
  init_level()

func _unhandled_input(event:InputEvent)->void:
  if event.is_action_pressed('move_up'):
    player_move(Global.DIR.UP)
  if event.is_action_pressed('move_right'):
    player_move(Global.DIR.RIGHT)
  if event.is_action_pressed('move_down'):
    player_move(Global.DIR.DOWN)
  if event.is_action_pressed('move_left'):
    player_move(Global.DIR.LEFT)
  if event.is_action_pressed('shoot'):
    release_bubble()

func _process(delta:float)->void:
  time += delta
  if time < tick_speed: return
  time -= tick_speed
  do_tick()

func do_tick():
  prints('tick', ticks)
  ticks += 1
  # reset
  for b in bubbles:
    b.reset()

  # calculate next state
  for b in bubbles:
    tick(b)

  # apply
  for b in bubbles:
    b.apply(tick_speed)
    if b.state == Bubble.State.ENTERING:
      bubbles.erase(b)

func get_bubble(pos:Vector2i, ignored:Bubble)->Bubble:
  for b:Bubble in bubbles:
    if b != ignored && b.pos == pos: return b
  return null

func get_next_bubble(pos:Vector2i, ignored:Bubble)->Bubble:
  for b:Bubble in bubbles:
    if b != ignored && b.next_pos == pos: return b
  return null

func tick(b:Bubble):
  if b.processed: return
  b.processed = true

  if b.state == Bubble.State.IDLE:
    return
  if b.state == Bubble.State.ABSORBING:
    b.state = Bubble.State.MOVING
    b.next_state = Bubble.State.MOVING
  if b.state == Bubble.State.TURNING:
    b.state = Bubble.State.MOVING
    b.next_state = Bubble.State.MOVING

  if b.state == Bubble.State.MOVING:
    # check if another bubble is on this pos
    var c:Bubble = get_bubble(b.pos, b)
    if c:
      c.processed = true
      var p:Bubble = b.can_merge(c)
      if p == null:
        b.turn()
        c.turn()
      elif p == b:
        b.merge(c)
      else:
        c.merge(b)
      return

    var dir:int = b.dir
    var next_pos:Vector2i = b.pos + Global.DIRS[dir]
    if walls.get_cell_tile_data(next_pos) != null:
      # bounce on wall
      b.turn()
      return
    c = get_bubble(next_pos, b)
    if c == null:
      b.next_pos = next_pos
      return

    if !c.processed:
      tick(c)
    if c.next_state == Bubble.State.MOVING && c.next_pos != next_pos:
      b.next_pos = next_pos
      return

    # check if it can merge
    var p:Bubble = b.can_merge(c)
    if p == null:
      # bounce on bubble
      b.turn()
      return

    # continue and check in next tick
    b.next_pos = next_pos


func player_move(dir:int):
  player.dir = dir
  if can_move(dir):
    player.pos += Global.DIRS[dir]

func can_move(dir)->bool:
  var pos:Vector2 = player.pos + Global.DIRS[dir]
  return walls.get_cell_tile_data(pos) == null

func get_type(pos:Vector2i)->StringName:
  var d:TileData = walls.get_cell_tile_data(pos)
  if !d: return ""
  return d.get_custom_data("type")

func create_bubble(pos:Vector2i, type:Bubble.Type)->Bubble:
  var b:Bubble = BUBBLE.instantiate()
  b.set_pos(pos)
  b.set_type(type)
  bubbles.append(b)
  objects.add_child(b)
  return b

func release_bubble()->void:
  var b:Bubble = create_bubble(player.pos + Global.DIRS[player.dir], Bubble.Type.WHITE)
  b.dir = player.dir
  b.state = Bubble.State.MOVING

func init_level():
  ## objects and start position from walls
  for c:Vector2i in walls.get_used_cells():
    var d:TileData = walls.get_cell_tile_data(c)
    var type:StringName = d.get_custom_data("type")
    var color:Bubble.Type = Bubble.type_from_color(d.get_custom_data("color"))
    if type == &"start":
      player.pos = c
      walls.set_cell(c, -1)
    elif type == &"bubble":
      create_bubble(c, color)
      walls.set_cell(c, -1)
