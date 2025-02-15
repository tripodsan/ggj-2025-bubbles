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

var immune:Vector2i

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
    State.BOUNCING:
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

func get_precedence(b0:Bubble, b1:Bubble)->Bubble:
  var d:int = YIELD_RULES[b0.next_dir][b1.next_dir]
  return b0 if b0.next_dir == d else b1


func tick_push(c:Cell)->void:
  super(c)
  tick_stop()

func tick_impulse(world:World, c:Cell)->void:
  # check if the movable can be pushed to the new place
  c.next_pos  = c.pos + Global.DIRS[next_dir]
  c.next_dir = next_dir
  c.processed = true
  if c is Bubble:
    c.next_state = State.MOVING
  tick_stop()
  if c.is_blocked(world, c.next_pos):
    c.tick_stop()
    #bounce()
    return
  # check if this is a bubble pushed into the player
  var nc:Cell = world.get_next_cell(c.next_pos, c)
  if c is Bubble and nc is Player:
    if not (nc as Player).tick_pickup(world, c):
      # if the player can't pickup the pushed bubble, block and bounce
      c.tick_stop()
      #bounce()

## special tick for bubble, because it is so special
func _tick(world:World)->void:
  #if processed: return
  #processed = true
  if state == State.MOVING:
    var c:Cell = world.get_next_cell(next_pos, self)
    if !c:
      c = get_swap(world)
      if c is Bubble:
        var wb:Bubble = can_merge(c)
        if wb == null:
          tick_stop()
          #bounce()
          c.tick_stop()
          c.bounce()
        elif wb == self:
          tick_merge(c)
        else:
          c.tick_merge(self)
      return

    c.processed = true
    # special case: player
    if c is Player:
      (c as Player).tick_pickup(world, self)
      return
    if c is Bubble:
      # check winning bubble
      var wb:Bubble = can_merge(c)
      if wb == null:
        if c.is_stationary():
          tick_impulse(world, c)
        elif (self.next_dir + 2) % 4 == c.next_dir: # bounce both if opposite
          tick_stop()
          #bounce(true)
          c.tick_stop()
          c.bounce(true)
        else:
          wb = get_precedence(self, c)
          # get other
          wb = self if wb == c else c
          wb.tick_stop()
          wb.bounce()
      elif wb == self:
        tick_merge(c)
      else:
        c.tick_merge(self)
      return

    if c.state == State.MOVING:
      # should not happen. no other moving cells
      return
    if c.is_movable:
      tick_impulse(world, c)
      return

    #bounce()


func apply_tick(world):
  prints(name, next_state, next_pos)
  # don't call super, as we don't want to set_pos auto update
  var moved:bool = pos != next_pos && (next_state == State.MOVING || next_state == State.ABSORBING)
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
  if immune != pos:
    immune = Vector2i.ZERO


## sets the next direction and state to make the bubble turn
func tick_bounce(other:Cell)->void:
  next_dir = (dir + 2) % 4
  next_state = State.BOUNCING
  if other && other.next_state == State.MOVING:
    other.tick_stop()
    other.tick_bounce(null)
    other.processed = true
    #half_step = true

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

func leave()->void:
  state = Bubble.State.MOVING
  next_state = Bubble.State.MOVING
