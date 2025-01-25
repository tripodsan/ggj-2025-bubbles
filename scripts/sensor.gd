@tool
class_name Sensor
extends Cell

@onready var visual: AnimatedSprite2D = $visual

enum Type { PLATE, SENSOR_RED, SENSOR_GREEN, SENSOR_BLUE, SENSOR_WHITE }

signal activation_change(active:bool)

var trigger_node:Node2D

@export var active:bool = false:
  set(v):
    active = v
    update_type()

@export var type:Type:
  set(v):
    type = v
    if visual:
      update_type()

func _ready():
  super()
  update_type()

func update_type():
  var str:String = Type.keys()[type].to_lower()
  if active:
    str += '_active'
  visual.animation = str
  visual.stop()

func activate(enable:bool)->void:
  if enable != active:
    active = enable
    activation_change.emit(active)
