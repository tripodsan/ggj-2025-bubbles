class_name Rock
extends Cell

var tween:Tween

func _ready() -> void:
  super()
  is_movable = true
  is_solid = true
  is_heavy = true

func apply():
  if pos == next_pos: return
  pos = next_pos
  dir = next_dir
  if tween: tween.stop()
  tween = create_tween()
  tween.tween_property(self, 'position', Global.grid2cart(pos), Global.tick_speed)

func apply_tick(world:World)->void:
  super(world)
  if state == State.FALLING:
    tween = create_tween()
    tween.tween_property(self, 'scale', Vector2.ZERO, Global.tick_speed)
