extends Node

var FPS := 60
var DELTA := SGFixed.div(SGFixed.from_float(1.0),SGFixed.from_float(FPS))
var DEBUG := false

var swoosh_to_lobby := false

var MUTE := false

var Maps := [
	"res://scenes/Levels/Level1/Level1.tscn",
	"res://scenes/Levels/Level2/Level2.tscn"
]

var current_map: String

var intro_played := false
