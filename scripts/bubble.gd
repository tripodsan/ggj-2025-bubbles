@tool
class_name Bubble
extends Cell

@onready var visual: AnimatedSprite2D = $visual

enum State { IDLE, MOVING, TURNING, ABSORBING, ENTERING, BURSTING }

enum Type { WHITE, RED, GREEN, BLUE }

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

@export
var state:State = State.IDLE: set = set_state

var next_state:State = State.IDLE

var next_child:Bubble

var left:Bubble
var right:Bubble

var immune:Vector2i

var tween:Tween

static func type_from_color(s:String)->Bubble.Type:
  return Bubble.Type.get(s.to_upper(), Bubble.Type.WHITE)

func _ready():
  super()
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

func reset():
  processed = false
  next_pos = pos
  next_dir = dir
  next_state = state
  next_child = null

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
    State.TURNING:
      visual.play(turn_names[(dir + 2) % 4 + type * 4], 1.0 / Global.tick_speed)
    State.BURSTING:
      visual.play(anim_names[type])
  recalc_sub()

func set_type(t:Type)->void:
  type = t
  _queue_update = true

func set_state(s:State)->void:
  if state != s:
    state = s
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
    left.position = Vector2.ZERO
  else:
    right.visible = state != State.ENTERING
    left.position = -Global.DIRS[(dir + 1)%4] * 2
    right.position = Global.DIRS[(dir + 1)%4] * 2

func apply():
  pos = next_pos
  set_dir(next_dir)
  set_state(next_state)
  if tween: tween.stop()
  if state == State.MOVING:
    tween = create_tween()
    tween.tween_property(self, 'position', Global.grid2cart(pos), Global.tick_speed)
  elif state == State.ABSORBING:
    assert(next_child)
    assert(!is_full())
    absorb(next_child)
  else:
    _queue_update = true
  if immune != pos:
    immune = Vector2i.ZERO


## sets the next direction and state to make the bubble turn
func turn()->void:
  next_dir = (dir + 2) % 4
  next_state = State.TURNING

func is_stationary()->bool:
  return state != State.MOVING

## tests if can be merged with other bubble and return the resulting parent
func can_merge(b:Bubble)->Bubble:
  if is_full() && b.is_full(): return null
  if is_stationary():
    return null if is_full() else self
  if b.is_stationary():
    return null if b.is_full() else b
  if b.is_full():
    return self
  if is_full():
    return b
  return self if get_num_children() < b.get_num_children() else b

func merge(b:Bubble)->void:
  next_state = State.ABSORBING
  b.next_state = State.ENTERING
  next_child = b
  if is_stationary():
    next_dir = b.dir

func absorb(b:Bubble)->void:
  if b.get_parent():
    b.reparent(self, false)
  else:
    add_child(b)
  if left == null:
    left = b
  else:
    right = b
  recalc_sub()

func leave()->void:
  state = Bubble.State.MOVING
  next_state = Bubble.State.MOVING
