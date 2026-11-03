class_name ArenaTiles
extends RefCounted
## Координаты плиток в arena_tiles.png. Файл создан скриптом arena_art.py — не править руками.

const SAND_WEIGHTS := [34, 34, 10, 5, 7, 2, 5, 3]
const WALL_WEIGHTS := [6, 3, 1]
## Кадров у анимированных плиток публики (кадры идут вправо от первого).
const CROWD_FRAMES := 2
const SAND := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
const WALL := [Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0)]
const EDGE := {"N": Vector2i(11, 0), "S": Vector2i(12, 0), "W": Vector2i(13, 0), "E": Vector2i(14, 0)}
const FACE_TOP := [Vector2i(15, 0), Vector2i(0, 1)]
const FACE_BOTTOM := [Vector2i(1, 1), Vector2i(2, 1)]
const STEP := Vector2i(3, 1)
const RIM := Vector2i(4, 1)
const CROWD_CALM := [Vector2i(5, 1), Vector2i(7, 1), Vector2i(9, 1)]
const CROWD_CHEER := [Vector2i(11, 1), Vector2i(13, 1), Vector2i(0, 2)]
const DIAG := {"TL": [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2)], "TR": [Vector2i(11, 2), Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2), Vector2i(15, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)], "BL": [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3)], "BR": [Vector2i(13, 3), Vector2i(14, 3), Vector2i(15, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4)]}
