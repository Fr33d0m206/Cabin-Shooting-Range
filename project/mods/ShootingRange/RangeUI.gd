extends CanvasLayer
const Catalog=preload("res://mods/ShootingRange/Catalog.gd")
var editor: Node
var panel: PanelContainer
var status: Label
var selection: Label
var snap: CheckButton
var slot_index=0
var scenario_buttons: Array[Button]=[]
var selected_actions: Array[Button]=[]
var duration: OptionButton
const GOLD=Color(.80,.67,.40)
const INK=Color(.055,.066,.066,.97)
func _ready() -> void:
	layer=98
	panel=PanelContainer.new()
	panel.position=Vector2(22,22)
	panel.custom_minimum_size=Vector2(330,0)
	var style=StyleBoxFlat.new()
	style.bg_color=INK
	style.border_color=Color(.36,.34,.27)
	style.set_border_width_all(1)
	style.border_width_top=3
	style.corner_radius_top_left=8
	style.corner_radius_top_right=8
	style.corner_radius_bottom_left=8
	style.corner_radius_bottom_right=8
	style.set_content_margin_all(18)
	style.shadow_color=Color(0,0,0,.35)
	style.shadow_size=8
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var col=VBoxContainer.new()
	col.add_theme_constant_override("separation",9)
	var scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	label(col,"V O S T O K   /   F I E L D   K I T",12,GOLD)
	label(col,"CABIN RANGE",26,Color(.94,.92,.84))
	label(col,"Build a course. Make every shot count.",13,Color(.59,.63,.61))
	col.add_child(HSeparator.new())
	label(col,"TARGET LIBRARY",12,GOLD)
	var grid=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",6)
	col.add_child(grid)
	for kind in Catalog.TYPES:
		var data=Catalog.TYPES[kind]
		var button=make_button(grid,data.name,func():editor.begin_new(kind))
		button.tooltip_text=data.detail
		button.custom_minimum_size=Vector2(132,40)
		button.add_theme_font_size_override("font_size",13)
	col.add_child(HSeparator.new())
	selection=label(col,"No target selected",14,Color(.85,.86,.81))
	var actions=HBoxContainer.new()
	col.add_child(actions)
	selected_actions.append(make_button(actions,"Duplicate",func():editor.duplicate_selected()))
	selected_actions.append(make_button(actions,"Remove",func():editor.remove_selected()))
	var rotations=HBoxContainer.new()
	col.add_child(rotations)
	selected_actions.append(make_button(rotations,"↶  Rotate",func():editor.rotate_selected(deg_to_rad(-15))))
	selected_actions.append(make_button(rotations,"Rotate  ↷",func():editor.rotate_selected(deg_to_rad(15))))
	snap=CheckButton.new()
	snap.text="Snap to 0.25 m grid"
	snap.add_theme_font_size_override("font_size",14)
	col.add_child(snap)
	col.add_child(HSeparator.new())
	label(col,"SCENARIO LAYOUTS",12,GOLD)
	var slots=HBoxContainer.new()
	col.add_child(slots)
	for i in 3:
		var button=make_button(slots,"Scenario "+str(i+1),select_slot.bind(i))
		button.toggle_mode=true
		button.add_theme_font_size_override("font_size",12)
		scenario_buttons.append(button)
	select_slot(0)
	label(col,"Select a slot, then Save or Load.",12,Color(.60,.64,.61))
	var layouts=HBoxContainer.new()
	col.add_child(layouts)
	make_button(layouts,"Save",save_slot)
	make_button(layouts,"Load",load_slot)
	make_button(col,"Reset hits & reactive plates",func():editor.host.reset_hits())
	col.add_child(HSeparator.new())
	label(col,"ARCADE CHALLENGE",12,GOLD)
	duration=OptionButton.new()
	for seconds in [30,60,90,120]:duration.add_item(str(seconds)+" second round",seconds)
	duration.select(1)
	duration.custom_minimum_size.y=34
	col.add_child(duration)
	var challenges=HBoxContainer.new()
	col.add_child(challenges)
	make_button(challenges,"Start round",func():editor.host.start_round(duration.get_selected_id()))
	make_button(challenges,"Free practice",func():editor.host.reset_hits();editor.close())
	make_button(col,"RETURN TO PRACTICE    /    F4",func():editor.close())
	label(col,"Drag  Move    /    Q E  Rotate\nWASD  Pan    /    RMB  Orbit\nWheel  Zoom    /    Ctrl+Z  Undo",12,Color(.60,.64,.61))
	status=Label.new()
	status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	status.add_theme_font_size_override("font_size",16)
	status.add_theme_color_override("font_color",Color(.93,.87,.69))
	status.add_theme_color_override("font_shadow_color",Color.BLACK)
	status.add_theme_constant_override("shadow_offset_y",2)
	add_child(status)
	selection_changed(null)
	hide()

func make_button(parent: Node, text: String, callback: Callable) -> Button:
	var button=Button.new()
	button.text=text
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y=34
	button.focus_mode=Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",14)
	for key in ["normal","hover","pressed","disabled"]:
		var style=StyleBoxFlat.new()
		style.bg_color={"normal":Color(.12,.145,.14),"hover":Color(.21,.23,.19),"pressed":Color(.30,.28,.19),"disabled":Color(.09,.105,.10)}[key]
		style.border_color=Color(.35,.33,.25) if key!="hover" else GOLD
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left=10
		style.content_margin_right=10
		button.add_theme_stylebox_override(key,style)
	button.add_theme_color_override("font_color",Color(.88,.88,.80))
	button.add_theme_color_override("font_hover_color",Color(1,.94,.75))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func label(parent: Node, text: String, size: int, color: Color) -> Label:
	var node=Label.new()
	node.text=text
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node

func show_editor() -> void:
	var height=editor.get_viewport().get_visible_rect().size.y
	var scale_factor=clampf(height/1000.0,1.0,2.2)
	panel.scale=Vector2.ONE*scale_factor
	panel.position=Vector2(22,22)*scale_factor
	panel.size=Vector2(340,(height-90*scale_factor)/scale_factor)
	status.position=Vector2(28,height-44)
	status.text="Select a target to drag, or choose one from the library"
	show()

func popup_open() -> bool:
	return duration.get_popup().visible

func select_slot(index: int) -> void:
	slot_index=index
	for i in scenario_buttons.size():scenario_buttons[i].set_pressed_no_signal(i==index)
	if status:status.text="Scenario "+str(index+1)+" selected / Save this layout or Load a saved one"

func selection_changed(target: Node3D) -> void:
	if not selection:return
	selection.text=Catalog.TYPES[target.kind].name+"  /  "+str(target.hits)+" hits" if is_instance_valid(target) else "No target selected"
	for button in selected_actions:button.disabled=not is_instance_valid(target)

func save_slot() -> void:
	if editor.host.loading or editor.dragged:return
	var ok=editor.host.store.write(editor.host.map_key,"scenario"+str(slot_index+1),editor.host.rows())
	editor.host.notice("Scenario "+str(slot_index+1)+" saved" if ok else "Could not save scenario")

func load_slot() -> void:
	if editor.host.loading:return
	var host=editor.host
	var key="scenario"+str(slot_index+1)
	if not host.store.config.has_section_key(host.map_key,key):host.notice("This scenario slot is empty");return
	host.checkpoint()
	var records=host.store.read(host.map_key,key)
	await host.replace_layout(records)
	if editor.opened and host.targets.size()==records.size():host.notice("Scenario "+str(slot_index+1)+" loaded")
