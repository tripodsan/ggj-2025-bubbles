class_name World
extends Node2D

const BUBBLE = preload('res://bubble.tscn')
const ROCK = preload('res://rock.tscn')

@onready var player: Player = %player

var objects: Node2D

@onready var floor: TileMapLayer = $level/floor
@onready var walls: TileMapLayer = $level/walls

var cells:Array[Cell] = []

var sensors:Array[Sensor] = []

var time:float = 0

var ticks:int = 0

var corner_matrix = [
  [1, 1, 2, 2],
  [3, 2, 2, 3],
  [0, 0, 3, 3],
  [0, 1, 1, 0]
]

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
    shoot_bubble()
  if event.is_action_pressed('wait'):
    tick()

func player_move(dir:int):
  player.input_dir = dir
  tick()


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
  if time < Global.tick_speed: return
  time -= Global.tick_speed
  #do_tick()

func tick():
  ticks += 1
  prints(ticks)
  for c in cells:
    if c.state == Cell.State.REMOVED:
      c.queue_free()
      cells.erase(c)
    else:
      c.prepare_tick(self)

  for c in cells:
    c.tick_move(self)

  for c in cells:
    c.tick(self)

  for c in cells:
    c.apply_tick(self)

  check_goal()
#func update_sensors():
  #for r in rocks:
    #var s:Sensor = get_sensor(r.pos)
    #if s && s.type == Sensor.Type.PLATE:
      #s.trigger_node = r
      #s.activate(true)
  #for b in bubbles:
    #var s:Sensor = get_sensor(b.pos)
    #if s:
      #if s.type == b.type || s.type == Sensor.Type.SENSOR_WHITE:
        #s.toggle()
#
  #for s in sensors:
    #if s.active && s.trigger_node && s.trigger_node.pos != s.pos:
      #s.activate(false)
      #s.trigger_node = null



func goal_reached():
  await get_tree().create_timer(0.5).timeout
  Global.level_complete.emit()


func check_goal():
  var type:StringName = get_type(player.pos)
  if type == &"goal":
    walls.set_cell(player.pos, -1)
    goal_reached()
    return

  #if walls.get_cell_tile_data(pos) != null: return
  #if !is_ground(pos): return
  #if is_closed_door(pos): return
  #var r:Rock = get_rock(pos)
  #if r != null:
    #var next_rock_pos:Vector2i = r.pos + Global.DIRS[dir]
    #if !can_move_rock(next_rock_pos): return
    #if get_bubble(next_rock_pos, null): return
    #r.set_pos(next_rock_pos)
  #var b:Bubble = get_bubble(pos, null)
  #if b:
    #pickup_bubble(b)

  #player.dir = dir
  #player.pos = pos

func is_ground(pos:Vector2i)->bool:
  var c:TileData = floor.get_cell_tile_data(pos)
  if c == null: return false
  return c.get_custom_data("type") == &"ground"

func get_sensor(pos:Vector2i)->Sensor:
  for s:Sensor in sensors:
    if s.pos == pos: return s
  return null

func is_closed_door(pos:Vector2i)->bool:
  #for s:Door in doors:
    #if s.pos == pos: return !s.open
  return false

func get_cell(pos:Vector2i, ignored:Cell)->Cell:
  var found:Cell = null
  for c:Cell in cells:
    if c != ignored && c.pos == pos:
      if !found || found is Door: # ignore door, if something else on top
        found = c
  return found

func get_next_cell(pos:Vector2i, ignored:Cell)->Cell:
  var found:Cell = null
  for c:Cell in cells:
    if c != ignored && c.next_pos == pos:
      if !found || found is Door: # ignore door, if something else on top
        found = c
  return found

func can_move_rock(pos:Vector2i)->bool:
  if walls.get_cell_tile_data(pos) != null: return false
  if is_closed_door(pos): return false
  if get_rock(pos): return false
  #if get_bubble(pos, null): return false
  return true

func get_rock(pos:Vector2i)->Rock:
  #for r:Rock in rocks:
    #if r.pos == pos: return r
  return null

func get_next_bubble(pos:Vector2i, ignored:Bubble)->Bubble:
  #for b:Bubble in bubbles:
    #if b != ignored && b.next_pos == pos: return b
  return null

func burst_bubble(b:Bubble)->void:
  cells.erase(b)
  b.queue_free()
  if b.left == null: return
  var l = b.left
  l.processed = false
  l.reparent(objects)
  l.leave()
  l.set_pos(b.pos)
  l.immune = b.pos
  cells.append(l)
  if b.right == null:
    # only 1 bubble
    l.dir = b.dir
    l.next_dir = b.dir
    _old_tick(l)
  else:
    var r = b.right
    r.processed = false
    r.reparent(objects)
    r.leave()
    r.set_pos(b.pos)
    r.immune = b.pos
    cells.append(r)
    var tick_dir = int(get_color_type(b.pos))
    # if hit opposite:
    if b.dir == (tick_dir + 2) % 4:
      l.dir = (b.dir + 3) % 4
      l.next_dir = l.dir
      r.dir = (b.dir + 1) % 4
      r.next_dir = r.dir
    else:
      if (tick_dir + b.dir) % 4 < 2:
        l.dir = b.dir
        l.next_dir = l.dir
        r.dir = tick_dir
        r.next_dir = r.dir
      else:
        r.dir = b.dir
        r.next_dir = r.dir
        l.dir = tick_dir
        l.next_dir = l.dir
    _old_tick(r)
    _old_tick(l)

func _old_tick(b:Bubble):
  if b.processed: return
  b.processed = true
  #if b.pos == player.pos:
    #pickup_bubble(b)

  if b.state == Bubble.State.IDLE:
    return
  if b.state == Bubble.State.ABSORBING:
    b.state = Bubble.State.MOVING
    b.next_state = Bubble.State.MOVING
  if b.state == Bubble.State.TURNING:
    b.state = Bubble.State.MOVING
    b.next_state = Bubble.State.MOVING
  if b.state == Bubble.State.BURSTING:
    burst_bubble(b)
    return
  if b.state == Bubble.State.MOVING:
    # check if the bubble is on a spike
    var type:StringName = get_type(b.pos)
    if type == &"spike" && b.immune != b.pos:
      b.next_state = Bubble.State.BURSTING
      return
    # check for corner
    if type == &"corner":
      # todo: add turn animation and extra tick
      var ct:int = int(get_color_type(b.pos))
      #b.next_dir = corner_matrix[ct][b.dir]
      #b.next_pos = b.pos + Global.DIRS[b.next_dir]
      b.dir = corner_matrix[ct][b.dir]
      b.next_dir = b.dir
      #return
    # check if another bubble is on this pos
    var c:Bubble = get_cell(b.pos, b)
    if c && b.immune != b.pos:
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
    type = get_type(next_pos)
    if type == &"spike":
      # handle bursting in the next tick
      b.next_pos = next_pos
      return
    if type == &"corner":
      # handle corner in the next tick
      b.next_pos = next_pos
      return

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
        if b.immune == b.pos:
          b.immune = Vector2i.ZERO
          b.next_state = Bubble.State.BURSTING
        else:
          b.next_state = Bubble.State.IDLE
      else:
        b.turn()
      return

    c = get_cell(next_pos, b)
    if c == null:
      b.next_pos = next_pos
      return

    if !c.processed:
      _old_tick(c)
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

func get_type(pos:Vector2i)->StringName:
  var d:TileData = walls.get_cell_tile_data(pos)
  if !d: return &""
  var type:StringName = d.get_custom_data("type")
  return &"wall" if type == &"" else type

func get_color_type(pos:Vector2i)->StringName:
  var d:TileData = walls.get_cell_tile_data(pos)
  if !d: return &""
  return d.get_custom_data("color")


func shoot_bubble()->void:
  var pos = player.pos + Global.DIRS[player.dir]
  var type:StringName = get_type(pos)
  if type != &"" and type != &"spike" and type != &"corner": return
  if get_rock(pos): return
  if is_closed_door(pos): return

  var b:Bubble = player.pop_bubble()
  if b == null: return
  cells.append(b)
  b.visible = true
  b.set_pos(pos)
  b.set_dir(player.dir)
  b.state = Bubble.State.MOVING
  var s:Sensor = get_sensor(b.pos)
  if s && (s.type == b.type || s.type == Sensor.Type.SENSOR_WHITE):
    s.toggle()

# --- level init -----------------------------------------------------------------------

func create_bubble(pos:Vector2i, type:Bubble.Type)->Bubble:
  var b:Bubble = BUBBLE.instantiate()
  b.set_pos(pos)
  b.set_type(type)
  cells.append(b)
  objects.add_child(b)
  return b

func create_rock(pos:Vector2i)->Rock:
  var b:Rock = ROCK.instantiate()
  b.set_pos(pos)
  cells.append(b)
  objects.add_child(b)
  return b

func init_level():
  walls = get_node('level/walls')
  floor = get_node('level/floor')
  cells.clear()
  # make player the first cell
  cells.append(player)
  sensors.clear()
  player.reset()

  for n:Cell in get_tree().get_nodes_in_group(&"cells"):
    if n is Bubble && n.state == Bubble.State.ENTERING:
      # ignore sub-bubble
      continue;
    cells.append(n)
  for n:Sensor in get_tree().get_nodes_in_group(&"sensors"):
    sensors.append(n)

  for c:Vector2i in walls.get_used_cells():
    var d:TileData = walls.get_cell_tile_data(c)
    var type:StringName = d.get_custom_data("type")
    var color:Bubble.Type = Bubble.type_from_color(d.get_custom_data("color"))
    if type == &"start":
      player.set_pos(c)
      walls.set_cell(c, -1)
    elif type == &"bubble":
      create_bubble(c, color)
      walls.set_cell(c, -1)
    elif type == &"rock":
      create_rock(c)
      walls.set_cell(c, -1)
