class_name World
extends Node2D

const BUBBLE = preload('res://bubble.tscn')
const ROCK = preload('res://rock.tscn')

@onready var player: Player = %player

var objects: Node2D

@onready var floor: TileMapLayer = $level/floor
@onready var walls: TileMapLayer = $level/walls

var tick_speed:float = 0.4

var bubbles:Array[Bubble] = []

var rocks:Array[Rock] = []

var sensors:Array[Sensor] = []

var doors:Array[Door] = []

var time:float = 0

var ticks:int = 0

var pending_move:bool = false

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

func goal_reached():
  await get_tree().create_timer(0.5).timeout
  Global.level_complete.emit()


func tick_player(dir:int):
  var pos:Vector2 = player.pos + Global.DIRS[dir]
  var type:StringName = get_type(pos)
  if type == &"goal":
    walls.set_cell(pos, -1)
    player.dir = dir
    player.pos = pos
    goal_reached()

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
  if player.push_bubble(b):
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
  if get_rock(pos): return
  return true

func get_rock(pos:Vector2i)->Rock:
  for r:Rock in rocks:
    if r.pos == pos: return r
  return null

func get_next_bubble(pos:Vector2i, ignored:Bubble)->Bubble:
  for b:Bubble in bubbles:
    if b != ignored && b.next_pos == pos: return b
  return null

func burst_bubble(b:Bubble)->void:
  bubbles.erase(b)
  b.queue_free()
  if b.left == null: return
  var l = b.left
  l.processed = false
  l.reparent(objects)
  l.leave()
  l.set_pos(b.pos)
  l.immune = b.pos
  bubbles.append(l)
  if b.right == null:
    # only 1 bubble
    l.dir = b.dir
    l.next_dir = b.dir
    tick(l)
  else:
    var r = b.right
    r.processed = false
    r.reparent(objects)
    r.leave()
    r.set_pos(b.pos)
    r.immune = b.pos
    bubbles.append(r)
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

    tick(r)
    tick(l)

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
      b.next_dir = corner_matrix[ct][b.dir]
      b.next_pos = b.pos + Global.DIRS[b.next_dir]
      return
    # check if another bubble is on this pos
    var c:Bubble = get_bubble(b.pos, b)
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
  if !d: return &""
  var type:StringName = d.get_custom_data("type")
  return &"wall" if type == &"" else type

func get_color_type(pos:Vector2i)->StringName:
  var d:TileData = walls.get_cell_tile_data(pos)
  if !d: return &""
  return d.get_custom_data("color")

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
  var pos = player.pos + Global.DIRS[player.dir]
  var type:StringName = get_type(pos)
  if type != &"" and type != &"spike": return
  if get_rock(pos): return
  if is_closed_door(pos): return

  var b:Bubble = player.pop_bubble()
  if b == null: return
  bubbles.append(b)
  b.visible = true
  b.set_pos(pos)
  b.set_dir(player.dir)
  b.state = Bubble.State.MOVING


func bubble_tree(outer:bool, tree:Dictionary)->Bubble:
  var color = tree['color']
  var children = tree['children']
  var size = children.size()
  var b0:Bubble = BUBBLE.instantiate()
  b0.set_type(color)
  if outer:
    #b.set_pos(pos)
    bubbles.append(b0)
    objects.add_child(b0)
  if size == 1:
    var b1:Bubble = bubble_tree(false, children[0])
    b1.state = Bubble.State.ENTERING
    b0.absorb(b1)
  if size == 2:
    var b1:Bubble = bubble_tree(false, children[0])
    b1.state = Bubble.State.ENTERING
    b0.absorb(b1)
    var b2:Bubble = bubble_tree(false, children[1])
    b2.state = Bubble.State.ENTERING
    b0.absorb(b2)
  return b0

func complex_bubble(pos:Vector2i, tree:Dictionary)->Bubble:
  var b:Bubble = bubble_tree(true, tree)
  b.set_pos(pos)
  return b

func init_level():
  walls = get_node('level/walls')
  floor = get_node('level/floor')
  ## objects and start position from walls
  bubbles.clear()
  rocks.clear()
  sensors.clear()
  doors.clear()
  player.reset()
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
    elif type == &"bubble_2":
      complex_bubble(c, {
        "color": Bubble.Type.WHITE,
        "children": [
          {
            "color": Bubble.Type.RED,
            "children": []
          }, {
            "color": Bubble.Type.WHITE,
            "children": []
          }
        ]
      })
      walls.set_cell(c, -1)
    elif type == &"bubble_3":
      complex_bubble(c, {
        "color": Bubble.Type.WHITE,
        "children": [
          {
            "color": Bubble.Type.RED,
            "children": []
          }, {
            "color": Bubble.Type.GREEN,
            "children": []
          }
        ]
      })
      walls.set_cell(c, -1)
    elif type == &"db_left":
      complex_bubble(c, {
        "color": Bubble.Type.GREEN,
        "children": [
          {
            "color": Bubble.Type.BLUE,
            "children": []
          }, {
            "color": Bubble.Type.BLUE,
            "children": []
          }
        ]
      })
      walls.set_cell(c, -1)
    elif type == &"db_down":
      complex_bubble(c, {
        "color": Bubble.Type.GREEN,
        "children": [
          {
            "color": Bubble.Type.BLUE,
            "children": []
          }, {
            "color": Bubble.Type.BLUE,
            "children": []
          }
        ]
      })
      walls.set_cell(c, -1)
    elif type == &"db_right":
      complex_bubble(c, {
        "color": Bubble.Type.GREEN,
        "children": [
          {
            "color": Bubble.Type.BLUE,
            "children": []
          }, {
            "color": Bubble.Type.BLUE,
            "children": []
          }
        ]
      })
      walls.set_cell(c, -1)
    elif type == &"db_up":
      complex_bubble(c, {
        "color": Bubble.Type.GREEN,
        "children": [
          {
            "color": Bubble.Type.BLUE,
            "children": []
          }, {
            "color": Bubble.Type.BLUE,
            "children": []
          }
        ]
      })
      walls.set_cell(c, -1)
    elif type == &"rock":
      create_rock(c)
      walls.set_cell(c, -1)
  for n:Node2D in get_tree().get_nodes_in_group(&"sensors"):
    sensors.append(n)
  for n:Node2D in get_tree().get_nodes_in_group(&"doors"):
    doors.append(n)
