##================================================================================
##Window Container
##================================================================================
tool
extends VBoxContainer
class_name WindowContainer, "res://WindowContainer/icons/WindowContainer.svg"
export(String) var title setget set_title, get_title;
export(Texture) var title_icon setget set_title_icon;
export(bool) var resizable = true;
export(int, FLAGS, "Minimize", "Maximize", "Close") var controls = CONTROL_MIN_MAX_CLOSE setget set_controls;

# Constatns
const DRAG_NONE = 0;
const DRAG_MOVE = 1;
const DRAG_RESIZE_TOP = 1 << 1;
const DRAG_RESIZE_RIGHT = 1 << 2;
const DRAG_RESIZE_BOTTOM = 1 << 3;
const DRAG_RESIZE_LEFT = 1 << 4;
const DRAG_RESIZE_TOPL = DRAG_RESIZE_TOP + DRAG_RESIZE_LEFT;
const DRAG_RESIZE_TOPR = DRAG_RESIZE_TOP + DRAG_RESIZE_RIGHT;
const DRAG_RESIZE_BOTTOML = DRAG_RESIZE_BOTTOM + DRAG_RESIZE_LEFT;
const DRAG_RESIZE_BOTTOMR = DRAG_RESIZE_BOTTOM + DRAG_RESIZE_RIGHT;
const CONTROL_NONE = 0;
const CONTROL_MIN = 1;
const CONTROL_MAX = 1 << 1;
const CONTROL_CLOSE = 1 << 2;
const CONTROL_MIN_MAX_CLOSE = CONTROL_MIN + CONTROL_MAX + CONTROL_CLOSE;

# Variables
var drag_pos = null;
var drag_offset := Vector2(0, 0);
var drag_offset_far := Vector2(0, 0);
var drag_type : int = DRAG_NONE;
var gmouse_pos := Vector2(0, 0);
var border_size := 6;


##================================================================================
##Notifications
##================================================================================
func _ready():
	connect("gui_input", self, "_on_Window_gui_input");

##================================================================================
##Signals
##================================================================================
func _on_Window_gui_input(event):
	gmouse_pos = get_global_mouse_position();
	if !Engine.is_editor_hint():
		# Check If Beginning Drag
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			if event.pressed:
				# Get Drag Type and Set Offsets
				drag_pos = gmouse_pos - rect_global_position;
				drag_type = get_drag_type(gmouse_pos);
				drag_offset_far = get_position() + get_size() - gmouse_pos;
				if drag_type != DRAG_NONE:
					drag_offset = gmouse_pos - get_position();
			elif drag_type != DRAG_NONE:
				# End Drag
				drag_pos = null;
				drag_type = DRAG_NONE;

		# Drag Operation
		prevent_resize_block();
		if event is InputEventMouseMotion:
			if drag_type == DRAG_NONE:
				set_resize_preview_cursor();
			else:
				 handle_drag_behavior();

##================================================================================
##Functions
##================================================================================
func handle_drag_behavior() -> void:
	# Move Window
	if drag_type == DRAG_MOVE and drag_pos:
		set_global_position(gmouse_pos - drag_pos);
	elif drag_type != DRAG_NONE:
		# Resize Window
		if resizable:
			var rect := get_rect();
			var min_size := get_minimum_size();
			if drag_type & DRAG_RESIZE_TOP:
				var bottom = rect.position.y + rect.size.y;
				var max_y = bottom - min_size.y;
				rect.position.y = min(gmouse_pos.y - drag_offset.y, max_y);
				rect.size.y = bottom - rect.position.y;
			elif drag_type & DRAG_RESIZE_BOTTOM:
				rect.size.y = gmouse_pos.y - rect.position.y + drag_offset_far.y;
			if drag_type & DRAG_RESIZE_LEFT:
				var right = rect.position.x + rect.size.x;
				var max_x = right - min_size.x;
				rect.position.x = min(gmouse_pos.x - drag_offset.x, max_x);
				rect.size.x = right - rect.position.x;
			elif drag_type & DRAG_RESIZE_RIGHT:
				rect.size.x = gmouse_pos.x - rect.position.x + drag_offset_far.x;
			set_size(rect.size);
			set_position(rect.position);

func prevent_resize_block() -> void:
	if resizable:
			var children = get_tree().get_nodes_in_group("prevent_resize_block");
			var pos = get_global_position()+Vector2(border_size, border_size);
			var size = get_size()+Vector2(-border_size*2, -border_size*2);
			var mouse_in_resize_area = Rect2(pos, size).has_point(get_global_mouse_position());
			if mouse_in_resize_area:
				for child in children:
					child.set_mouse_filter(MOUSE_FILTER_PASS);
			else:
				for child in children:
					child.set_mouse_filter(MOUSE_FILTER_IGNORE);

func set_resize_preview_cursor() -> void:
	if resizable:
		var cursor = CURSOR_ARROW;
		var preview_drag_type = get_drag_type(gmouse_pos);
		match preview_drag_type:
			DRAG_RESIZE_TOP, DRAG_RESIZE_BOTTOM:
				cursor = CURSOR_VSIZE;
			DRAG_RESIZE_LEFT, DRAG_RESIZE_RIGHT:
				cursor = CURSOR_HSIZE;
			DRAG_RESIZE_TOPL, DRAG_RESIZE_BOTTOMR:
				cursor = CURSOR_FDIAGSIZE;
			DRAG_RESIZE_TOPR, DRAG_RESIZE_BOTTOML:
				cursor = CURSOR_BDIAGSIZE;
		if get_cursor_shape() != cursor:
			set_default_cursor_shape(cursor);

func set_title(txt : String) -> void:
	if txt != null:
		title = txt;
		$TitleBar/TitleHbox/ContentInfo/Title.set_text(txt);

func set_title_icon(tex : Texture) -> void:
	if tex != null:
		title_icon = tex;
		$TitleBar/TitleHbox/ContentInfo/Icon.set_texture(tex);

func set_controls(flags) -> void:
	controls = flags;
	var Minimize = $TitleBar/TitleHbox/Controls/Buttons/Minimize;
	var Maximize = $TitleBar/TitleHbox/Controls/Buttons/Maximize;
	var Close = $TitleBar/TitleHbox/Controls/Buttons/Close;
	if Minimize and Maximize and Close != null:
		Minimize.set_visible(flags & CONTROL_MIN);
		Maximize.set_visible(flags & CONTROL_MAX);
		Close.set_visible(flags & CONTROL_CLOSE);

func get_drag_type(mpos : Vector2) -> int:
	var drag_type = DRAG_NONE;
	var pos = get_global_position();
	if mpos.y < (pos.y+border_size):
		drag_type = DRAG_RESIZE_TOP;
	elif mpos.y >= (pos.y+get_size().y-border_size):
		drag_type = DRAG_RESIZE_BOTTOM;
	if mpos.x < (pos.x+border_size):
		drag_type |= DRAG_RESIZE_LEFT;
	elif mpos.x >= (pos.x+get_size().x-border_size):
		drag_type |= DRAG_RESIZE_RIGHT;
	if drag_type == DRAG_NONE and $TitleBar.get_global_rect().has_point(gmouse_pos):
		drag_type = DRAG_MOVE;
	return drag_type

func get_title() -> String:
	return title;

func get_title_icon() -> Texture:
	return title_icon;