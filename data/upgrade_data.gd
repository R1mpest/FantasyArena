class_name UpgradeData
extends Resource
## Улучшение стата игрока, которое предлагается при повышении уровня.

enum Mode { ADD, MULTIPLY }

@export var id: StringName
@export var title: String
@export_multiline var description: String
## Имя свойства Player, которое меняется.
@export var stat: StringName
@export var amount: float = 1.0
@export var mode: Mode = Mode.ADD
@export var max_level: int = 5
@export var weight: float = 1.0
