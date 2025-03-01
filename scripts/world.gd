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
  #tick()

func tick():
  ticks += 1
  prints(ticks)

  for c in cells.duplicate():
    if c.state == Cell.State.REMOVED:
      c.queue_free()
      cells.erase(c)
    elif c.state == Cell.State.ENTERING:
      cells.erase(c)
    else:
      c.tick_prepare(self)

  for c in cells:
    c.tick_move(self)

  var st:int = 0
  while not all_processed():
    print(ticks, '.', st)
    st += 1
    for c in cells:
      c.tick(self)

  check_sensors()

  for c in cells:
    c.apply_tick(self)

  check_goal()

func check_sensors():
  for c in cells:
    var s:Sensor = get_sensor(c.next_pos)
    if !s: continue
    if s.type == Sensor.Type.PLATE && c.is_heavy:
      s.trigger_node = c
      s.activate(true)
    elif c is Bubble && (s.type == c.type || s.type == Sensor.Type.SENSOR_WHITE) && s.trigger_node != c:
      s.trigger_node = c
      s.toggle()

  for s in sensors:
    if s.trigger_node && s.trigger_node.next_pos != s.pos:
      if s.type == Sensor.Type.PLATE:
        s.activate(false)
      s.trigger_node = null

func all_processed()->bool:
  for c in cells:
    if !c.processed: return false
  return true

func goal_reached():
  await get_tree().create_timer(0.5).timeout
  Global.level_complete.emit()


func check_goal():
  var type:StringName = get_type(player.pos)
  if type == &"goal":
    walls.set_cell(player.pos, -1)
    goal_reached()
    return

func is_ground(pos:Vector2i)->bool:
  var c:TileData = floor.get_cell_tile_data(pos)
  if c == null: return false
  return c.get_custom_data("type") == &"ground"

func get_sensor(pos:Vector2i)->Sensor:
  for s:Sensor in sensors:
    if s.pos == pos: return s
  return null

func get_next_cells(pos:Vector2i, ignored:Cell)->Array[Cell]:
  var found:Array[Cell] = []
  for c:Cell in cells:
    # ignore open door
    if c is Door and c.open: continue
    # ignore removed or bursting cells
    if c.state == Cell.State.REMOVED || c.state == Cell.State.BURSTING: continue
    if c != ignored && c.next_pos == pos:
      found.append(c)
  return found

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
  #if get_rock(pos): return
  #if is_closed_door(pos): return

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

## called when bubble is dispatch from its parent
func dispatch_bubble(b:Bubble)->void:
  cells.append(b)
  b.reparent(objects)
  b.visible = true

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
    if n.visible:
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
