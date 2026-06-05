class_name TowerData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var element: JunkElement.Type = JunkElement.Type.WATER
@export var phenomenon_type: PhenomenonBase.PhenomenonType = PhenomenonBase.PhenomenonType.PUDDLE
@export var base_phenomenon_interval: float = 3.0
@export var phenomenon_radius: float = 28.0
@export var phenomenon_duration: float = 5.0
@export var element_color: Color = Color.WHITE
@export var tower_scene: PackedScene
@export var attack_range: float = 60.0
@export var fire_rate: float = 0.8
@export var damage: int = 10
@export var projectile_scene: PackedScene
