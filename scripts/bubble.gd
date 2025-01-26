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

var type:Type = Type.WHITE

var state:State = State.IDLE

var next_state:State = State.IDLE

var next_child:Bubble

var left:Bubble
var right:Bubble
var immune:Vector2i

@onready var sub: Node2D = $sub

var tween:Tween

static func type_from_color(s:String)->Bubble.Type:
  return Bubble.Type.get(s.to_upper(), Bubble.Type.WHITE)

func _ready() -> void:
  set_type(type)

func reset():
  processed = false
  next_pos = pos
  next_dir = dir
  next_state = state
  next_child = null

func set_dir(v:int):
  dir = v
  sub.rotation_degrees = dir * 90

func set_type(t:Type)->void:
  type = t
  var offset:int = 4 if state == State.ENTERING else 0
  if visual:
    visual.animation = anim_names[t + offset]
    visual.stop()

func move_to(v:Vector2):
  pos = v

func is_full()->bool:
  return right != null

func get_num_children()->int:
  if left == null: return 0
  return 1 if right == null else 2

func recalc_sub()->void:
  if left == null: return
  if right == null:
    left.position = Vector2.ZERO
  else:
    left.position = Vector2(0, -2)
    right.position = Vector2(0, 2)

func apply(speed:float):
  pos = next_pos
  set_dir(next_dir)
  state = next_state
  #prints(State.keys()[state])
  #visual.position = Vector2.ZERO if state == State.ENTERING else Global.DIRS[dir] * 1.0
  if tween: tween.stop()
  if state == State.MOVING:
    tween = create_tween()
    tween.tween_property(self, 'position', Global.grid2cart(pos), speed)
  elif state == State.ABSORBING:
    assert(next_child)
    assert(!is_full())
    absorb(next_child)
  elif state == State.ENTERING:
    set_type(type)

  if state == State.TURNING:
    visual.play(turn_names[(dir + 2) % 4 + type * 4], 1.5)
  elif state == State.BURSTING:
    prints('play ', anim_names[type])
    visual.play(anim_names[type])
  else:
    set_type(type)
  if immune != pos:
    immune = Vector2i.ZERO


## sets the next direction and state to make the bubble turn
func turn()->void:
  next_dir = (dir + 2) % 4
  next_state = State.TURNING

func is_stationary()->bool:
  return state == State.IDLE or state == State.TURNING

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
    b.reparent(sub, false)
  else:
    sub.add_child(b)
  b.scale = Vector2.ONE
  b.sub.visible = false
  if left == null:
    left = b
  else:
    right = b
  recalc_sub()

func leave()->void:
  state = Bubble.State.MOVING
  next_state = Bubble.State.MOVING
  scale = Vector2.ONE
  rotation_degrees = 0
  sub.rotation_degrees = 0
  sub.visible = true
