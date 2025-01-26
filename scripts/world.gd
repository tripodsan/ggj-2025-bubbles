class_name World
extends Node2D

const BUBBLE = preload('res://bubble.tscn')
const ROCK = preload('res://rock.tscn')

@onready var player: Player = %player

var objects: Node2D

@onready var floor: TileMapLayer = $level/floor
@onready var walls: TileMapLayer = $level/walls

var tick_speed:float = 0.5

var bubbles:Array[Bubble] = []

var rocks:Array[Rock] = []

var sensors:Array[Sensor] = []

var doors:Array[Door] = []

var time:float = 0

var ticks:int = 0

var pending_move:bool = false

var current_level_scn:PackedScene

func _ready():
  pass
  #init_level()

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

func load_level(nr:int, scn:PackedScene):
  current_level_scn = scn
  var level:Node2D = get_node('level')
  remove_child(level)
  level.queue_free()
  level = scn.instantiate()
  add_child(level)
  move_child(level, 0)
  objects = Node2D.new()
  level.add_child(objects)
  init_level()

func _process(delta:float)->void:
  time += delta
  if time < tick_speed: return
  time -= tick_speed
  do_tick()

func do_tick():
  #prints('tick', ticks)
  ticks += 1
  # reset
  for b in rocks:
    b.reset()
  for b in bubbles:
    b.reset()

  #if pending_move:
    #tick_player()
    #pending_move = false

  # calculate next state
  for b in bubbles:
    tick(b)

  # apply
  for b in bubbles:
    b.apply(tick_speed)
    if b.state == Bubble.State.ENTERING:
      bubbles.erase(b)
  for r in rocks:
    r.apply(tick_speed)
    if !is_ground(r.pos):
      rocks.erase(r)
      r.queue_free()

  update_sensors()

func update_sensors():
  for r in rocks:
    var s:Sensor = get_sensor(r.pos)
    if s && s.type == Sensor.Type.PLATE:
      s.trigger_node = r
      s.activate(true)
  for b in bubbles:
    var s:Sensor = get_sensor(b.pos)
    if s:
      if s.type == b.type || s.type == Sensor.Type.SENSOR_WHITE:
        s.toggle()

  for s in sensors:
    if s.active && s.trigger_node && s.trigger_node.pos != s.pos:
      s.activate(false)
      s.trigger_node = null

func tick_player(dir:int):
  var pos:Vector2 = player.pos + Global.DIRS[dir]
  if walls.get_cell_tile_data(pos) != null: return
  if !is_ground(pos): return
  if is_closed_door(pos): return
  var r:Rock = get_rock(pos)
  if r != null:
    var next_rock_pos:Vector2i = r.pos + Global.DIRS[dir]
    if !can_move_rock(next_rock_pos): return
    if get_bubble(next_rock_pos, null): return
    r.set_pos(next_rock_pos)
  var b:Bubble = get_bubble(pos, null)
  if b:
    pickup_bubble(b)

  player.dir = dir
  player.pos = pos

func pickup_bubble(b:Bubble):
  bubbles.erase(b)
  b.visible = false
  player.push_bubble(b)



func is_ground(pos:Vector2i)->bool:
  var c:TileData = floor.get_cell_tile_data(pos)
  if c == null: return false
  return c.get_custom_data("type") == &"ground"

func get_sensor(pos:Vector2i)->Sensor:
  for s:Sensor in sensors:
    if s.pos == pos: return s
  return null

func is_closed_door(pos:Vector2i)->bool:
  for s:Door in doors:
    if s.pos == pos: return !s.open
  return false

func get_bubble(pos:Vector2i, ignored:Bubble)->Bubble:
  for b:Bubble in bubbles:
    if b != ignored && b.pos == pos: return b
  return null

func can_move_rock(pos:Vector2i):
  if walls.get_cell_tile_data(pos) != null: return
  if is_closed_door(pos): return
  return true

func get_rock(pos:Vector2i)->Rock:
  for r:Rock in rocks:
    if r.pos == pos: return r
  return null

func get_next_bubble(pos:Vector2i, ignored:Bubble)->Bubble:
  for b:Bubble in bubbles:
    if b != ignored && b.next_pos == pos: return b
  return null

func tick(b:Bubble):
  if b.processed: return
  b.processed = true
  if b.pos == player.pos:
    pickup_bubble(b)

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
    if walls.get_cell_tile_data(next_pos) != null || is_closed_door(next_pos):
      # bounce on wall
      b.turn()
      return
    var r:Rock = get_rock(next_pos)
    if r != null:
      var next_rock_pos:Vector2i = r.pos + Global.DIRS[dir]
      if can_move_rock(next_rock_pos):
        r.next_dir = dir
        r.next_pos = next_rock_pos
        b.next_state = Bubble.State.IDLE
      else:
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
      if c.state == Bubble.State.MOVING:
        # bounce
        b.turn()
        c.turn()
      else:
        # transfer
        b.next_state = Bubble.State.IDLE
        c.next_state = Bubble.State.MOVING
        c.next_dir = dir
      return

    # continue and check in next tick
    b.next_pos = next_pos

func player_move(dir:int):
  pending_move = true
  tick_player(dir)

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

func create_rock(pos:Vector2i)->Rock:
  var b:Rock = ROCK.instantiate()
  b.set_pos(pos)
  rocks.append(b)
  objects.add_child(b)
  return b

func release_bubble()->void:
  var b:Bubble = player.pop_bubble()
  if b == null: return
  #var b:Bubble = create_bubble(player.pos + Global.DIRS[player.dir], Bubble.Type.WHITE)
  bubbles.append(b)
  b.visible = true
  b.set_pos(player.pos + Global.DIRS[player.dir])
  b.dir = player.dir
  b.state = Bubble.State.MOVING

func init_level():
  walls = get_node('level/walls')
  floor = get_node('level/floor')
  ## objects and start position from walls
  bubbles.clear()
  rocks.clear()
  sensors.clear()
  doors.clear()
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
    elif type == &"rock":
      create_rock(c)
      walls.set_cell(c, -1)
  for n:Node2D in get_tree().get_nodes_in_group(&"sensors"):
    sensors.append(n)
  for n:Node2D in get_tree().get_nodes_in_group(&"doors"):
    doors.append(n)
