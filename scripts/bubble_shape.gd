@tool
extends Node2D

var points:PackedVector2Array = []

@export_tool_button("redraw") var redraw_action = update

@export var details:int = 32

@export var radius:float = 30

@export var color:Color = Color.RED
@export var fill_color:Color = Color.RED

var time:float

var ph0:float
var ph1:float
var ph2:float

func _init()->void:
  time = randf() * TAU
  ph0 = randf() * TAU
  ph1 = randf() * TAU
  ph2 = randf() * TAU
  update()

func _process(delta:float):
  time += delta
  queue_redraw()

func update()->void:
  ph0 = randf() * TAU
  ph1 = randf() * TAU
  ph2 = randf() * TAU
  queue_redraw()
  pass

func _draw() -> void:
  #draw_circle(Vector2.ZERO, 28, Color.RED, false, 5, true)
  points.resize(details + 1)
  var tim := time * 3.0
  for i in range(details):
    var t = float(i) * TAU / float(details)
    var r = 1 + cos(2*t + ph0) * sin(1 * tim) * 0.1
    r += 1 + cos(3*t + ph1) * sin(1 * tim) * 0.1 / 2.0
    r += 1 + cos(5*t + ph2) * sin(1 * tim) * 0.1 / 3.0
    r *= radius / 3.0
    points[i] = Vector2(r * cos(t), r*sin(t))
  points[details] = points[0]
  draw_polyline(points, color, 3.0, true)
  draw_colored_polygon(points, fill_color)
