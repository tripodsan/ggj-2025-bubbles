@tool
class_name Door
extends Cell

@onready var visual: AnimatedSprite2D = $visual

func _ready():
  super()
  is_movable = false
  is_solid = !open
  visual.animation = 'vert' if vertical else 'horz'
  if open:
    visual.play_backwards()
  visual.pause()

@export var vertical:bool:
  set(v):
    vertical = v
    if visual:
      visual.animation = 'vert' if v else 'horz'
      visual.stop()

@export var open:bool:
  set(v):
    if not visual:
      open = v
      return
    if open != v:
      open = v
      is_solid = !open
      if open:
        visual.play()
      else:
        visual.play_backwards()
