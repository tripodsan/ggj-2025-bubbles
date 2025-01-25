class_name Activator
extends Node

@export var targets:Array[Sensor] = []

func _ready():
  for s:Sensor in targets:
    s.activation_change.connect(_on_sensor_activated.bind(s))

func _on_sensor_activated(active:bool, _s:Sensor)->void:
  for s:Sensor in targets:
    if !s.active:
      get_parent().open = false
      return
  get_parent().open = true
