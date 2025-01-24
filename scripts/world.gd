class_name World
extends Node2D

const BUBBLE = preload('res://bubble.tscn')

@onready var player: Player = %player
@onready var objects: Node2D = %objects

@onready var floor: TileMapLayer = $level/floor
@onready var walls: TileMapLayer = $level/walls

var tick_speed:float = 0.5

var bubbles:Array[Bubble] = []

var time:float = 0
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
  for b in bubbles:
    if b.is_moving:
      bubble_move(b)
  for b in bubbles:
    b.apply(tick_speed)

func get_bubble(pos:Vector2i)->Bubble:
  for b:Bubble in bubbles:
    if b.pos == pos: return b
  return null

func bubble_move(b:Bubble):
  var dir:int = b.dir
  var pos:Vector2i = b.pos + Global.DIRS[dir]

  if walls.get_cell_tile_data(pos) != null:
    # bounce
    dir = (dir + 2) % 4
    pos = b.pos + Global.DIRS[dir]

  var c:Bubble = get_bubble(pos)
  if c:
    if c.merge(b):
      bubbles.erase(b)
      return
    else:
      dir = (b.dir + 2) % 4
      pos = b.pos + Global.DIRS[dir]
  b.dir = dir
  b.next_pos = pos

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

func create_bubble(pos:Vector2i)->Bubble:
  var b:Bubble = BUBBLE.instantiate()
  b.set_pos(pos)
  bubbles.append(b)
  objects.add_child(b)
  return b

func release_bubble()->void:
  var b:Bubble = create_bubble(player.pos + Global.DIRS[player.dir])
  b.dir = player.dir
  b.is_moving = true

func init_level():
  ## objects and start position from walls
  for c:Vector2i in walls.get_used_cells():
    var d:TileData = walls.get_cell_tile_data(c)
    var type:StringName = d.get_custom_data("type")
    if type == &"start":
      player.pos = c
      walls.set_cell(c, -1)
    elif type == &"bubble":
      create_bubble(c)
      walls.set_cell(c, -1)
