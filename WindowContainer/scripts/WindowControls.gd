# WindowContainer
extends HBoxContainer

onready var WindowContainer = get_node("../../../..") ;
##================================================================================
##Notifications
##================================================================================
func _ready():
	$Minimize.connect("pressed", self, "_on_Minimize_pressed");
	$Maximize.connect("pressed", self, "_on_Maximize_pressed");
	$Close.connect("pressed", self, "_on_Close_pressed");
	$Close.connect("mouse_exited", self, "_on_Close_mouse_exited");
	$Close.connect("mouse_entered", self, "_on_Close_mouse_entered");

##================================================================================
##Signals
##================================================================================
func _on_Close_pressed():
	WindowContainer.queue_free();

func _on_Maximize_pressed():
	WindowContainer.set_size(OS.get_window_size());
	WindowContainer.set_position(Vector2(0, 0));

func _on_Minimize_pressed():
	WindowContainer.set_size(WindowContainer.get_minimum_size());