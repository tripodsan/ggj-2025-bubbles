@tool
class_name Door
extends Cell

@onready var visual: AnimatedSprite2D = $visual

func _ready():
  super()
  visual.animation = 'vert' if vertical else 'horz'
  visual.stop()

@export var vertical:bool:
  set(v):
    vertical = v
    if Engine.is_editor_hint():
      visual.animation = 'vert' if v else 'horz'
      visual.stop()

@export var open:bool:
  set(v):
    if not visual: return
    if open != v:
      open = v
      if open:
        visual.play()
      else:
        visual.play_backwards()
