class_name Global
extends Node

const GRID_DX := 16
const GRID_DX2 := 8
const GRID_DY := 16
const GRID_DY2 := 8

const GRID_SIZE := Vector2(GRID_DX, GRID_DY)

enum DIR { RIGHT, DOWN, LEFT, UP }

const DIRS = [
  Vector2i(1, 0),  # right
  Vector2i(0, 1),  # down
  Vector2i(-1, 0), # left
  Vector2i(0, -1), # up
]

static func grid2cart(pos:Vector2i)->Vector2:
  return Vector2(pos.x * GRID_DX + GRID_DX2, pos.y * GRID_DY + GRID_DY2)

static func cart2grid(pos:Vector2)->Vector2i:
  return Vector2i((pos.x - GRID_DX2) / GRID_DX, (pos.y - GRID_DY2) / GRID_DY)
