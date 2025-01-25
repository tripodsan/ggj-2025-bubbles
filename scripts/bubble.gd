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

var type:Type = Type.WHITE

var state:State = State.IDLE

var next_state:State = State.IDLE

var next_children:Array[Bubble] = []

var max_children:int = 1

@onready var sub: Node2D = $sub

var tween:Tween

static func type_from_color(s:String)->Bubble.Type:
  return Bubble.Type.get(s.to_upper(), Bubble.Type.WHITE)

func reset():
  processed = false
  next_pos = pos
  next_dir = dir
  next_state = state

func set_dir(v:int):
  dir = v
  #visual.rotation_degrees = dir * 90

func set_type(t:Type)->void:
  type = t
  var offset:int = 4 if state == State.ENTERING else 0
  $visual.animation = anim_names[t + offset]

func move_to(v:Vector2):
  pos = v

func is_full()->bool:
  return sub.get_child_count() >= max_children

func get_num_children()->int:
  return sub.get_child_count()

func apply(speed:float):
  pos = next_pos
  dir = next_dir
  state = next_state
  prints(State.keys()[state])
  visual.position = Vector2.ZERO if state == State.ENTERING else Global.DIRS[dir] * 1.0
  if tween: tween.stop()
  if state == State.MOVING:
    tween = create_tween()
    tween.tween_property(self, 'position', Global.grid2cart(pos), speed - 0.2)
  elif state == State.ABSORBING:
    for b in next_children:
      b.reparent(sub, true)
      b.position = Vector2.ZERO
      b.scale = Vector2.ONE
  elif state == State.ENTERING:
    set_type(type)


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
  assert(get_num_children() < max_children)
  next_state = State.ABSORBING
  b.next_state = State.ENTERING
  next_children.append(b)
  if is_stationary():
    next_dir = b.dir
