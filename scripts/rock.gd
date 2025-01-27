class_name Rock
extends Cell

var tween:Tween

func apply():
  if pos == next_pos: return
  pos = next_pos
  dir = next_dir
  if tween: tween.stop()
  tween = create_tween()
  tween.tween_property(self, 'position', Global.grid2cart(pos), Global.tick_speed)
