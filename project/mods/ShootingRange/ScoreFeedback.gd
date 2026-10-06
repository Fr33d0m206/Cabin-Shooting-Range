extends CanvasLayer
## Persistent small scoreboard; one occasional popup with no input capture.
var session: RefCounted
var board: Label
var popup: VBoxContainer
var title: Label
var detail: Label
var animation: Tween
var tick=0.0
var enabled=true
func _ready() -> void:
	layer=96
	board=Label.new()
	board.mouse_filter=Control.MOUSE_FILTER_IGNORE
	board.add_theme_font_size_override("font_size",18)
	board.add_theme_color_override("font_color",Color(.94,.87,.65))
	board.add_theme_color_override("font_shadow_color",Color.BLACK)
	board.add_theme_constant_override("shadow_offset_y",2)
	add_child(board)
	popup=VBoxContainer.new()
	popup.mouse_filter=Control.MOUSE_FILTER_IGNORE
	popup.custom_minimum_size=Vector2(460,90)
	add_child(popup)
	title=make_label(34,Color(1,.79,.32))
	detail=make_label(20,Color(.95,.94,.84))
	popup.hide()
	session.changed.connect(refresh)
	session.encouragement.connect(show_message)
	session.completed.connect(finished)
	refresh()
func make_label(size: int, color: Color) -> Label:
	var label=Label.new()
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,.9))
	label.add_theme_constant_override("shadow_offset_y",3)
	popup.add_child(label)
	return label
func _process(delta: float) -> void:
	tick+=delta
	if tick<.1:return
	tick=0
	refresh()
func refresh() -> void:
	var size=get_viewport().get_visible_rect().size
	var unit=clampf(size.y/1000.0,1.0,2.2)
	board.scale=Vector2.ONE*unit
	board.position=Vector2(maxf(20,size.x-400*unit),24*unit)
	var mode="FREE PRACTICE" if session.mode=="free" else "%02d:%02d LEFT" % [int(ceil(session.remaining))/60,int(ceil(session.remaining))%60] if session.mode=="timed" else "ROUND COMPLETE"
	board.text=mode+"  /  "+str(session.total)+" POINTS\n"+str(session.hits)+" HITS  /  "+str(session.headshots)+" HEADSHOTS"
	if session.mode!="free":board.text+="  /  BEST "+str(session.best)
	board.visible=enabled and session.hits>0 or enabled and session.mode=="timed"
	popup.position=Vector2((size.x-460*unit)*.5,size.y*.64)
func show_message(headline: String, line: String) -> void:
	if not enabled:return
	if animation and animation.is_valid():animation.kill()
	title.text=headline
	detail.text=line
	popup.modulate.a=0
	var unit=clampf(get_viewport().get_visible_rect().size.y/1000.0,1.0,2.2)
	popup.scale=Vector2.ONE*.94*unit
	popup.show()
	animation=create_tween()
	animation.set_parallel(true)
	animation.tween_property(popup,"modulate:a",1.0,.16)
	animation.tween_property(popup,"scale",Vector2.ONE*unit,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.chain().tween_interval(1.6)
	animation.chain().tween_property(popup,"modulate:a",0.0,.45)
	animation.chain().tween_callback(popup.hide)
func finished(result: Dictionary) -> void:
	show_message("NEW HIGH SCORE!" if result.new_best else "ROUND COMPLETE",str(result.points)+" POINTS  /  "+str(result.hits)+" HITS  /  BEST "+str(result.best))
func set_enabled(value: bool) -> void:
	enabled=value
	if not value:
		board.hide()
		popup.hide()
