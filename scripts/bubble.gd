@tool
class_name Bubble
extends Cell

@onready var visual: AnimatedSprite2D = $visual

enum Type { WHITE, RED, GREEN, BLUE }

var YIELD_RULES:Array[Array] = [
  [0, 0, 2, 3],
  [0, 1, 1, 1],
  [2, 1, 2, 2],
  [3, 1, 2, 3]
]

var anim_names = [
  "l_white",
  "l_red",
  "l_green",
  "l_blue",
  "s_white",
  "s_red",
  "s_green",
  "s_blue"
]

var turn_names = [
  "b_white_e",
  "b_white_s",
  "b_white_w",
  "b_white_n",
  "b_red_e",
  "b_red_s",
  "b_red_w",
  "b_red_n",
  "b_green_e",
  "b_green_s",
  "b_green_w",
  "b_green_n",
  "b_blue_e",
  "b_blue_s",
  "b_blue_w",
  "b_blue_n",
]

@export
var type:Type = Type.WHITE: set = set_type

var next_child:Bubble

var left:Bubble
var right:Bubble

# special flag when 2 bubbles bounce over the same cell
var half_step:bool = false

var tween:Tween

static func type_from_color(s:String)->Bubble.Type:
  return Bubble.Type.get(s.to_upper(), Bubble.Type.WHITE)

func _ready():
  super()
  is_movable = false
  is_solid = false
  is_heavy = false
  can_push = true

  register_child_bubbles()
  _queue_update = true

func _notification(what: int) -> void:
  if what == NOTIFICATION_CHILD_ORDER_CHANGED and Engine.is_editor_hint():
    register_child_bubbles()
    _queue_update = true

func register_child_bubbles():
  left = null
  right = null
  for n:Node2D in get_children():
    if n is Bubble:
      if left == null: left = n
      else: right = n

func _process(_d)->void:
  if !_queue_update: return
  _queue_update = false
  if !visual: return
  match state:
    State.IDLE, State.MOVING, State.ABSORBING:
      visual.animation = anim_names[type]
      visual.stop()
    State.ENTERING:
      visual.animation = anim_names[type + 4]
      visual.stop()
    State.BOUNCING, State.PUSHING, State.PULSING:
      visual.play(turn_names[(dir + 2) % 4 + type * 4], 1.0 / Global.tick_speed)
      # add hack for missing bouncing anim
      if half_step:
        visual.animation_finished.connect(reset_half, CONNECT_ONE_SHOT)
    State.BURSTING:
      visual.play(anim_names[type])
  visual.position = -Global.DIRS[dir] * 8 if half_step else Vector2.ZERO
  recalc_sub()

func reset_half()->void:
  half_step = false
  visual.position = Vector2.ZERO
  recalc_sub()

func set_type(t:Type)->void:
  type = t
  _queue_update = true

func is_full()->bool:
  return right != null

func get_num_children()->int:
  if left == null: return 0
  return 1 if right == null else 2

func recalc_sub()->void:
  if left == null: return
  left.visible = state != State.ENTERING
  if right == null:
    # hide children if we are inside a bubble
    left.position = -Global.DIRS[dir] * 8 if half_step else Vector2.ZERO
  else:
    right.visible = state != State.ENTERING
    left.position = -Global.DIRS[(dir + 1)%4] * 2 - (Global.DIRS[dir] * 8 if half_step else Vector2i.ZERO)
    right.position = Global.DIRS[(dir + 1)%4] * 2 - (Global.DIRS[dir] * 8 if half_step else Vector2i.ZERO)

func tick_prepare(world:World)->void:
  if state == State.BOUNCING || state == State.ABSORBING:
    state = State.MOVING
  super(world)
  next_child = null
  half_step = false

  # check if bubble is on a spike
  if (state != State.BURSTING) && world.get_type(pos) == &"spike":
    next_state = Bubble.State.BURSTING
    processed = true

func get_precedence(b0:Bubble, b1:Bubble)->Bubble:
  var d:int = YIELD_RULES[b0.next_dir][b1.next_dir]
  return b0 if b0.next_dir == d else b1

func tick(world:World)->void:
  if next_state == State.BURSTING && !processed:
    tick_burst(world)
    return
  super(world)

func tick_push(world:World, c:Cell)->bool:
  var ret:bool = super(world, c)
  if ret:
    tick_stop()
    next_dir = (dir + 2) % 4
    next_state = State.PUSHING
  return ret

func tick_turn(world:World)->void:
  var ct:int = int(world.get_color_type(pos))
  next_dir = world.corner_matrix[ct][dir]
  if next_dir != dir:
    next_state = State.TURNING

func tick_burst(world:World)->void:
  processed = true
  next_state = State.REMOVED
  if left == null: return
  var l = left
  left = null
  l.processed = false
  world.dispatch_bubble(l)
  l.leave(pos)
  if right == null:
    # only 1 bubble
    l.dir = dir
    l.next_dir = dir
    l.tick_move(world)
  else:
    var r = right
    r.processed = false
    world.dispatch_bubble(r)
    r.leave(pos)
    var tick_dir = int(world.get_color_type(pos))
    # if hit opposite:
    if dir == (tick_dir + 2) % 4:
      l.dir = (dir + 3) % 4
      l.next_dir = l.dir
      r.dir = (dir + 1) % 4
      r.next_dir = r.dir
    else:
      if (tick_dir + dir) % 4 < 2:
        l.dir = dir
        l.next_dir = l.dir
        r.dir = tick_dir
        r.next_dir = r.dir
      else:
        r.dir = dir
        r.next_dir = r.dir
        l.dir = tick_dir
        l.next_dir = l.dir
    l.tick_move(world)
    r.tick_move(world)

func apply_tick(world):
  prints(name, next_state, next_pos)
  # don't call super, as we don't want to set_pos auto update
  var moved:bool = pos != next_pos && (next_state == State.MOVING || next_state == State.ABSORBING)
  set_pos(pos)
  pos = next_pos
  set_dir(next_dir)
  set_state(next_state)
  if tween: tween.stop()
  if moved:
    tween = create_tween()
    tween.tween_property(self, 'position', Global.grid2cart(pos), Global.tick_speed)
  if state == State.ABSORBING:
    _absorb()
  else:
    _queue_update = true

## sets the next direction and state to make the bubble turn
func tick_bounce(other:Cell)->void:
  super(other)
  next_dir = (dir + 2) % 4
  next_state = State.BOUNCING
  if other && other.next_state == State.MOVING:
    other.tick_bounce(null)
    other.processed = true
    if other.next_pos == next_pos:
      half_step = true
  elif other is Bubble && other.next_state == State.IDLE:
    next_dir = (dir + 2) % 4
    next_state = State.PUSHING
    other.next_dir = dir
    other.next_state = State.PULSING
    ##half_step = true

func is_stationary()->bool:
  return state != State.MOVING

## tests if can be merged with other bubble and return the resulting parent
func can_merge(other:Cell)->Cell:
  var b:Bubble = other as Bubble
  if !b: return other.can_merge(self)
  if is_full() && b.is_full(): return null
  if is_stationary():
    return null if is_full() else self
  if b.is_stationary():
    return null if b.is_full() else b
  if b.is_full():
    return self
  if is_full():
    return b
  if get_num_children() == b.get_num_children():
    return get_precedence(self, b)
  return self if get_num_children() < b.get_num_children() else b

func tick_merge(c:Cell)->void:
  assert(c is Bubble)
  next_state = State.ABSORBING
  c.processed = true
  c.next_state = State.ENTERING
  next_child = c
  if is_stationary():
    next_dir = c.dir

func _absorb()->void:
  assert(next_child)
  assert(!is_full())
  if next_child.get_parent():
    next_child.reparent(self, false)
  else:
    add_child(next_child)
  if left == null:
    left = next_child
  else:
    right = next_child
  next_child = null
  recalc_sub()

func leave(p:Vector2i)->void:
  state = State.MOVING
  next_state = State.MOVING
  set_pos(p)
  next_pos = p
