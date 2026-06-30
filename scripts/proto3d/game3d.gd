extends Node3D
## «Побег от Тимохи» — 3D от ПЕРВОГО ЛИЦА. Большой туманный лес (Slender-стиль),
## изба человеческого размера с интерьером (котёл), квесты разбросаны по карте,
## Тимоха гонится, день/ночь, дождь. Примитивы-плейсхолдеры (заменяемы на 3D-модели).

const WORLD := 220.0          # полупролёт карты (440x440 м) — большой лес
const TREES := 2400         # очень густой лес (на мобиле /3)
const TREE_SCALE := 5.2     # крупные GLB-деревья Kenney (густой высокий лес)
const BORDER_TREES := 320   # плотная стена леса по периметру карты
const CLEARING := 11.0        # радиус поляны у избы без деревьев (меньше → лес ближе к дому)
const HUTS := [Vector3(82, 0, -72), Vector3(136, 0, 92), Vector3(-165, 0, -50), Vector3(22, 0, 176)]
# ориентиры-структуры — деревья оставляют вокруг них полянку (иначе густой лес их заслоняет)
const LANDMARKS := [Vector3(-110, 0, -130), Vector3(-135, 0, 150), Vector3(160, 0, -55), Vector3(-85, 0, 75), Vector3(-170, 0, -45), Vector3(-60, 0, -185), Vector3(95, 0, 38), Vector3(-42, 0, 120), Vector3(176, 0, 28), Vector3(-150, 0, 92)]
const LANDMARK_CLEAR := 9.0
const SPEED := 6.2
const SPRINT := 9.6
const GRAVITY := 22.0
const JUMP := 7.5
const CATCH_DIST := 1.7
const STUN := 0.8
const DAY_LEN := 95.0         # длительность суток (сек)
const TIMOKHA_SPEED := 4.4
const TIMOKHA_NIGHT := 7.2     # быстрее ходьбы (6.2), медленнее спринта (9.6) — стой/делай дела = опасно, беги спринтом
const TIMOKHA_DASH := 10.8     # рывок чуть быстрее спринта — страшные моменты
const WAKE_TIME := 18.0       # грейс перед началом охоты
const TK_MODEL_SCALE := 1.18  # модель ~1.87 м → ~2.2 м (нависающий антагонист)

var player: CharacterBody3D
var cam: Camera3D
var timokha: CharacterBody3D
var timokha_mat: StandardMaterial3D
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var env: Environment
var rain: GPUParticles3D
var fireflies: CPUParticles3D   # светлячки вокруг игрока ночью (атмосфера)
var pollen: CPUParticles3D      # пыльца/споры в воздухе днём (атмосфера)
var hud: Label
var snd_rain: AudioStreamPlayer
var snd_heart: AudioStreamPlayer
var snd_ding: AudioStreamPlayer
var snd_caught: AudioStreamPlayer
var snd_win: AudioStreamPlayer
var snd_step1: AudioStreamPlayer
var snd_step2: AudioStreamPlayer
var snd_wind: AudioStreamPlayer
var snd_stinger: AudioStreamPlayer
var snd_laugh: AudioStreamPlayer
var snd_crickets: AudioStreamPlayer
var snd_owl: AudioStreamPlayer
var _owl_t := 8.0
var snd_thunder: AudioStreamPlayer
var snd_dread: AudioStreamPlayer
var light_flash: ColorRect
var _light_v := 0.0
var _lightning_t := 14.0
var _thunder_delay := -1.0
var heart_t := 0.0
var step_t := 0.0
var step_alt := false
var last_seen := Vector3.ZERO
var search_t := 0.0
var wander_t := 0.0
var wander_dir := Vector3.ZERO
var tk_state := "сон"
var tk_aggro := false   # видит игрока в упор (для красного прицела/угрозы)
var tk_stuck_t := 0.0   # сколько застрял (уперся и не продвигается)
var tk_detour_t := 0.0  # таймер обхода препятствия
var tk_detour := Vector3.ZERO   # направление обхода (вбок)
var tk_lastpos := Vector3.ZERO  # позиция в прошлом кадре (детект застревания)
var _was_night := false
var tk_legs: Array = []
var tk_arms: Array = []
var tk_walk := 0.0
var _tree_pine: Array = []
var _tree_leafy: Array = []
var _rock_scenes: Array = []
var _bush_scenes: Array = []
var _log_scenes: Array = []
var tk_sprite: Sprite3D
var tk_sprite_y := 0.6
var tk_model: Node3D                # 3D-модель Мишганчика (FBX со скелетом+анимацией бега)
var tk_anim: AnimationPlayer
var tk_anim_name := ""              # клип по умолчанию (бег) — единственный в текущем FBX
var tk_clip_run := ""              # клип бега/погони (ночь)
var tk_clip_walk := ""            # клип ходьбы (если пользователь добавит)
var tk_clip_idle := ""            # клип покоя/стоя (день; если пользователь добавит)
var tk_cur_clip := ""             # что сейчас проигрывается (чтобы не перезапускать)
var tk_glow: OmniLight3D            # жуткая подсветка модели, включается только ночью
var tk_mats: Array = []            # материалы модели — эмиссия по текстуре нарастает ночью (видимость)

# балансовый авто-плей (headless): бот идёт по квестам по порядку
var _autoplay := false
const _AP_ORDER := ["wood1", "wood2", "herb1", "herb2", "cucumber", "water", "berries", "mushroom", "fish", "chickens", "fence", "potato", "apples", "banya", "bones", "brew", "yacht"]
var _ap_log := {}
var _ap_frames := 0

# тач-управление (мобайл)
var _touch_flag := false
var show_touch := false
var touch_move := Vector2.ZERO
var joy_id := -1
var joy_origin := Vector2.ZERO
var look_id := -1
var touch_jump := false
var touch_sprint := false
var joy_base: ColorRect
var joy_knob: ColorRect

# фидбэк поимки
var catch_flash: ColorRect
var flash_v := 0.0
var shake := 0.0
var bob_t := 0.0
var bob_amt := 0.0
var fire_light: OmniLight3D
var mill_blades: Node3D
var danger_overlay: ColorRect
var vignette: ColorRect   # затемнение краёв экрана, усиливается с близостью Мишганчика ночью (хоррор)

# хотбар ресурсов
var hb_wood: Label
var hb_herbs: Label
var done_label: Label
var done_t := 0.0
var qbar_fill: ColorRect
var qbar_label: Label
var qbar_bg: ColorRect
var touch_root: Control   # контейнер тач-контролов (джойстик+кнопки) — прячем на финале
var pause_btn: Button
var catch_label: Label
var quest_panel: Label
var quest_prompt: Label
var qp_bg: ColorRect
var qp_fill: ColorRect
var crosshair: ColorRect
var tutorial_label: Label
var _tut_t := 9.0
var paused := false
var pause_overlay: ColorRect
var pause_controls: Label
var window_mats: Array = []
var snd_btn: Button
var _muted := false
var _yacht_announced := false
var restart_btn: Button
var win_quit_btn: Button
var win_overlay: ColorRect
var win_label: Label
var moon_hud: Control
var star_dots: Array = []

# мини-карта-радар
var radar: Control
var radar_dots: Array = []
var radar_tk: Panel
var radar_dir: Polygon2D
var space: PhysicsDirectSpaceState3D

# материалы
var m_ground: Material
var _path_shader: Shader   # кэш шейдера дороги (колеи/грязь)
var m_trunk: StandardMaterial3D
var m_leaf: ShaderMaterial
var m_leaf2: ShaderMaterial
var m_log: StandardMaterial3D
var m_floor: StandardMaterial3D
var m_rock: StandardMaterial3D

var pitch := 0.0
var stun := 0.0
var caught := 0
var won := false
var lost := false
var clock := 0.0
var nights := 1
var wake := WAKE_TIME

var wood := 0
var herbs := 0

# квесты: id, pos, label, kind, done, prog, need(словарь ресурсов)
var quests := []
var quests_done := 0
var yacht_ready := false

# рывок Тимохи
var _tele := false
var _dash := false
var _t_tele := 0.0
var _t_dash := 0.0
var _cd := 5.0

# скриншот-режим
var _shot := false
var _shotin := false
var _shothut := false
var _shotwin := false
var _shot_t := 0.0
var _shot_saved := false
var _dbg_clip := ""   # форс-проигрывание клипа для проверочных кадров (--shotidle/walk/run)
var _mobile := false   # мобильный режим (телефон/мобильный веб): лёгкая графика + тач

func _ready() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_shot = "--shot" in args
	_shotin = "--shotin" in args
	_autoplay = "--autoplay" in args
	_touch_flag = "--touch" in args
	_mobile = ("--mobile" in args) or OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")
	_shothut = "--shothut" in args
	_shotwin = "--shotwin" in args
	if "--night" in args:
		clock = DAY_LEN * 0.72   # для проверки ночной атмосферы скриншотом
		wake = 0.0               # без грейса — ночь-спавн срабатывает сразу
	if _autoplay:
		print("[autoplay] start")
	_build_materials()
	_build_environment()
	_build_ground()
	_build_cabin()
	_build_structures()
	_build_paths()
	_build_forest()
	_build_water_and_yacht()
	_make_player()
	_make_timokha()
	_build_quests()
	if not _autoplay:
		_build_rain()
	_build_hud()
	_build_audio()
	_build_touch()
	_build_radar()
	space = get_world_3d().direct_space_state
	if not (_shot or _shotin):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _shotin:
		player.global_position = Vector3(0, 1.0, 1.0)
	if _shot:
		timokha.global_position = Vector3(1.0, 1.0, 10.0)   # в кадр (по центру) для проверки модели/тени
	if _shothut:
		_shot = true
		player.global_position = HUTS[0] + Vector3(0.0, 1.0, 2.2)   # внутрь хижины смотреть на пропсы
	if _shotwin:
		_shot = true
		won = true
		nights = 2
		caught = 1
		clock = 137.0   # 2:17 для проверки статистики на экране победы
	if "--shotwell" in args:
		_shot = true
		player.global_position = Vector3(-170, 1.0, -39)   # смотрит на колодец у квеста «вода»
	if "--shotcatch" in args:
		_shot = true
		caught = 2   # проверка постоянного счётчика поимок в HUD
	if "--shotlose" in args:
		_shot = true
		lost = true
		nights = 2
		quests_done = 5   # проверка экрана проигрыша
	if "--shotedge" in args:
		_shot = true
		player.global_position = Vector3(WORLD - 12.0, 1.5, 0)
		player.rotate_y(-PI * 0.5)   # смотрит к краю (+X) — проверка стены леса/границы
	if "--shotcamp" in args:
		_shot = true
		player.global_position = HUTS[0] + Vector3(0, 1.6, 11.0)   # снаружи хижины — бочки/палатка/ящики
	if "--shotfire" in args:
		_shot = true
		player.global_position = Vector3(-60, 1.0, -179)   # смотрит на лесной костёр у квеста «грибы»
	if "--shotmill" in args:
		_shot = true
		player.global_position = Vector3(-110, 1.0, -107)   # смотрит на мельницу у квеста «дрова 2»
	if "--shottower" in args:
		_shot = true
		player.global_position = Vector3(-135, 1.0, 169)   # смотрит на сторожевую вышку у квеста «забор»
	if "--shothay" in args:
		_shot = true
		player.global_position = Vector3(160, 1.0, -41)   # смотрит на стог с пугалом у квеста «огурец»
	if "--shotidol" in args:
		_shot = true
		player.global_position = Vector3(-85, 1.5, 83)   # смотрит на лицо идола у квеста «травы 1»
	if "--shotprompt" in args:
		_shot = true
		player.global_position = Vector3(70, 1.0, -65)   # стоит на квесте «дрова 1» — подсказка-прогресс
	if "--shotpause" in args:
		_shot = true
		paused = true
		if pause_overlay != null:
			pause_overlay.visible = true
	if "--shotdock" in args:
		_shot = true
		player.global_position = Vector3(10, 1.5, 186)
		player.rotate_y(PI)   # развернуть к причалу/яхте (+Z), фонарь-маяк в кадре
	if "--shotflash" in args:
		_shot = true
		_light_v = 4.5   # к моменту снимка останется частичная вспышка молнии
		_lightning_t = 999.0
	if "--shotdark" in args:
		_shot = true
		clock = DAY_LEN * 0.72   # ночь визуально (nf=1)
		wake = 0.0               # ночная охота активна (для danger/виньетки)
		_was_night = true        # подавить телепорт-спавн — модель остаётся в кадре близко
		timokha.global_position = Vector3(1.0, 1.0, 9.0)   # близко перед игроком (ночная встреча)
		timokha.look_at(player.global_position, Vector3.UP)
	for _p in [["--shotidle", "idle"], ["--shotwalk", "walk"], ["--shotrun", "run"]]:
		if _p[0] in args:
			_shot = true
			_dbg_clip = _p[1]   # форс-клип для проверки позы (день, модель в кадре)
			timokha.global_position = Vector3(1.0, 1.0, 9.0)
			timokha.look_at(player.global_position, Vector3.UP)
	var _qshots := {"--shotbanya": Vector3(176, 1.5, 36), "--shotgarden": Vector3(95, 1.5, 46), "--shotapples": Vector3(-42, 1.5, 128), "--shotbones": Vector3(-150, 1.5, 100)}
	for k in _qshots:
		if k in args:
			_shot = true
			player.global_position = _qshots[k]
	if tutorial_label != null:
		if show_touch:
			tutorial_label.text = "Левый джойстик — идти · справа свайп — камера · БЕГ\nДелай дела ДНЁМ. НОЧЬЮ беги от Мишганчика!\nСобери всё и почини яхту, чтобы сбежать"
		else:
			tutorial_label.text = "WASD — идти · Shift — бег · мышь — осмотр · Esc — пауза\nДелай дела ДНЁМ. НОЧЬЮ беги от Мишганчика!\nСобери всё и почини яхту, чтобы сбежать"
	if pause_controls != null:
		if show_touch:
			pause_controls.text = "Управление: левый джойстик — идти · правая зона свайп — камера\nкнопки БЕГ / ПРЫЖОК · кнопка ❚❚ — пауза\nДнём делай дела · ночью беги и прячься · почини яхту"
		else:
			pause_controls.text = "Управление: WASD — идти · Shift — бег · мышь — осмотр\nSpace — прыжок · Esc — пауза\nДнём делай дела · ночью беги и прячься · почини яхту"

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _emissive_mat(albedo: Color, emit: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(albedo)
	m.emission_enabled = true
	m.emission = emit
	m.emission_energy_multiplier = energy
	return m

func _add_light(pos: Vector3, color: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	add_child(l)
	return l

func _build_materials() -> void:
	var gtex: Variant = load("res://art/textures/grass.png") if ResourceLoader.exists("res://art/textures/grass.png") else null
	var dtex: Variant = load("res://art/textures/dirt.png") if ResourceLoader.exists("res://art/textures/dirt.png") else null
	if gtex != null and dtex != null:
		# земля = шейдер: трава + проплешины грязи по шуму + крупная цветовая вариация (не «одна плоская текстура»)
		var gsh := Shader.new()
		gsh.code = """shader_type spatial;
uniform sampler2D grass : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt : source_color, repeat_enable, filter_linear_mipmap;
uniform float tile = 135.0;
uniform float patch = 46.0;
float hsh(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vns(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hsh(i); float b = hsh(i + vec2(1.0, 0.0));
	float c = hsh(i + vec2(0.0, 1.0)); float d = hsh(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p){ return vns(p) * 0.62 + vns(p * 3.1 + vec2(11.0, 5.0)) * 0.38; }
void fragment(){
	vec2 guv = UV * tile;
	vec3 g = texture(grass, guv).rgb;
	vec3 d = texture(dirt, guv).rgb;
	float m = smoothstep(0.50, 0.70, fbm(UV * patch));     // доля грязи/проплешин
	vec3 col = mix(g, d, m);
	float tint = vns(UV * (patch * 0.26) + vec2(3.3, 7.7)); // крупные свет/тёмные зоны травы
	col *= mix(0.80, 1.13, tint);
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
"""
		var gm := ShaderMaterial.new()
		gm.shader = gsh
		gm.set_shader_parameter("grass", gtex)
		gm.set_shader_parameter("dirt", dtex)
		gm.set_shader_parameter("tile", 135.0)
		gm.set_shader_parameter("patch", 46.0)
		m_ground = gm
	elif gtex != null:
		var gm2 := _mat(Color(1, 1, 1))
		gm2.albedo_texture = gtex
		gm2.uv1_scale = Vector3(135, 135, 1)
		gm2.roughness = 1.0
		m_ground = gm2
	else:
		m_ground = _mat(Color(0.30, 0.40, 0.22))
	m_trunk = _mat(Color(0.34, 0.24, 0.16))
	# ветер: вершинный шейдер качает кроны/кусты (GPU, фаза по позиции дерева — 0 нагрузки на CPU)
	var wind_shader := Shader.new()
	wind_shader.code = """shader_type spatial;
uniform vec4 albedo : source_color = vec4(0.2, 0.4, 0.2, 1.0);
uniform float amount = 0.12;
uniform float speed = 1.1;
void vertex() {
	float ph = NODE_POSITION_WORLD.x * 0.6 + NODE_POSITION_WORLD.z * 0.4;
	VERTEX.x += sin(TIME * speed + ph) * amount;
	VERTEX.z += sin(TIME * speed * 0.7 + ph * 1.3) * amount * 0.6;
}
void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
}
"""
	m_leaf = ShaderMaterial.new()
	m_leaf.shader = wind_shader
	m_leaf.set_shader_parameter("albedo", Color(0.16, 0.34, 0.18))
	m_leaf.set_shader_parameter("amount", 0.12)
	m_leaf2 = ShaderMaterial.new()
	m_leaf2.shader = wind_shader
	m_leaf2.set_shader_parameter("albedo", Color(0.34, 0.47, 0.17))
	m_leaf2.set_shader_parameter("amount", 0.10)
	m_log = _mat(Color(0.52, 0.38, 0.24))
	m_floor = _mat(Color(0.42, 0.30, 0.18))
	m_rock = _mat(Color(0.5, 0.5, 0.52))

func _build_environment() -> void:
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -40, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.94, 0.83)   # тёплый солнечный свет (не белый «прожектор»)
	sun.shadow_enabled = not _mobile   # на телефоне тени выключены (тяжело)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS   # дешевле для большого леса
	sun.directional_shadow_max_distance = 75.0   # тени только вблизи (туман скрывает дальние) → перф ок
	sun.shadow_blur = 1.5                          # мягче края
	sun.shadow_bias = 0.04
	add_child(sun)
	# луна — второй directional light; ProceduralSkyMaterial рисует её диск в небе (не зависит от тумана)
	moon = DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-13, 180, 0)   # низко над линией деревьев, в направлении обзора (−Z)
	moon.light_color = Color(0.70, 0.80, 1.0)
	moon.light_energy = 0.0
	moon.light_angular_distance = 5.0   # крупный диск = луна
	moon.shadow_enabled = false
	moon.visible = false
	add_child(moon)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.42, 0.52, 0.62)
	sm.sky_horizon_color = Color(0.70, 0.72, 0.70)
	sm.ground_horizon_color = Color(0.55, 0.55, 0.52)
	sm.ground_bottom_color = Color(0.40, 0.40, 0.36)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92   # ниже — день не пересвечен
	# лёгкий цветокор — чуть «киношнее»
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.18   # больше контраста — не плоско
	env.adjustment_saturation = 1.14
	# мягкое свечение ярких/эмиссивных поверхностей (огонь/окна/луна/лампа)
	env.glow_enabled = not _mobile   # glow выключен на телефоне (перф)
	env.glow_intensity = 0.45
	env.glow_strength = 0.9
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color(0.70, 0.74, 0.74)
	env.fog_density = 0.020
	we.environment = env
	add_child(we)

func _build_ground() -> void:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(WORLD * 3.0, WORLD * 3.0)   # шире игровой зоны → за краем не «пустота», а туманная земля
	mesh.mesh = pm
	mesh.material_override = m_ground
	body.add_child(mesh)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(WORLD * 3.0, 1.0, WORLD * 3.0)
	cs.shape = bs
	cs.position = Vector3(0, -0.5, 0)
	body.add_child(cs)
	add_child(body)
	# невидимые стены по периметру игровой зоны — нельзя уйти за край/упасть
	var e := WORLD - 2.0
	_bound_wall(Vector3(e, 8, 0), Vector3(3, 16, WORLD * 2.0))
	_bound_wall(Vector3(-e, 8, 0), Vector3(3, 16, WORLD * 2.0))
	_bound_wall(Vector3(0, 8, e), Vector3(WORLD * 2.0, 16, 3))
	_bound_wall(Vector3(0, 8, -e), Vector3(WORLD * 2.0, 16, 3))

func _bound_wall(pos: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	wall.add_child(cs)
	add_child(wall)

func _box(parent: Node, pos: Vector3, size: Vector3, mat: StandardMaterial3D, collide: bool) -> void:
	var node: Node3D
	if collide:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()
	node.position = pos
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat
	node.add_child(mesh)
	if collide:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		node.add_child(cs)
	parent.add_child(node)

func _build_cabin() -> void:
	# изба ~9x9, стены 3.2 м, проём-дверь спереди (+Z). Человеческий масштаб.
	var H := 3.2
	var half := 4.5
	# пол (декор) + крыльцо
	_box(self, Vector3(0, 0.05, 0), Vector3(half * 2, 0.2, half * 2), m_floor, false)
	# задняя и боковые стены
	_box(self, Vector3(0, H * 0.5, -half), Vector3(half * 2, H, 0.3), m_log, true)
	_box(self, Vector3(-half, H * 0.5, 0), Vector3(0.3, H, half * 2), m_log, true)
	_box(self, Vector3(half, H * 0.5, 0), Vector3(0.3, H, half * 2), m_log, true)
	# передняя стена с дверным проёмом (две секции + перемычка)
	var door := 1.8
	var seg := (half * 2 - door) * 0.5
	_box(self, Vector3(-(door * 0.5 + seg * 0.5), H * 0.5, half), Vector3(seg, H, 0.3), m_log, true)
	_box(self, Vector3((door * 0.5 + seg * 0.5), H * 0.5, half), Vector3(seg, H, 0.3), m_log, true)
	_box(self, Vector3(0, H - 0.4, half), Vector3(door, 0.8, 0.3), m_log, true)
	# крыша (двускатная имитация — наклонные боксы)
	var roofL := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(half * 2 + 0.6, 0.25, half + 0.8)
	roofL.mesh = rb
	roofL.material_override = _mat(Color(0.40, 0.22, 0.16))
	roofL.position = Vector3(0, H + 1.0, -half * 0.5)
	roofL.rotation_degrees = Vector3(-28, 0, 0)
	add_child(roofL)
	var roofR := MeshInstance3D.new()
	roofR.mesh = rb
	roofR.material_override = roofL.material_override
	roofR.position = Vector3(0, H + 1.0, half * 0.5)
	roofR.rotation_degrees = Vector3(28, 0, 0)
	add_child(roofR)
	# интерьер: стол + котёл (квест варки)
	_box(self, Vector3(2.4, 0.95, -2.6), Vector3(1.8, 0.12, 1.0), m_floor, false)
	for c in [Vector3(-0.8, 0.47, -0.4), Vector3(0.8, 0.47, -0.4), Vector3(-0.8, 0.47, 0.4), Vector3(0.8, 0.47, 0.4)]:
		_box(self, Vector3(2.4, 0, -2.6) + c, Vector3(0.12, 0.95, 0.12), m_floor, false)
	_cauldron(Vector3(-1.8, 0, -2.8))
	# детали интерьера/экстерьера
	_porch(half, H)
	_window(Vector3(-half + 0.06, 1.7, -1.2))
	_window(Vector3(half - 0.06, 1.7, 1.4))
	_door_leaf(half, H)
	_bed(Vector3(-3.0, 0, -3.2))
	_corner_stove(Vector3(3.3, 0, -3.3))
	# перегородка с проходом (намёк на вторую комнату)
	_box(self, Vector3(1.4, H * 0.5, -3.0), Vector3(0.25, H, 2.6), m_log, true)
	# печная труба над углом с печью + дымок из неё
	var brick := _mat(Color(0.46, 0.32, 0.26))
	_box(self, Vector3(3.0, 4.5, -3.0), Vector3(0.7, 1.9, 0.7), brick, false)
	_box(self, Vector3(3.0, 5.55, -3.0), Vector3(0.9, 0.25, 0.9), brick, false)   # навершие
	_smoke(Vector3(3.0, 5.8, -3.0), 12, 3.6, Vector3(0.25, 0.4, 0.0), 0.4, 0.9, 0.3, 10.0, 0.4, 0.9)   # дым из трубы (снос ветром)

func _smoke(pos: Vector3, amount: int, lifetime: float, gravity: Vector3, smin: float, smax: float, mesh_r: float, spread: float, vmin: float, vmax: float) -> void:
	var sm := CPUParticles3D.new()
	sm.position = pos
	sm.amount = amount
	sm.lifetime = lifetime
	sm.direction = Vector3(0, 1, 0)
	sm.spread = spread
	sm.initial_velocity_min = vmin
	sm.initial_velocity_max = vmax
	sm.gravity = gravity
	sm.scale_amount_min = smin
	sm.scale_amount_max = smax
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.0))
	sm.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = mesh_r
	mesh.height = mesh_r * 2.0
	sm.mesh = mesh
	var grad := Gradient.new()
	grad.set_color(0, Color(0.5, 0.5, 0.52, 0.0))
	grad.set_color(1, Color(0.43, 0.43, 0.45, 0.0))
	grad.add_point(0.3, Color(0.48, 0.48, 0.5, 0.31))
	sm.color_ramp = grad
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.5, 0.5, 0.52)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material_override = mat
	add_child(sm)

func _cauldron(pos: Vector3) -> void:
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 0.9
	body.mesh = sm
	body.scale = Vector3(1, 0.85, 1)
	body.position = pos + Vector3(0, 0.7, 0)
	body.material_override = _mat(Color(0.14, 0.13, 0.14))
	add_child(body)
	# угли под котлом
	var fire := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.2, 0.7)
	fire.mesh = bm
	fire.position = pos + Vector3(0, 0.1, 0)
	var fmat := _emissive_mat(Color(1.0, 0.5, 0.1), Color(1.0, 0.45, 0.1), 2.5)
	fire.material_override = fmat
	add_child(fire)
	_add_light(pos + Vector3(0, 1.0, 0), Color(1.0, 0.6, 0.3), 2.6, 7.0)

func _ground_shadow(pos: Vector3, r: float) -> void:
	var sh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.02
	sh.mesh = cm
	sh.position = Vector3(pos.x, 0.02, pos.z)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0, 0, 0, 0.26)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sh.material_override = m
	add_child(sh)

func _tint_meshes(n: Node, c: Color, rough := 0.85) -> void:
	# GLB без текстур (белые) → красим заливкой подходящего цвета
	var m := _mat(c)
	m.roughness = rough
	for mi in _collect_meshes(n):
		mi.material_override = m

func _prop_color(nm: String) -> Color:
	if nm.begins_with("barrel"):
		return Color(0.40, 0.27, 0.15)   # дерево/бочка
	if nm.begins_with("box"):
		return Color(0.55, 0.40, 0.22)   # ящик
	if nm == "chest":
		return Color(0.45, 0.30, 0.16)   # сундук
	if nm == "tree-log":
		return Color(0.42, 0.30, 0.18)   # бревно
	if nm == "tent":
		return Color(0.46, 0.43, 0.30)   # брезент
	return Color(0.5, 0.5, 0.52)

func _camp_props() -> void:
	var scenes := {}
	for n in ["barrel", "barrel-open", "box", "box-large", "chest", "tree-log", "tent"]:
		var p := "res://art/models/props/%s.glb" % n
		if ResourceLoader.exists(p):
			scenes[n] = load(p)
	if scenes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var picks := ["barrel", "barrel-open", "box", "box-large", "chest", "tree-log"]
	for h in HUTS:
		for k in 3:
			var nm: String = picks[rng.randi() % picks.size()]
			if not scenes.has(nm):
				continue
			var pr: Node3D = scenes[nm].instantiate()
			var sc := rng.randf_range(1.4, 1.9)
			pr.scale = Vector3(sc, sc, sc)
			var a := rng.randf() * TAU
			pr.position = h + Vector3(cos(a) * 4.6, 0, sin(a) * 4.6)
			pr.rotation.y = rng.randf() * TAU
			_tint_meshes(pr, _prop_color(nm))
			add_child(pr)
	# палатка у первой хижины
	if scenes.has("tent"):
		var t: Node3D = scenes["tent"].instantiate()
		t.scale = Vector3(2.2, 2.2, 2.2)
		t.position = HUTS[0] + Vector3(5.5, 0, -1.0)
		t.rotation.y = deg_to_rad(40)
		_tint_meshes(t, _prop_color("tent"))
		add_child(t)

func _build_structures() -> void:
	var cols := [_mat(Color(0.50, 0.37, 0.24)), _mat(Color(0.46, 0.40, 0.30)), _mat(Color(0.42, 0.34, 0.26)), _mat(Color(0.48, 0.42, 0.32))]
	var i := 0
	for h in HUTS:
		_ground_shadow(h, 4.3)
		_hut(h, 6.0, 6.0, 3.0, cols[i % cols.size()])
		_hut_props(h, i)
		i += 1
	_camp_props()   # бочки/ящики/сундук/палатка у хижин (Survival Kit)
	_ground_shadow(Vector3(-170, 0, -45), 1.6); _well(Vector3(-170, 0, -45))   # ориентир у квеста «вода»
	_ground_shadow(Vector3(-60, 0, -185), 1.4); _campfire(Vector3(-60, 0, -185))   # лесной костёр у квеста «грибы»
	_ground_shadow(Vector3(-110, 0, -130), 2.6); _windmill(Vector3(-110, 0, -130))   # мельница у квеста «дрова 2»
	_ground_shadow(Vector3(-135, 0, 150), 1.8); _watchtower(Vector3(-135, 0, 150))   # вышка у квеста «забор»
	_fences(Vector3(-135, 0, 150))   # ряд заборов (часть сломана) у квеста «забор»

func _fences(pos: Vector3) -> void:
	var fp := "res://art/models/props/fence_simple.glb"
	if not ResourceLoader.exists(fp):
		return
	var sc := 2.2
	var step := 2.2
	for i in 8:
		var f: Node3D = load(fp).instantiate()
		f.scale = Vector3(sc, sc, sc)
		f.position = pos + Vector3(4.0, 0, float(i) * step - 8.0)
		f.rotation.y = 0.0
		if i == 3 or i == 6:
			f.rotation.z = deg_to_rad(35)   # повалившийся сегмент («сломан»)
		add_child(f)
	_ground_shadow(Vector3(160, 0, -55), 1.9); _haystack(Vector3(160, 0, -55))   # стог+пугало у квеста «огурец»
	_ground_shadow(Vector3(-85, 0, 75), 1.2); _idol(Vector3(-85, 0, 75))   # идол-тотем у квеста «травы 1»
	_graves(Vector3(-85, 0, 75))      # мрачный погост у идола
	_graves(Vector3(-60, 0, -185))    # надгробия у грибов (хоррор)
	_ground_detail()                  # грибы/цветы у тематических квестов

func _scatter_models(names: Array, pos: Vector3, count: int, rmin: float, rmax: float, scl: float, rng: RandomNumberGenerator) -> void:
	var scenes: Array = []
	for n in names:
		var p := "res://art/models/nature/%s.glb" % n
		if ResourceLoader.exists(p):
			scenes.append(load(p))
	if scenes.is_empty():
		return
	for i in count:
		var m: Node3D = scenes[rng.randi() % scenes.size()].instantiate()
		var s := scl * rng.randf_range(0.8, 1.3)
		m.scale = Vector3(s, s, s)
		var a := rng.randf() * TAU
		var r := rng.randf_range(rmin, rmax)
		m.position = pos + Vector3(cos(a) * r, 0, sin(a) * r)
		m.rotation.y = rng.randf() * TAU
		add_child(m)

func _scatter_global(names: Array, count: int, scl: float) -> void:
	# мелкая флора по ВСЕЙ карте (жизнь): обходит поляну/тропы/хижины/озеро/ориентиры
	var scenes: Array = []
	for n in names:
		var p := "res://art/models/nature/%s.glb" % n
		if ResourceLoader.exists(p):
			scenes.append(load(p))
	if scenes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 5:
		attempts += 1
		var x := rng.randf_range(-WORLD + 8, WORLD - 8)
		var z := rng.randf_range(-WORLD + 8, WORLD - 8)
		if Vector2(x, z).length() < CLEARING:
			continue
		if z > WORLD - 42.0 and abs(x) < 55.0:
			continue
		if _on_path(x, z):
			continue
		var skip := false
		for h in HUTS:
			if Vector2(x - h.x, z - h.z).length() < 7.0:
				skip = true
				break
		if skip:
			continue
		placed += 1
		var m: Node3D = scenes[rng.randi() % scenes.size()].instantiate()
		var s := scl * rng.randf_range(0.7, 1.4)
		m.scale = Vector3(s, s, s)
		m.position = Vector3(x, 0, z)
		m.rotation.y = rng.randf() * TAU
		add_child(m)

func _scatter_clumps(names: Array, clumps: int, per_clump: int, radius: float, scl: float) -> void:
	# кучки подлеска (трава/мелкие кусты) — естественные пятна, а не одиночки
	var scenes: Array = []
	for n in names:
		var p := "res://art/models/nature/%s.glb" % n
		if ResourceLoader.exists(p):
			scenes.append(load(p))
	if scenes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	var placed := 0
	var attempts := 0
	while placed < clumps and attempts < clumps * 5:
		attempts += 1
		var cx := rng.randf_range(-WORLD + 10, WORLD - 10)
		var cz := rng.randf_range(-WORLD + 10, WORLD - 10)
		if Vector2(cx, cz).length() < CLEARING:
			continue
		if cz > WORLD - 42.0 and abs(cx) < 55.0:
			continue
		if _on_path(cx, cz):
			continue
		var skip := false
		for h in HUTS:
			if Vector2(cx - h.x, cz - h.z).length() < 7.0:
				skip = true
				break
		if skip:
			continue
		placed += 1
		for j in per_clump:
			var m: Node3D = scenes[rng.randi() % scenes.size()].instantiate()
			var s := scl * rng.randf_range(0.7, 1.3)
			m.scale = Vector3(s, s, s)
			var a := rng.randf() * TAU
			var r := rng.randf_range(0.0, radius)
			m.position = Vector3(cx + cos(a) * r, 0, cz + sin(a) * r)
			m.rotation.y = rng.randf() * TAU
			add_child(m)

func _ground_detail() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	# глобальная флора по всей карте (цветы/трава/грибы) — оживляет лес
	_scatter_global(["flower_redB", "flower_yellowB", "flower_purpleB", "grass_leafs", "mushroom_tan", "mushroom_red"], 55 if _mobile else 170, 1.5)
	# кучки подлеска (трава + мелкие кусты) — плотные пятна
	_scatter_clumps(["grass_leafs", "plant_bushSmall", "flower_yellowB"], 22 if _mobile else 65, 4, 2.6, 1.4)
	# грибы у квеста «грибы»
	_scatter_models(["mushroom_red", "mushroom_redGroup", "mushroom_tan", "mushroom_tanGroup"], Vector3(-60, 0, -185), 12, 2.0, 7.0, 2.6, rng)
	# цветы/трава у квестов с травами
	_scatter_models(["flower_redB", "flower_yellowB", "flower_purpleB", "grass_leafs"], Vector3(-85, 0, 75), 14, 2.0, 7.0, 2.0, rng)
	_scatter_models(["flower_redB", "flower_yellowB", "flower_purpleB", "grass_leafs"], Vector3(130, 0, 100), 14, 2.0, 7.0, 2.0, rng)

func _graves(pos: Vector3) -> void:
	var names := ["cross-wood", "gravestone-cross", "gravestone-broken", "gravestone-round", "gravestone-bevel"]
	var scenes: Array = []
	var snames: Array = []
	for n in names:
		var p := "res://art/models/props/%s.glb" % n
		if ResourceLoader.exists(p):
			scenes.append(load(p))
			snames.append(n)
	if scenes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 13.0 + pos.z * 7.0) + 100
	for i in 6:
		var idx := rng.randi() % scenes.size()
		var g: Node3D = scenes[idx].instantiate()
		# GLB без текстур (белые) → назначаем материал: дерево для креста, камень для надгробий
		var mat: StandardMaterial3D
		if String(snames[idx]).begins_with("cross-wood"):
			mat = _mat(Color(0.33, 0.23, 0.14))
		else:
			var v := rng.randf_range(-0.04, 0.04)   # лёгкая вариация камня
			mat = _mat(Color(0.40 + v, 0.41 + v, 0.44 + v))   # серый камень (не пересвечивать на солнце)
		mat.roughness = 0.94
		for mi in _collect_meshes(g):
			mi.material_override = mat
		var sc := rng.randf_range(1.4, 2.0)
		g.scale = Vector3(sc, sc, sc)
		var a := rng.randf() * TAU
		var r := rng.randf_range(3.5, 8.0)
		g.position = pos + Vector3(cos(a) * r, 0, sin(a) * r)
		g.rotation.y = rng.randf() * TAU
		g.rotation.z = deg_to_rad(rng.randf_range(-9.0, 9.0))   # лёгкий наклон — заброшенность
		add_child(g)

func _idol(pos: Vector3) -> void:
	var wood := _mat(Color(0.36, 0.26, 0.16))
	var darkwood := _mat(Color(0.22, 0.15, 0.09))
	# основание-камни
	for i in 5:
		var a := TAU * i / 5.0
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.28
		sm.height = 0.5
		s.mesh = sm
		s.position = pos + Vector3(cos(a) * 0.95, 0.12, sin(a) * 0.95)
		s.material_override = _mat(Color(0.45, 0.45, 0.47))
		add_child(s)
	# столб-тело
	var pole := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.45
	pc.bottom_radius = 0.55
	pc.height = 2.8
	pole.mesh = pc
	pole.position = pos + Vector3(0, 1.4, 0)
	pole.material_override = wood
	add_child(pole)
	# голова-короб
	_box(self, pos + Vector3(0, 3.0, 0), Vector3(1.0, 0.95, 0.9), wood, false)
	# навершие-шапка
	var cap := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.0
	cc.bottom_radius = 0.72
	cc.height = 0.7
	cap.mesh = cc
	cap.position = pos + Vector3(0, 3.8, 0)
	cap.material_override = darkwood
	add_child(cap)
	# лицо спереди (+Z): глаза-впадины, нос, рот
	_box(self, pos + Vector3(-0.25, 3.08, 0.46), Vector3(0.22, 0.14, 0.08), darkwood, false)
	_box(self, pos + Vector3(0.25, 3.08, 0.46), Vector3(0.22, 0.14, 0.08), darkwood, false)
	_box(self, pos + Vector3(0, 2.88, 0.5), Vector3(0.14, 0.42, 0.18), darkwood, false)
	_box(self, pos + Vector3(0, 2.62, 0.46), Vector3(0.42, 0.1, 0.08), darkwood, false)
	# руки-обрубки
	_box(self, pos + Vector3(-0.62, 1.95, 0), Vector3(0.5, 0.2, 0.2), wood, false)
	_box(self, pos + Vector3(0.62, 1.95, 0), Vector3(0.5, 0.2, 0.2), wood, false)

func _haystack(pos: Vector3) -> void:
	var hay := _mat(Color(0.78, 0.66, 0.32))
	# стог-конус
	var stack := MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 0.0
	sc.bottom_radius = 1.8
	sc.height = 2.6
	stack.mesh = sc
	stack.position = pos + Vector3(0, 1.3, 0)
	stack.material_override = hay
	add_child(stack)
	# вилы воткнуты в стог
	_box(self, pos + Vector3(1.5, 1.0, 0.3), Vector3(0.06, 2.0, 0.06), _mat(Color(0.35, 0.25, 0.14)), false)
	# ── пугало рядом ──
	var spos := pos + Vector3(2.8, 0, 0.5)
	var wood := _mat(Color(0.4, 0.28, 0.16))
	_box(self, spos + Vector3(0, 1.1, 0), Vector3(0.14, 2.2, 0.14), wood, false)   # столб
	_box(self, spos + Vector3(0, 1.6, 0), Vector3(1.6, 0.12, 0.12), wood, false)   # руки-поперечина
	var body := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.32
	bc.bottom_radius = 0.44
	bc.height = 0.95
	body.mesh = bc
	body.position = spos + Vector3(0, 1.5, 0)
	body.material_override = _mat(Color(0.55, 0.42, 0.28))
	add_child(body)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.28
	hs.height = 0.56
	head.mesh = hs
	head.position = spos + Vector3(0, 2.25, 0)
	head.material_override = _mat(Color(0.80, 0.68, 0.42))
	add_child(head)
	# шляпа
	_box(self, spos + Vector3(0, 2.52, 0), Vector3(0.56, 0.07, 0.56), _mat(Color(0.3, 0.2, 0.12)), false)
	_box(self, spos + Vector3(0, 2.62, 0), Vector3(0.28, 0.2, 0.28), _mat(Color(0.3, 0.2, 0.12)), false)
	# пучки соломы на концах рук
	for sx in [-0.85, 0.85]:
		_box(self, spos + Vector3(sx, 1.55, 0), Vector3(0.12, 0.4, 0.12), hay, false)

func _watchtower(pos: Vector3) -> void:
	var wood := _mat(Color(0.40, 0.30, 0.19))
	var dark := _mat(Color(0.30, 0.22, 0.13))
	var legs := [Vector3(-1.0, 0, -1.0), Vector3(1.0, 0, -1.0), Vector3(-1.0, 0, 1.0), Vector3(1.0, 0, 1.0)]
	# ноги
	for lp in legs:
		_box(self, pos + lp + Vector3(0, 2.0, 0), Vector3(0.18, 4.0, 0.18), wood, false)
	# горизонтальные стяжки на середине
	_box(self, pos + Vector3(0, 2.0, -1.0), Vector3(2.2, 0.12, 0.12), dark, false)
	_box(self, pos + Vector3(0, 2.0, 1.0), Vector3(2.2, 0.12, 0.12), dark, false)
	_box(self, pos + Vector3(-1.0, 2.0, 0), Vector3(0.12, 0.12, 2.2), dark, false)
	_box(self, pos + Vector3(1.0, 2.0, 0), Vector3(0.12, 0.12, 2.2), dark, false)
	# платформа
	_box(self, pos + Vector3(0, 4.05, 0), Vector3(2.6, 0.16, 2.6), wood, false)
	# перила + угловые стойки
	var rh := 4.6
	_box(self, pos + Vector3(0, rh, -1.25), Vector3(2.6, 0.1, 0.1), dark, false)
	_box(self, pos + Vector3(0, rh, 1.25), Vector3(2.6, 0.1, 0.1), dark, false)
	_box(self, pos + Vector3(-1.25, rh, 0), Vector3(0.1, 0.1, 2.6), dark, false)
	_box(self, pos + Vector3(1.25, rh, 0), Vector3(0.1, 0.1, 2.6), dark, false)
	for lp in legs:
		_box(self, pos + lp * 1.25 + Vector3(0, 4.4, 0), Vector3(0.1, 0.7, 0.1), dark, false)
	# двускатная крыша
	var roofL := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(3.0, 0.18, 1.8)
	roofL.mesh = rb
	roofL.material_override = dark
	roofL.position = pos + Vector3(0, 5.4, -0.7)
	roofL.rotation_degrees = Vector3(-26, 0, 0)
	add_child(roofL)
	var roofR := MeshInstance3D.new()
	roofR.mesh = rb
	roofR.material_override = dark
	roofR.position = pos + Vector3(0, 5.4, 0.7)
	roofR.rotation_degrees = Vector3(26, 0, 0)
	add_child(roofR)
	_box(self, pos + Vector3(-1.0, 5.0, 0), Vector3(0.1, 0.9, 0.1), dark, false)
	_box(self, pos + Vector3(1.0, 5.0, 0), Vector3(0.1, 0.9, 0.1), dark, false)
	# лесенка спереди (+Z)
	for r in 5:
		_box(self, pos + Vector3(0, 0.6 + r * 0.65, 1.32), Vector3(0.9, 0.08, 0.08), wood, false)

func _windmill(pos: Vector3) -> void:
	# башня (сужающийся кверху цилиндр)
	var tower := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.bottom_radius = 2.2
	tc.top_radius = 1.4
	tc.height = 7.0
	tower.mesh = tc
	tower.position = pos + Vector3(0, 3.5, 0)
	tower.material_override = _mat(Color(0.5, 0.42, 0.32))
	add_child(tower)
	# коническая крыша
	var roof := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.0
	rc.bottom_radius = 1.7
	rc.height = 1.8
	roof.mesh = rc
	roof.position = pos + Vector3(0, 7.9, 0)
	roof.material_override = _mat(Color(0.4, 0.26, 0.16))
	add_child(roof)
	# дверь
	_box(self, pos + Vector3(0, 1.05, 2.05), Vector3(1.0, 2.1, 0.2), _mat(Color(0.26, 0.18, 0.1)), false)
	# крылья (вращаются в _process)
	mill_blades = Node3D.new()
	mill_blades.position = pos + Vector3(0, 5.6, 2.3)
	add_child(mill_blades)
	_box(mill_blades, Vector3.ZERO, Vector3(0.45, 0.45, 0.5), _mat(Color(0.22, 0.15, 0.08)), false)
	for i in 4:
		var blade := Node3D.new()
		blade.rotation_degrees = Vector3(0, 0, 90.0 * i)
		mill_blades.add_child(blade)
		_box(blade, Vector3(0, 1.75, 0), Vector3(0.55, 3.3, 0.06), _mat(Color(0.62, 0.52, 0.36)), false)
		_box(blade, Vector3(0, 1.75, 0.02), Vector3(0.13, 3.4, 0.13), _mat(Color(0.3, 0.2, 0.12)), false)

func _campfire(pos: Vector3) -> void:
	# GLB-костёр (камни + поленья); пламя/искры/дым/свет — ниже
	var cfp := "res://art/models/props/campfire_stones.glb"
	if ResourceLoader.exists(cfp):
		var m: Node3D = load(cfp).instantiate()
		m.scale = Vector3(1.7, 1.7, 1.7)
		m.position = pos
		add_child(m)
	else:
		var stone := _mat(Color(0.42, 0.42, 0.44))
		for i in 7:
			var a := TAU * i / 7.0
			var s := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.22
			sm.height = 0.4
			s.mesh = sm
			s.position = pos + Vector3(cos(a) * 0.85, 0.1, sin(a) * 0.85)
			s.material_override = stone
			add_child(s)
	# пламя-конус (эмиссия)
	var flame := MeshInstance3D.new()
	var fc := CylinderMesh.new()
	fc.top_radius = 0.0
	fc.bottom_radius = 0.30
	fc.height = 0.7
	flame.mesh = fc
	flame.position = pos + Vector3(0, 0.45, 0)
	var fm := _emissive_mat(Color(1.0, 0.55, 0.12), Color(1.0, 0.5, 0.1), 3.0)
	flame.material_override = fm
	add_child(flame)
	# мерцающий тёплый свет
	fire_light = _add_light(pos + Vector3(0, 0.8, 0), Color(1.0, 0.6, 0.25), 2.4, 10.0)
	# искры (поднимаются и гаснут)
	var sparks := CPUParticles3D.new()
	sparks.position = pos + Vector3(0, 0.55, 0)
	sparks.amount = 22
	sparks.lifetime = 1.5
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 22.0
	sparks.initial_velocity_min = 1.4
	sparks.initial_velocity_max = 2.8
	sparks.gravity = Vector3(0, -2.2, 0)   # взлетают и опадают дугой
	sparks.scale_amount_min = 0.04
	sparks.scale_amount_max = 0.08
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.06
	pmesh.height = 0.12
	sparks.mesh = pmesh
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.72, 0.28, 0.95))
	grad.set_color(1, Color(0.8, 0.2, 0.08, 0.0))
	sparks.color_ramp = grad
	var spm := StandardMaterial3D.new()
	spm.vertex_color_use_as_albedo = true
	spm.emission_enabled = true
	spm.emission = Color(1.0, 0.55, 0.15)
	spm.emission_energy_multiplier = 2.5
	spm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sparks.material_override = spm
	add_child(sparks)
	# дымок (поднимается выше искр и рассеивается)
	_smoke(pos + Vector3(0, 0.7, 0), 14, 3.2, Vector3(0, 0.35, 0), 0.5, 1.1, 0.35, 12.0, 0.5, 1.0)

func _well(pos: Vector3) -> void:
	var stone := _mat(Color(0.5, 0.5, 0.52))
	var wood := _mat(Color(0.42, 0.30, 0.18))
	# каменное кольцо колодца
	var ring := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.95
	rc.bottom_radius = 1.0
	rc.height = 1.0
	ring.mesh = rc
	ring.position = pos + Vector3(0, 0.5, 0)
	ring.material_override = stone
	add_child(ring)
	# тёмная «вода» внутри
	var water := MeshInstance3D.new()
	var wc := CylinderMesh.new()
	wc.top_radius = 0.78
	wc.bottom_radius = 0.78
	wc.height = 0.06
	water.mesh = wc
	water.position = pos + Vector3(0, 0.94, 0)
	water.material_override = _mat(Color(0.12, 0.20, 0.28))
	add_child(water)
	# два столба (от земли), поперечная балка, навес-крыша
	_box(self, pos + Vector3(-0.95, 1.35, 0), Vector3(0.16, 2.7, 0.16), wood, false)
	_box(self, pos + Vector3(0.95, 1.35, 0), Vector3(0.16, 2.7, 0.16), wood, false)
	_box(self, pos + Vector3(0, 2.72, 0), Vector3(2.1, 0.16, 0.16), wood, false)
	_box(self, pos + Vector3(0, 2.95, 0), Vector3(2.4, 0.12, 1.5), _mat(Color(0.38, 0.26, 0.16)), false)
	# верёвка + ведро над устьем
	_box(self, pos + Vector3(0, 2.2, 0), Vector3(0.05, 0.95, 0.05), _mat(Color(0.30, 0.25, 0.20)), false)
	var bucket := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.22
	bcyl.bottom_radius = 0.18
	bcyl.height = 0.3
	bucket.mesh = bcyl
	bucket.position = pos + Vector3(0, 1.72, 0)
	bucket.material_override = wood
	add_child(bucket)

func _hut_props(pos: Vector3, variant: int) -> void:
	match variant % 4:
		0:
			_prop_table(pos + Vector3(-1.3, 0, -1.6))
			_prop_barrel(pos + Vector3(1.4, 0, -1.4))
		1:
			_prop_barrel(pos + Vector3(-1.5, 0, -1.5))
			_prop_crate(pos + Vector3(1.3, 0, -1.4), 0.7)
			_prop_crate(pos + Vector3(1.3, 0.7, -1.4), 0.5)
		2:
			_prop_table(pos + Vector3(1.2, 0, -1.5))
			_prop_stove(pos + Vector3(-1.6, 0, -1.6))
		_:
			_prop_barrel(pos + Vector3(-1.4, 0, -1.5))
			_prop_crate(pos + Vector3(1.4, 0, -1.5), 0.8)

func _prop_barrel(pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.42
	c.bottom_radius = 0.45
	c.height = 1.0
	m.mesh = c
	m.position = pos + Vector3(0, 0.5, 0)
	m.material_override = _mat(Color(0.42, 0.28, 0.16))
	add_child(m)

func _prop_crate(pos: Vector3, s: float) -> void:
	_box(self, pos + Vector3(0, s * 0.5, 0), Vector3(s, s, s), _mat(Color(0.55, 0.42, 0.26)), false)

func _prop_table(pos: Vector3) -> void:
	_box(self, pos + Vector3(0, 0.95, 0), Vector3(1.4, 0.12, 0.8), m_floor, false)
	for cc in [Vector3(-0.6, 0.47, -0.3), Vector3(0.6, 0.47, -0.3), Vector3(-0.6, 0.47, 0.3), Vector3(0.6, 0.47, 0.3)]:
		_box(self, pos + cc, Vector3(0.1, 0.95, 0.1), m_floor, false)

func _prop_stove(pos: Vector3) -> void:
	_box(self, pos + Vector3(0, 0.7, 0), Vector3(0.9, 1.4, 0.9), _mat(Color(0.48, 0.46, 0.44)), false)
	var fire := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.5, 0.4, 0.1)
	fire.mesh = fb
	fire.position = pos + Vector3(0, 0.5, 0.48)
	var fm := _emissive_mat(Color(1, 0.5, 0.1), Color(1, 0.45, 0.1), 2.0)
	fire.material_override = fm
	add_child(fire)
	_add_light(pos + Vector3(0, 0.9, 0.6), Color(1, 0.6, 0.3), 1.8, 5.0)

func _hut(pos: Vector3, w: float, d: float, h: float, col: StandardMaterial3D) -> void:
	_box(self, pos + Vector3(0, 0.05, 0), Vector3(w, 0.15, d), m_floor, false)
	_box(self, pos + Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, 0.3), col, true)
	_box(self, pos + Vector3(-w * 0.5, h * 0.5, 0), Vector3(0.3, h, d), col, true)
	_box(self, pos + Vector3(w * 0.5, h * 0.5, 0), Vector3(0.3, h, d), col, true)
	var seg := (w - 1.6) * 0.5
	_box(self, pos + Vector3(-(0.8 + seg * 0.5), h * 0.5, d * 0.5), Vector3(seg, h, 0.3), col, true)
	_box(self, pos + Vector3(0.8 + seg * 0.5, h * 0.5, d * 0.5), Vector3(seg, h, 0.3), col, true)
	_box(self, pos + Vector3(0, h - 0.4, d * 0.5), Vector3(1.6, 0.8, 0.3), col, true)
	var rl := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(w + 0.5, 0.25, d * 0.62)
	rl.mesh = rb
	rl.material_override = _mat(Color(0.38, 0.22, 0.16))
	rl.position = pos + Vector3(0, h + 0.7, -d * 0.25)
	rl.rotation_degrees = Vector3(-26, 0, 0)
	add_child(rl)
	var rr := MeshInstance3D.new()
	rr.mesh = rb
	rr.material_override = rl.material_override
	rr.position = pos + Vector3(0, h + 0.7, d * 0.25)
	rr.rotation_degrees = Vector3(26, 0, 0)
	add_child(rr)

func _build_paths() -> void:
	for h in HUTS:
		_path(Vector3.ZERO, h)
	_path(Vector3.ZERO, Vector3(8, 0, WORLD - 18.0))   # к причалу/яхте
	_path(Vector3.ZERO, Vector3(135, 0, -150))         # к курятнику
	_path(Vector3.ZERO, Vector3(-135, 0, 150))         # к забору

func _path(a: Vector3, b: Vector3) -> void:
	var dir := b - a
	dir.y = 0
	var length := dir.length()
	if length < 1.0:
		return
	var mid := (a + b) * 0.5
	var seg := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.4, 0.06, length)
	seg.mesh = bm
	var dtex: Variant = load("res://art/textures/dirt.png") if ResourceLoader.exists("res://art/textures/dirt.png") else null
	if dtex != null:
		if _path_shader == null:
			_path_shader = Shader.new()
			_path_shader.code = """shader_type spatial;
uniform sampler2D dirt : source_color, repeat_enable, filter_linear_mipmap;
uniform float len = 10.0;
float hsh(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vns(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	float a = hsh(i); float b = hsh(i + vec2(1.0, 0.0));
	float c = hsh(i + vec2(0.0, 1.0)); float d = hsh(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
void fragment(){
	vec2 uv = vec2(UV.x, UV.y * (len / 3.0));
	vec3 c = texture(dirt, uv).rgb;
	float ruts = vns(vec2(UV.x * 4.0, UV.y * len * 0.5));     // пятна грязи
	c *= mix(0.60, 1.06, ruts);
	float wheel = smoothstep(0.07, 0.0, abs(UV.x - 0.32)) + smoothstep(0.07, 0.0, abs(UV.x - 0.68));
	c *= mix(1.0, 0.68, clamp(wheel, 0.0, 1.0) * 0.7);        // две тёмные колеи вдоль
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"""
		var psh := ShaderMaterial.new()
		psh.shader = _path_shader
		psh.set_shader_parameter("dirt", dtex)
		psh.set_shader_parameter("len", length)
		seg.material_override = psh
	else:
		var pmat := _mat(Color(0.30, 0.24, 0.16))
		seg.material_override = pmat
	seg.position = Vector3(mid.x, 0.04, mid.z)
	seg.rotation.y = atan2(dir.x, dir.z)
	seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(seg)

func _dist_to_seg(px: float, pz: float, ax: float, az: float, bx: float, bz: float) -> float:
	var abx := bx - ax
	var abz := bz - az
	var ab2 := abx * abx + abz * abz
	var t := 0.0
	if ab2 > 0.0001:
		t = clampf((px - ax) * abx + (pz - az) * abz, 0.0, ab2) / ab2
	var cx := ax + abx * t
	var cz := az + abz * t
	return Vector2(px - cx, pz - cz).length()

func _on_path(x: float, z: float) -> bool:
	for h in HUTS:
		if _dist_to_seg(x, z, 0.0, 0.0, h.x, h.z) < 2.6:
			return true
	if _dist_to_seg(x, z, 0.0, 0.0, 8.0, WORLD - 18.0) < 2.6:
		return true
	if _dist_to_seg(x, z, 0.0, 0.0, 135.0, -150.0) < 2.6:
		return true
	if _dist_to_seg(x, z, 0.0, 0.0, -135.0, 150.0) < 2.6:
		return true
	return false

func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260627
	var n := 60 if _autoplay else (int(TREES / 3) if _mobile else TREES)   # на телефоне втрое меньше деревьев (перф)
	var placed := 0
	var attempts := 0
	while placed < n and attempts < n * 4:
		attempts += 1
		var x := rng.randf_range(-WORLD + 4, WORLD - 4)
		var z := rng.randf_range(-WORLD + 4, WORLD - 4)
		var p := Vector2(x, z)
		if p.length() < CLEARING:
			continue
		if z > WORLD - 42.0 and abs(x) < 55.0:   # не сажать в озере/у яхты
			continue
		var near_hut := false
		for h in HUTS:
			if Vector2(x - h.x, z - h.z).length() < 8.5:
				near_hut = true
				break
		if near_hut:
			continue
		var near_lm := false
		for lm in LANDMARKS:
			if Vector2(x - lm.x, z - lm.z).length() < LANDMARK_CLEAR:
				near_lm = true
				break
		if near_lm:
			continue
		if _on_path(x, z):
			continue
		placed += 1
		_tree(Vector3(x, 0, z), rng.randf_range(0.8, 1.5), rng.randf() < 0.35)
	# плотная стена леса по периметру — визуальная граница, перекрывает обзор за край
	if not _autoplay:
		for i in (int(BORDER_TREES / 3) if _mobile else BORDER_TREES):
			var bx := 0.0
			var bz := 0.0
			if rng.randf() < 0.5:
				bx = rng.randf_range(-WORLD + 3, WORLD - 3)
				bz = (WORLD - rng.randf_range(3.0, 32.0)) * (1.0 if rng.randf() < 0.5 else -1.0)
			else:
				bz = rng.randf_range(-WORLD + 3, WORLD - 3)
				bx = (WORLD - rng.randf_range(3.0, 32.0)) * (1.0 if rng.randf() < 0.5 else -1.0)
			if bz > WORLD - 42.0 and abs(bx) < 55.0:   # не в озере/у яхты
				continue
			_tree(Vector3(bx, 0, bz), rng.randf_range(1.0, 1.6), rng.randf() < 0.3)
	# валуны (больше для большой карты)
	for i in (40 if _mobile else 95):
		var x := rng.randf_range(-WORLD + 6, WORLD - 6)
		var z := rng.randf_range(-WORLD + 6, WORLD - 6)
		if Vector2(x, z).length() < CLEARING or (z > WORLD - 42.0 and abs(x) < 55.0):
			continue
		_rock(Vector3(x, 0, z), rng.randf_range(0.6, 2.4))
	# кусты-подлесок (разнообразие)
	for i in (70 if _mobile else 190):
		var bx := rng.randf_range(-WORLD + 6, WORLD - 6)
		var bz := rng.randf_range(-WORLD + 6, WORLD - 6)
		if Vector2(bx, bz).length() < CLEARING or (bz > WORLD - 42.0 and abs(bx) < 55.0):
			continue
		if _bush_scenes.is_empty():
			for bn in ["plant_bush", "plant_bushDetailed", "plant_bushLarge", "plant_bushSmall"]:
				var bp := "res://art/models/nature/%s.glb" % bn
				if ResourceLoader.exists(bp):
					_bush_scenes.append(load(bp))
		if not _bush_scenes.is_empty():
			var bm: Node3D = _bush_scenes[randi() % _bush_scenes.size()].instantiate()
			var bsc := rng.randf_range(1.3, 2.2)
			bm.scale = Vector3(bsc, bsc, bsc)
			bm.position = Vector3(bx, 0, bz)
			bm.rotation.y = rng.randf_range(0.0, TAU)
			add_child(bm)
		else:
			var bush := MeshInstance3D.new()
			var bsm := SphereMesh.new()
			bsm.radius = rng.randf_range(0.4, 0.9)
			bsm.height = bsm.radius * 1.4
			bush.mesh = bsm
			bush.position = Vector3(bx, bsm.radius * 0.6, bz)
			bush.material_override = m_leaf
			add_child(bush)
	# пеньки и поваленные брёвна
	for i in (24 if _mobile else 66):
		var lx := rng.randf_range(-WORLD + 6, WORLD - 6)
		var lz := rng.randf_range(-WORLD + 6, WORLD - 6)
		if Vector2(lx, lz).length() < CLEARING or (lz > WORLD - 42.0 and abs(lx) < 55.0) or _on_path(lx, lz):
			continue
		var skip := false
		for hh in HUTS:
			if Vector2(lx - hh.x, lz - hh.z).length() < 8.0:
				skip = true
				break
		if skip:
			continue
		if _log_scenes.is_empty():
			for ln in ["log", "log_large"]:
				var lp := "res://art/models/nature/%s.glb" % ln
				if ResourceLoader.exists(lp):
					_log_scenes.append(load(lp))
		if not _log_scenes.is_empty():
			var lm: Node3D = _log_scenes[rng.randi() % _log_scenes.size()].instantiate()
			var lsc := rng.randf_range(1.6, 2.4)
			lm.scale = Vector3(lsc, lsc, lsc)
			lm.position = Vector3(lx, 0, lz)
			lm.rotation.y = rng.randf() * TAU
			add_child(lm)
		else:
			var lg := MeshInstance3D.new()
			var lc := CylinderMesh.new()
			lc.top_radius = 0.3
			lc.bottom_radius = 0.32
			lc.height = 3.0
			lg.mesh = lc
			lg.position = Vector3(lx, 0.32, lz)
			lg.rotation = Vector3(0, rng.randf_range(0.0, PI), PI * 0.5)
			lg.material_override = m_trunk
			add_child(lg)

func _load_tree_scenes(leafy: bool) -> Array:
	var arr: Array = []
	var names := ["tree_default", "tree_oak"] if leafy else ["tree_pineTallA", "tree_pineDefaultA", "tree_pineRoundC", "tree_pineSmallC"]
	for n in names:
		var p := "res://art/models/nature/%s.glb" % n
		if ResourceLoader.exists(p):
			arr.append(load(p))
	if leafy:
		_tree_leafy = arr
	else:
		_tree_pine = arr
	return arr

func _tree(pos: Vector3, s: float, leafy: bool = false) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var scenes: Array = _tree_leafy if leafy else _tree_pine
	if scenes.is_empty():
		scenes = _load_tree_scenes(leafy)
	if not scenes.is_empty():
		var ps: PackedScene = scenes[randi() % scenes.size()]
		var model: Node3D = ps.instantiate()
		var ms := s * TREE_SCALE
		model.scale = Vector3(ms, ms, ms)
		model.rotation.y = randf() * TAU
		body.add_child(model)
	else:
		# запасной примитив (если моделей нет)
		var trunk := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.22 * s
		cm.bottom_radius = 0.30 * s
		cm.height = 3.2 * s
		trunk.mesh = cm
		trunk.position = Vector3(0, 1.6 * s, 0)
		trunk.material_override = m_trunk
		body.add_child(trunk)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4 * s
	cap.height = 5.0 * s
	cs.shape = cap
	cs.position = Vector3(0, 2.5 * s, 0)
	body.add_child(cs)
	add_child(body)

func _rock(pos: Vector3, s: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	if _rock_scenes.is_empty():
		for n in ["rock_largeA", "rock_largeB", "rock_largeC"]:
			var p := "res://art/models/nature/%s.glb" % n
			if ResourceLoader.exists(p):
				_rock_scenes.append(load(p))
	if not _rock_scenes.is_empty():
		var m: Node3D = _rock_scenes[randi() % _rock_scenes.size()].instantiate()
		var ms := s * 1.4
		m.scale = Vector3(ms, ms, ms)
		m.rotation.y = randf() * TAU
		body.add_child(m)
	else:
		var mesh := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.7 * s
		sm.height = 1.0 * s
		mesh.mesh = sm
		mesh.position = Vector3(0, 0.2 * s, 0)
		mesh.material_override = m_rock
		body.add_child(mesh)
	var cs := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = 0.6 * s
	cs.shape = ss
	cs.position = Vector3(0, 0.4 * s, 0)
	body.add_child(cs)
	add_child(body)

func _build_water_and_yacht() -> void:
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(WORLD * 2.0, 60.0)
	pm.subdivide_width = 48   # сетка для вершинных волн
	pm.subdivide_depth = 10
	water.mesh = pm
	water.position = Vector3(0, 0.14, WORLD - 5.0)   # выше земли: с волнами ±0.06 диапазон 0.08..0.20 → НЕ ныряет под землю (убирает «плавание» на берегу)
	var wsh := Shader.new()
	wsh.code = """shader_type spatial;
uniform vec4 col : source_color = vec4(0.16, 0.30, 0.44, 0.9);
uniform float wave_h = 0.06;
void vertex() {
	float w = sin(VERTEX.x * 0.22 + TIME * 1.1) + sin(VERTEX.z * 0.5 + TIME * 0.8);
	VERTEX.y += w * wave_h;
}
void fragment() {
	ALBEDO = col.rgb;
	ALPHA = col.a;
	ROUGHNESS = 0.08;
	METALLIC = 0.4;
}
"""
	var wm := ShaderMaterial.new()
	wm.shader = wsh
	water.material_override = wm
	add_child(water)
	# причал + яхта (у дальнего края воды)
	_box(self, Vector3(8, 0.3, 200), Vector3(2.6, 0.3, 16), m_log, false)
	var boat := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.4, 1.3, 7.0)
	boat.mesh = bm
	boat.position = Vector3(8, 0.85, 214)
	boat.material_override = _mat(Color(0.7, 0.65, 0.5))
	add_child(boat)
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.12
	mm.bottom_radius = 0.14
	mm.height = 6.0
	mast.mesh = mm
	mast.position = Vector3(8, 3.5, 214)
	mast.material_override = m_log
	add_child(mast)
	_dock_lantern(Vector3(5.0, 0, 195))   # фонарь у входа на причал — маяк точки побега
	# деревянный мост на подходе к причалу
	var brp := "res://art/models/props/bridge_wood.glb"
	if ResourceLoader.exists(brp):
		var br: Node3D = load(brp).instantiate()
		br.scale = Vector3(2.6, 2.6, 2.6)
		br.position = Vector3(8, 0.05, 189)
		add_child(br)

func _dock_lantern(pos: Vector3) -> void:
	var wood := _mat(Color(0.34, 0.24, 0.15))
	var post := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.1
	pc.bottom_radius = 0.13
	pc.height = 3.0
	post.mesh = pc
	post.position = pos + Vector3(0, 1.5, 0)
	post.material_override = wood
	add_child(post)
	_box(self, pos + Vector3(0.28, 2.9, 0), Vector3(0.65, 0.1, 0.1), wood, false)   # кронштейн
	_box(self, pos + Vector3(0.55, 2.72, 0), Vector3(0.32, 0.42, 0.32), _mat(Color(0.25, 0.2, 0.12)), false)   # корпус
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.15
	lm.height = 0.3
	lamp.mesh = lm
	lamp.position = pos + Vector3(0.55, 2.7, 0)
	var em := _emissive_mat(Color(1.0, 0.85, 0.5), Color(1.0, 0.8, 0.45), 3.0)
	lamp.material_override = em
	add_child(lamp)
	_add_light(pos + Vector3(0.55, 2.7, 0), Color(1.0, 0.8, 0.5), 2.2, 13.0)

func _make_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.0, 16)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	cs.shape = cap
	player.add_child(cs)
	add_child(player)
	cam = Camera3D.new()
	cam.fov = 75.0
	cam.position = Vector3(0, 0.7, 0)
	player.add_child(cam)
	# падающие листья вокруг игрока (атмосфера, на уровне глаз)
	if not _autoplay:
		var leaves := CPUParticles3D.new()
		leaves.position = Vector3(0, 4, 0)
		leaves.local_coords = false   # листья живут в мире (не «качаются» при повороте камеры)
		leaves.amount = 30
		leaves.lifetime = 7.0
		leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		leaves.emission_box_extents = Vector3(8, 4, 8)   # объём по высоте → листья на всех уровнях
		leaves.direction = Vector3(0.3, -1, 0.1)
		leaves.spread = 25.0
		leaves.gravity = Vector3(0.5, -1.1, 0.2)   # медленное падение + снос ветром
		leaves.initial_velocity_min = 0.3
		leaves.initial_velocity_max = 0.8
		leaves.angular_velocity_min = -120.0
		leaves.angular_velocity_max = 120.0
		leaves.scale_amount_min = 0.7
		leaves.scale_amount_max = 1.3
		var lmesh := BoxMesh.new()
		lmesh.size = Vector3(0.34, 0.02, 0.22)
		leaves.mesh = lmesh
		var lgrad := Gradient.new()
		lgrad.set_color(0, Color(0.45, 0.55, 0.20, 0.9))
		lgrad.set_color(1, Color(0.55, 0.40, 0.15, 0.0))
		leaves.color_ramp = lgrad
		var lmat := StandardMaterial3D.new()
		lmat.vertex_color_use_as_albedo = true
		lmat.albedo_color = Color(0.5, 0.52, 0.22)
		lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		leaves.material_override = lmat
		player.add_child(leaves)
		# светлячки вокруг игрока — включаются ночью (см. _day_night)
		fireflies = CPUParticles3D.new()
		fireflies.position = Vector3(0, 1.0, 0)
		fireflies.local_coords = false
		fireflies.amount = 8 if _mobile else 24
		fireflies.lifetime = 4.5
		fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		fireflies.emission_box_extents = Vector3(10, 2.5, 10)
		fireflies.gravity = Vector3.ZERO
		fireflies.direction = Vector3(0, 1, 0)
		fireflies.spread = 180.0
		fireflies.initial_velocity_min = 0.15
		fireflies.initial_velocity_max = 0.5
		var fmesh := QuadMesh.new()
		fmesh.size = Vector2(0.11, 0.11)
		fireflies.mesh = fmesh
		var fgrad := Gradient.new()
		fgrad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		fgrad.colors = PackedColorArray([Color(0.85, 1.0, 0.45, 0.0), Color(0.85, 1.0, 0.45, 1.0), Color(0.85, 1.0, 0.45, 0.0)])
		fireflies.color_ramp = fgrad
		var fmat := StandardMaterial3D.new()
		fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		fmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		fmat.vertex_color_use_as_albedo = true
		fmat.emission_enabled = true
		fmat.emission = Color(0.75, 1.0, 0.4)
		fmat.emission_energy_multiplier = 3.2
		fireflies.material_override = fmat
		fireflies.emitting = false
		player.add_child(fireflies)
		# пыльца/споры в воздухе днём — мягкие светлые пылинки (см. _day_night)
		pollen = CPUParticles3D.new()
		pollen.position = Vector3(0, 1.6, 0)
		pollen.local_coords = false
		pollen.amount = 10 if _mobile else 30
		pollen.lifetime = 6.0
		pollen.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		pollen.emission_box_extents = Vector3(9, 3.0, 9)
		pollen.gravity = Vector3(0.15, -0.05, 0.1)   # почти парят, лёгкий снос
		pollen.direction = Vector3(0, 0, 0)
		pollen.spread = 180.0
		pollen.initial_velocity_min = 0.05
		pollen.initial_velocity_max = 0.25
		var pmesh := QuadMesh.new()
		pmesh.size = Vector2(0.045, 0.045)
		pollen.mesh = pmesh
		var pgrad := Gradient.new()
		pgrad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		pgrad.colors = PackedColorArray([Color(1.0, 0.98, 0.85, 0.0), Color(1.0, 0.98, 0.85, 0.5), Color(1.0, 0.98, 0.85, 0.0)])
		pollen.color_ramp = pgrad
		var pmat := StandardMaterial3D.new()
		pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		pmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		pmat.vertex_color_use_as_albedo = true
		pmat.albedo_color = Color(1.0, 0.98, 0.85)
		pollen.material_override = pmat
		pollen.emitting = false
		player.add_child(pollen)

func _small_sphere(pos: Vector3, r: float, col: Color) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 1.7
	m.mesh = sm
	m.position = pos
	m.material_override = _mat(col)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)

func _collect_meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out += _collect_meshes(c)
	return out

func _make_timokha() -> void:
	# человечек-примитив, СТОИТ НА ЗЕМЛЕ: origin на y=1.0, ступни на 0.
	timokha = CharacterBody3D.new()
	timokha.position = Vector3(0, 1.0, -4)
	timokha_mat = _mat(Color(0.86, 0.25, 0.20))
	var pants := _mat(Color(0.20, 0.18, 0.24))
	var skin := _mat(Color(0.85, 0.62, 0.46))
	# тень-кружок под ногами (заземляет модель, помогает заметить угрозу)
	var shadow := MeshInstance3D.new()
	var sd := CylinderMesh.new()
	sd.top_radius = 0.95
	sd.bottom_radius = 0.95
	sd.height = 0.02
	shadow.mesh = sd
	shadow.position = Vector3(0, -0.98, 0)   # world ~0.02 над землёй
	var shmat := StandardMaterial3D.new()
	shmat.albedo_color = Color(0.0, 0.0, 0.0, 0.38)
	shmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = shmat
	timokha.add_child(shadow)
	var model_path := "res://art/models/character/mishganchik.fbx"
	var tex_path := "res://art/mishganchik.png"
	if ResourceLoader.exists(model_path):
		# реальная 3D-модель со скелетом и анимацией бега
		var ps: PackedScene = load(model_path)
		var mdl: Node3D = ps.instantiate()
		mdl.scale = Vector3.ONE * TK_MODEL_SCALE
		mdl.position = Vector3(0, -1.0, 0)   # origin модели в ногах; timokha origin y=1.0 → ступни на земле
		mdl.rotation.y = PI                   # нативный фронт модели = +Z; look_at целит −Z в игрока → разворот на 180° = лицом к игроку в погоне
		timokha.add_child(mdl)
		tk_model = mdl
		var ap: Node = mdl.find_child("AnimationPlayer", true, false)
		if ap is AnimationPlayer:
			tk_anim = ap
			var lst := tk_anim.get_animation_list()
			if lst.size() > 0:
				tk_anim_name = lst[0]
				# классифицируем клипы по имени (на будущее: пользователь добавит idle/walk)
				for nm in lst:
					var clip: Animation = tk_anim.get_animation(nm)
					clip.loop_mode = Animation.LOOP_LINEAR   # все клипы зациклены
					var low := String(nm).to_lower()
					if tk_clip_idle == "" and (low.contains("idle") or low.contains("stand") or low.contains("tpose") or low.contains("rest")):
						tk_clip_idle = nm
					elif tk_clip_walk == "" and low.contains("walk"):
						tk_clip_walk = nm
					elif tk_clip_run == "" and (low.contains("run") or low.contains("jog") or low.contains("sprint") or low.contains("chase")):
						tk_clip_run = nm
				if tk_clip_run == "":
					tk_clip_run = tk_anim_name   # клип из основного FBX = бег
				# подключить idle/walk из лёгкой внешней библиотеки (без дублей мешей)
				var extra_path := "res://art/models/character/extra_anims.res"
				if ResourceLoader.exists(extra_path):
					var extra: AnimationLibrary = load(extra_path)
					var lib: AnimationLibrary = tk_anim.get_animation_library("")
					if lib == null:
						lib = AnimationLibrary.new()
						tk_anim.add_animation_library("", lib)
					if extra != null:
						for an in extra.get_animation_list():
							if not lib.has_animation(an):
								lib.add_animation(an, extra.get_animation(an))
					if tk_anim.has_animation("idle"):
						tk_clip_idle = "idle"
					if tk_anim.has_animation("walk"):
						tk_clip_walk = "walk"
		# жуткая холодная подсветка — заметен ночью (когда охотится), днём выключена
		tk_glow = OmniLight3D.new()
		tk_glow.position = Vector3(0, 1.45, -0.6)   # спереди-сверху (−Z = look_at к игроку) → мягко освещает всё тело
		tk_glow.light_color = Color(0.74, 0.84, 1.0)   # бледно-лунный, нездоровый
		tk_glow.omni_range = 9.0
		tk_glow.omni_attenuation = 0.5   # пологое затухание = ровный мягкий свет, без горячего пятна/bloom
		tk_glow.light_energy = 0.0
		tk_glow.shadow_enabled = false
		timokha.add_child(tk_glow)
		# эмиссия по собственной текстуре — Мишганчик светится в темноте (видимость ночью)
		tk_mats.clear()
		for mi in _collect_meshes(mdl):
			if mi.mesh == null:
				continue
			for s in mi.mesh.get_surface_count():
				var base: Material = mi.mesh.surface_get_material(s)
				if base is StandardMaterial3D:
					var dup: StandardMaterial3D = base.duplicate()
					dup.emission_enabled = true
					if dup.albedo_texture != null:
						dup.emission_texture = dup.albedo_texture   # светится своей же текстурой
					dup.emission = Color(1, 1, 1)
					dup.emission_energy_multiplier = 0.0            # рулится в _day_night по ночи
					mi.set_surface_override_material(s, dup)
					tk_mats.append(dup)
	elif ResourceLoader.exists(tex_path):
		# реальная модель-вырез Мишганчика как билборд-спрайт (всегда лицом к камере)
		var spr := Sprite3D.new()
		spr.texture = load(tex_path)
		spr.pixel_size = 0.001344   # ×1.2 — ~2.55 м роста (высота текстуры 1900 px)
		spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y   # к камере, но стоит вертикально
		spr.shaded = true                                  # реагирует на свет/туман (вписывается в сцену)
		spr.double_sided = true
		spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD     # корректная глубина, без проблем сортировки
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tk_sprite_y = 1900.0 * 0.001344 * 0.5 - 1.0        # центр так, чтобы ступни были на земле
		spr.position = Vector3(0, tk_sprite_y, 0)
		tk_sprite = spr
		timokha.add_child(spr)
	else:
		# запасной примитив-человечек (если текстуры нет)
		for sx in [-0.22, 0.22]:
			var hip := Node3D.new()
			hip.position = Vector3(sx, 0.0, 0)
			timokha.add_child(hip)
			var leg := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(0.3, 1.0, 0.34)
			leg.mesh = lb
			leg.position = Vector3(0, -0.5, 0)
			leg.material_override = pants
			hip.add_child(leg)
			tk_legs.append(hip)
		var torso := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(0.86, 0.95, 0.5)
		torso.mesh = tb
		torso.position = Vector3(0, 0.38, 0)
		torso.material_override = timokha_mat
		timokha.add_child(torso)
		for sx in [-0.56, 0.56]:
			var sh := Node3D.new()
			sh.position = Vector3(sx, 0.78, 0)
			timokha.add_child(sh)
			var arm := MeshInstance3D.new()
			var ab := BoxMesh.new()
			ab.size = Vector3(0.2, 0.85, 0.22)
			arm.mesh = ab
			arm.position = Vector3(0, -0.42, 0)
			arm.material_override = timokha_mat
			sh.add_child(arm)
			tk_arms.append(sh)
		var head := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 0.32
		hs.height = 0.64
		head.mesh = hs
		head.position = Vector3(0, 1.05, 0)
		head.material_override = skin
		timokha.add_child(head)
		var nose := MeshInstance3D.new()
		var nb := BoxMesh.new()
		nb.size = Vector3(0.16, 0.16, 0.2)
		nose.mesh = nb
		nose.position = Vector3(0, 1.02, -0.34)
		nose.material_override = skin
		timokha.add_child(nose)
		var hat := MeshInstance3D.new()
		var hb := BoxMesh.new()
		hb.size = Vector3(0.72, 0.26, 0.72)
		hat.mesh = hb
		hat.position = Vector3(0, 1.38, 0)
		hat.material_override = _mat(Color(0.45, 0.12, 0.1))
		timokha.add_child(hat)
	var cs := CollisionShape3D.new()
	var cc := CapsuleShape3D.new()
	cc.radius = 0.45
	cc.height = 2.0
	cs.shape = cc
	timokha.add_child(cs)
	add_child(timokha)

func _build_quests() -> void:
	_add_quest("wood1", Vector3(70, 0, -65), "Наруби дров (1)", "wood")
	_add_quest("wood2", Vector3(-110, 0, -130), "Наруби дров (2)", "wood")
	_add_quest("herb1", Vector3(-85, 0, 75), "Собери травы (1)", "herb")
	_add_quest("herb2", Vector3(130, 0, 100), "Собери травы (2)", "herb")
	_add_quest("cucumber", Vector3(160, 0, -55), "Накорми Мишганчика огурцом", "task")
	_add_quest("water", Vector3(-170, 0, -45), "Набери воды Гене", "task")
	_add_quest("berries", Vector3(55, 0, 170), "Набери ягод", "task")
	_add_quest("mushroom", Vector3(-60, 0, -185), "Собери грибы", "task")
	_add_quest("fish", Vector3(15, 0, 188), "Налови рыбы", "task")
	_add_quest("chickens", Vector3(135, 0, -150), "Покорми кур", "task")
	_add_quest("fence", Vector3(-135, 0, 150), "Почини забор", "task")
	_add_quest("potato", Vector3(95, 0, 38), "Накопай картошки", "task")
	_add_quest("apples", Vector3(-42, 0, 120), "Собери яблоки", "task")
	_add_quest("banya", Vector3(176, 0, 28), "Затопи баню", "task")
	_add_quest("bones", Vector3(-150, 0, 92), "Похорони кости", "task")
	_add_quest("brew", Vector3(-1.8, 0, -2.8), "Свари варево (2 дрова + 2 травы)", "brew")
	_add_quest("yacht", Vector3(8, 0, WORLD - 15.0), "Почини яхту — побег!", "yacht")
	# пропсы у точек
	_woodpile(Vector3(72, 0, -66))
	_axe_stump(Vector3(68, 0, -63))
	_woodpile(Vector3(-108, 0, -131))
	_axe_stump(Vector3(-112, 0, -128))
	_bushes(Vector3(-85, 0, 75), Color(0.2, 0.45, 0.18))
	_bushes(Vector3(130, 0, 100), Color(0.2, 0.45, 0.18))
	_bushes(Vector3(55, 0, 170), Color(0.55, 0.12, 0.2))
	_bushes(Vector3(-60, 0, -185), Color(0.7, 0.62, 0.5))
	_axe_stump(Vector3(158, 0, -53))
	var cuc := MeshInstance3D.new()
	var csm := SphereMesh.new()
	csm.radius = 0.4
	csm.height = 0.5
	cuc.mesh = csm
	cuc.scale = Vector3(1.0, 1.0, 2.4)
	cuc.position = Vector3(160, 0.9, -55)
	cuc.material_override = _mat(Color(0.30, 0.55, 0.18))
	add_child(cuc)
	_box(self, Vector3(-170, 0.6, -45), Vector3(1.6, 1.2, 1.6), m_rock, true)
	var roof := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(1.8, 0.2, 1.8)
	roof.mesh = rb
	roof.position = Vector3(-170, 2.6, -45)
	roof.material_override = _mat(Color(0.4, 0.25, 0.16))
	add_child(roof)
	# курятник + куры
	_box(self, Vector3(135, 0.6, -152), Vector3(2.2, 1.2, 1.6), m_log, true)
	for c in [Vector3(-1.2, 0, 1.0), Vector3(0.4, 0, 1.4), Vector3(1.4, 0, 0.7)]:
		var ch := MeshInstance3D.new()
		var csm2 := SphereMesh.new()
		csm2.radius = 0.25
		csm2.height = 0.45
		ch.mesh = csm2
		ch.position = Vector3(135, 0.3, -150) + c
		ch.material_override = _mat(Color(0.92, 0.9, 0.82))
		ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ch)
	# забор (столбы + перекладина)
	for i in 6:
		_box(self, Vector3(-138.0 + float(i) * 1.6, 0.8, 150), Vector3(0.2, 1.6, 0.2), m_log, false)
	_box(self, Vector3(-134.0, 1.25, 150), Vector3(9.6, 0.14, 0.12), m_log, false)
	# огород-картошка (95,38): грядки + клубни
	for i in 4:
		_box(self, Vector3(93.0 + float(i) * 1.3, 0.15, 38.0), Vector3(1.0, 0.3, 3.0), _mat(Color(0.34, 0.24, 0.16)), false)
	for p in [Vector3(94, 0.2, 37), Vector3(96, 0.2, 39), Vector3(95, 0.2, 36.5)]:
		_small_sphere(p, 0.18, Color(0.72, 0.6, 0.4))
	# яблоня + яблоки (-42,120)
	_tree(Vector3(-42, 0, 121.6), 1.6, true)
	for a in [Vector3(-43, 0.2, 120), Vector3(-41, 0.2, 119.2), Vector3(-42.6, 0.2, 121), Vector3(-40.6, 0.2, 120.6)]:
		_small_sphere(a, 0.16, Color(0.82, 0.16, 0.12))
	for ca in [Vector3(-43.2, 4.6, 121), Vector3(-41.0, 4.9, 122.4), Vector3(-42.8, 5.2, 120.6), Vector3(-40.7, 4.4, 121.3), Vector3(-42.1, 5.5, 122.0)]:
		_small_sphere(ca, 0.17, Color(0.82, 0.16, 0.12))   # яблоки в кроне
	# баня (176,28): сруб + крыша + труба
	_box(self, Vector3(176, 1.1, 28), Vector3(4.0, 2.2, 3.2), m_log, true)
	var broof := MeshInstance3D.new()
	var brm := BoxMesh.new()
	brm.size = Vector3(4.4, 0.3, 3.6)
	broof.mesh = brm
	broof.position = Vector3(176, 2.35, 28)
	broof.material_override = _mat(Color(0.38, 0.26, 0.16))
	add_child(broof)
	_box(self, Vector3(177.4, 3.0, 28), Vector3(0.5, 1.4, 0.5), m_rock, false)
	_smoke(Vector3(177.4, 3.9, 28), 12, 3.6, Vector3(0.25, 0.4, 0.0), 0.4, 0.9, 0.3, 10.0, 0.4, 0.9)   # дым из бани
	# кости (-150,92): могильный холм + покосившийся крест + череп + кости
	_box(self, Vector3(-150, 0.18, 92), Vector3(2.4, 0.35, 1.4), _mat(Color(0.30, 0.22, 0.14)), false)   # холм
	var cr := Node3D.new()
	cr.position = Vector3(-150, 0, 90.8)
	cr.rotation.z = deg_to_rad(8.0)
	add_child(cr)
	_box(cr, Vector3(0, 0.9, 0), Vector3(0.16, 1.8, 0.16), _mat(Color(0.30, 0.20, 0.12)), false)
	_box(cr, Vector3(0, 1.25, 0), Vector3(0.8, 0.16, 0.16), _mat(Color(0.30, 0.20, 0.12)), false)
	_small_sphere(Vector3(-150, 0.45, 92), 0.32, Color(0.85, 0.82, 0.74))
	for b in [Vector3(-148.8, 0.12, 92.7), Vector3(-150.8, 0.12, 91.3), Vector3(-149.3, 0.12, 91.0), Vector3(-151.1, 0.12, 92.4)]:
		_box(self, b, Vector3(0.7, 0.12, 0.12), _mat(Color(0.82, 0.79, 0.7)), false)

func _bushes(pos: Vector3, col: Color) -> void:
	for i in 6:
		var bush := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.4
		sm.height = 0.6
		bush.mesh = sm
		bush.position = pos + Vector3(sin(float(i) * 1.7) * 1.8, 0.4, cos(float(i) * 1.7) * 1.8)
		bush.material_override = _mat(col)
		bush.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(bush)

func _add_quest(id: String, pos: Vector3, label: String, kind: String) -> void:
	quests.append({"id": id, "pos": pos, "label": label, "kind": kind, "done": false, "prog": 0.0})
	# маяк-столб света (видно в тумане)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.25
	cm.bottom_radius = 0.25
	cm.height = 16.0
	beam.mesh = cm
	beam.position = pos + Vector3(0, 8.0, 0)
	var bmat := _mat(Color(0.95, 0.8, 0.2, 0.35))
	bmat.emission_enabled = true
	bmat.emission = Color(0.95, 0.75, 0.2)
	bmat.emission_energy_multiplier = 1.2
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = bmat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	quests[quests.size() - 1]["beam_mat"] = bmat
	# плавающая надпись
	var l := Label3D.new()
	l.text = label
	l.position = pos + Vector3(0, 2.6, 0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 64
	l.outline_size = 16
	l.modulate = Color(1, 0.95, 0.6)
	l.no_depth_test = true
	add_child(l)

func _build_rain() -> void:
	rain = GPUParticles3D.new()
	rain.amount = 200 if _mobile else 900   # меньше капель на телефоне
	rain.lifetime = 1.2
	rain.local_coords = false
	rain.position = Vector3(0, 16, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 0.0
	pm.gravity = Vector3(0, -34, 0)
	pm.initial_velocity_min = 14.0
	pm.initial_velocity_max = 18.0
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(26, 0.5, 26)
	rain.process_material = pm
	var streak := BoxMesh.new()
	streak.size = Vector3(0.025, 0.6, 0.025)
	var rmat := _mat(Color(0.72, 0.78, 0.85, 0.6))
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak.material = rmat
	rain.draw_pass_1 = streak
	add_child(rain)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# виньетка по краям: базовый кинотон + усиление с близостью Мишганчика ночью (хоррор)
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vsh := Shader.new()
	vsh.code = """shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.42;
void fragment() {
	float r = distance(UV, vec2(0.5)) * 1.32;
	float v = smoothstep(0.42, 0.95, r) * strength;
	COLOR = vec4(0.0, 0.0, 0.0, v);
}
"""
	var vmat := ShaderMaterial.new()
	vmat.shader = vsh
	vmat.set_shader_parameter("strength", 0.42)
	vignette.material = vmat
	layer.add_child(vignette)
	danger_overlay = ColorRect.new()
	danger_overlay.color = Color(0.8, 0.05, 0.05, 0.0)
	danger_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(danger_overlay)
	catch_flash = ColorRect.new()
	catch_flash.color = Color(1, 0.1, 0.1, 0.0)
	catch_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	catch_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(catch_flash)
	light_flash = ColorRect.new()
	light_flash.color = Color(0.85, 0.9, 1.0, 0.0)
	light_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	light_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(light_flash)
	hud = Label.new()
	hud.position = Vector2(26, 18)
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud)
	# прицел (динамический: зелёный у квеста, красный-пульс когда Тимоха видит)
	crosshair = ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.7)
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_crosshair_size(5.0)
	layer.add_child(crosshair)
	var vp := get_viewport().get_visible_rect().size
	# HUD-луна: мягкое гало + бледный диск с «морем», проявляется ночью (вверху)
	moon_hud = Control.new()
	moon_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon_hud.modulate = Color(1, 1, 1, 0.0)
	layer.add_child(moon_hud)
	var mcx := vp.x * 0.66
	var mcy := vp.y * 0.15
	var glow := Panel.new()
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(0.75, 0.83, 1.0, 0.16)
	gs.set_corner_radius_all(80)
	glow.add_theme_stylebox_override("panel", gs)
	glow.size = Vector2(160, 160)
	glow.position = Vector2(mcx - 80, mcy - 80)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon_hud.add_child(glow)
	var disc := Panel.new()
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.88, 0.92, 1.0, 0.94)
	ds.set_corner_radius_all(34)
	disc.add_theme_stylebox_override("panel", ds)
	disc.size = Vector2(68, 68)
	disc.position = Vector2(mcx - 34, mcy - 34)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon_hud.add_child(disc)
	var mare := Panel.new()
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(0.74, 0.80, 0.94, 0.55)
	ms.set_corner_radius_all(12)
	mare.add_theme_stylebox_override("panel", ms)
	mare.size = Vector2(22, 22)
	mare.position = Vector2(mcx - 4, mcy - 14)
	mare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moon_hud.add_child(mare)
	# звёзды рядом с луной (проявляются ночью вместе с moon_hud, лёгкое мерцание в _process)
	var srng := RandomNumberGenerator.new()
	srng.seed = 424242
	for i in 16:
		var st := ColorRect.new()
		var ssz := srng.randf_range(2.0, 3.6)
		st.color = Color(0.9, 0.94, 1.0, srng.randf_range(0.5, 0.95))
		st.size = Vector2(ssz, ssz)
		st.position = Vector2(srng.randf_range(vp.x * 0.04, vp.x * 0.96), srng.randf_range(vp.y * 0.03, vp.y * 0.34))
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moon_hud.add_child(st)
		star_dots.append(st)
	layer.move_child(moon_hud, 0)   # за остальным HUD (вспышки/текст поверх)
	hb_wood = _hotbar_slot(layer, Vector2(vp.x * 0.5 - 96, vp.y - 96), Color(0.5, 0.36, 0.2), "Дрова")
	hb_herbs = _hotbar_slot(layer, Vector2(vp.x * 0.5 + 8, vp.y - 96), Color(0.25, 0.5, 0.22), "Травы")
	done_label = Label.new()
	done_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	done_label.offset_top = vp.y * 0.42
	done_label.offset_bottom = vp.y * 0.42 + 80
	done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	done_label.add_theme_font_size_override("font_size", 50)
	done_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	done_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	done_label.add_theme_constant_override("outline_size", 8)
	done_label.modulate.a = 0.0
	layer.add_child(done_label)
	# прогресс-бар квестов сверху по центру
	var bw := 340.0
	var qbg := ColorRect.new()
	qbg.color = Color(0, 0, 0, 0.45)
	qbg.position = Vector2(vp.x * 0.5 - bw * 0.5, 10)
	qbg.size = Vector2(bw, 24)
	layer.add_child(qbg)
	qbar_bg = qbg
	qbar_fill = ColorRect.new()
	qbar_fill.color = Color(0.3, 0.8, 0.4, 0.85)
	qbar_fill.position = Vector2(vp.x * 0.5 - bw * 0.5, 10)
	qbar_fill.size = Vector2(0, 24)
	layer.add_child(qbar_fill)
	qbar_label = Label.new()
	qbar_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	qbar_label.offset_top = 11
	qbar_label.offset_bottom = 33
	qbar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qbar_label.add_theme_font_size_override("font_size", 16)
	qbar_label.add_theme_color_override("font_color", Color(1, 1, 1))
	qbar_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	qbar_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(qbar_label)
	# счётчик поимок под прогресс-баром
	catch_label = Label.new()
	catch_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	catch_label.offset_top = 38
	catch_label.offset_bottom = 58
	catch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	catch_label.add_theme_font_size_override("font_size", 15)
	catch_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5))
	catch_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	catch_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(catch_label)
	# квест-зона: компас к цели + прогресс текущего дела (верх-центр, под счётчиком)
	quest_panel = Label.new()
	quest_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	quest_panel.offset_top = 60
	quest_panel.offset_bottom = 110
	quest_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_panel.add_theme_font_size_override("font_size", 18)
	quest_panel.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	quest_panel.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	quest_panel.add_theme_constant_override("outline_size", 5)
	layer.add_child(quest_panel)
	# подсказка-прогресс у прицела при подходе к квесту
	quest_prompt = Label.new()
	quest_prompt.set_anchors_preset(Control.PRESET_TOP_WIDE)
	quest_prompt.offset_top = vp.y * 0.54
	quest_prompt.offset_bottom = vp.y * 0.54 + 24
	quest_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_prompt.add_theme_font_size_override("font_size", 18)
	quest_prompt.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	quest_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	quest_prompt.add_theme_constant_override("outline_size", 5)
	quest_prompt.visible = false
	layer.add_child(quest_prompt)
	var qpw := 220.0
	qp_bg = ColorRect.new()
	qp_bg.color = Color(0, 0, 0, 0.5)
	qp_bg.position = Vector2(vp.x * 0.5 - qpw * 0.5, vp.y * 0.54 + 28)
	qp_bg.size = Vector2(qpw, 12)
	qp_bg.visible = false
	layer.add_child(qp_bg)
	qp_fill = ColorRect.new()
	qp_fill.color = Color(0.45, 0.85, 0.5, 0.9)
	qp_fill.position = qp_bg.position
	qp_fill.size = Vector2(0, 12)
	qp_fill.visible = false
	layer.add_child(qp_fill)
	# стартовая подсказка-туториал (первые ~9 с, текст ставится в _ready по show_touch)
	tutorial_label = Label.new()
	tutorial_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tutorial_label.offset_top = vp.y * 0.16
	tutorial_label.offset_bottom = vp.y * 0.16 + 96
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.add_theme_font_size_override("font_size", 20)
	tutorial_label.add_theme_color_override("font_color", Color(1, 1, 1))
	tutorial_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tutorial_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(tutorial_label)
	# кнопка паузы (угол, под радаром) — для тача и мыши
	var pbtn := Button.new()
	pbtn.position = Vector2(vp.x - 70, 220)
	pbtn.size = Vector2(52, 52)
	pbtn.pressed.connect(_toggle_pause)
	layer.add_child(pbtn)
	pause_btn = pbtn
	for bx in [-8.0, 4.0]:
		var bar := ColorRect.new()
		bar.color = Color(0.95, 0.95, 1.0, 0.92)
		bar.size = Vector2(6, 22)
		bar.position = Vector2(26.0 + bx, 15.0)   # относительно кнопки
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pbtn.add_child(bar)
	# оверлей победы
	win_overlay = ColorRect.new()
	win_overlay.color = Color(0.02, 0.05, 0.03, 0.72)
	win_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_overlay.visible = false
	layer.add_child(win_overlay)
	win_label = Label.new()
	win_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_label.add_theme_font_size_override("font_size", 44)
	win_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	win_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	win_label.add_theme_constant_override("outline_size", 8)
	win_label.visible = false
	layer.add_child(win_label)
	restart_btn = Button.new()
	restart_btn.text = "Играть снова"
	restart_btn.size = Vector2(250, 60)
	restart_btn.position = Vector2(vp.x * 0.5 - 260, vp.y - 150)
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.visible = false
	restart_btn.pressed.connect(_restart_game)
	layer.add_child(restart_btn)
	win_quit_btn = Button.new()
	win_quit_btn.text = "Выход"
	win_quit_btn.size = Vector2(250, 60)
	win_quit_btn.position = Vector2(vp.x * 0.5 + 10, vp.y - 150)
	win_quit_btn.add_theme_font_size_override("font_size", 24)
	win_quit_btn.visible = false
	win_quit_btn.pressed.connect(_quit_game)
	layer.add_child(win_quit_btn)
	# пауза-меню (поверх всего)
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.02, 0.03, 0.05, 0.78)
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	layer.add_child(pause_overlay)
	var ptitle := Label.new()
	ptitle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ptitle.offset_top = vp.y * 0.5 - 120
	ptitle.offset_bottom = vp.y * 0.5 - 70
	ptitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ptitle.add_theme_font_size_override("font_size", 42)
	ptitle.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
	ptitle.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ptitle.add_theme_constant_override("outline_size", 8)
	ptitle.text = "ПАУЗА"
	pause_overlay.add_child(ptitle)
	var btn_resume := Button.new()
	btn_resume.text = "Продолжить"
	btn_resume.size = Vector2(240, 56)
	btn_resume.position = Vector2(vp.x * 0.5 - 120, vp.y * 0.5 - 60)
	btn_resume.add_theme_font_size_override("font_size", 22)
	btn_resume.pressed.connect(_resume_game)
	pause_overlay.add_child(btn_resume)
	snd_btn = Button.new()
	snd_btn.text = "Звук: вкл"
	snd_btn.size = Vector2(240, 56)
	snd_btn.position = Vector2(vp.x * 0.5 - 120, vp.y * 0.5 + 8)
	snd_btn.add_theme_font_size_override("font_size", 22)
	snd_btn.pressed.connect(_toggle_mute)
	pause_overlay.add_child(snd_btn)
	var btn_quit := Button.new()
	btn_quit.text = "Выход"
	btn_quit.size = Vector2(240, 56)
	btn_quit.position = Vector2(vp.x * 0.5 - 120, vp.y * 0.5 + 76)
	btn_quit.add_theme_font_size_override("font_size", 22)
	btn_quit.pressed.connect(_quit_game)
	pause_overlay.add_child(btn_quit)
	# подсказка управления — только здесь, в паузе (не засоряет игровой HUD); текст ставится в _ready по show_touch
	pause_controls = Label.new()
	pause_controls.set_anchors_preset(Control.PRESET_TOP_WIDE)
	pause_controls.offset_top = vp.y * 0.5 + 156
	pause_controls.offset_bottom = vp.y * 0.5 + 240
	pause_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_controls.add_theme_font_size_override("font_size", 17)
	pause_controls.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	pause_controls.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	pause_controls.add_theme_constant_override("outline_size", 4)
	pause_overlay.add_child(pause_controls)

func _toggle_pause() -> void:
	paused = not paused
	if pause_overlay != null:
		pause_overlay.visible = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not show_touch:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _resume_game() -> void:
	if paused:
		_toggle_pause()

func _toggle_mute() -> void:
	_muted = not _muted
	AudioServer.set_bus_mute(0, _muted)   # 0 — мастер-шина
	if snd_btn != null:
		snd_btn.text = "Звук: выкл" if _muted else "Звук: вкл"

func _quit_game() -> void:
	get_tree().quit()

func _restart_game() -> void:
	get_tree().reload_current_scene()

func _hotbar_slot(layer: CanvasLayer, pos: Vector2, col: Color, name: String) -> Label:
	var box := ColorRect.new()
	box.color = Color(col.r, col.g, col.b, 0.8)
	box.position = pos
	box.size = Vector2(88, 70)
	layer.add_child(box)
	var nm := Label.new()
	nm.text = name
	nm.position = Vector2(6, 2)   # относительно box → прячется вместе со слотом
	nm.add_theme_font_size_override("font_size", 16)
	nm.add_theme_color_override("font_color", Color(1, 1, 1))
	box.add_child(nm)
	var cnt := Label.new()
	cnt.position = Vector2(34, 24)   # относительно box
	cnt.add_theme_font_size_override("font_size", 34)
	cnt.add_theme_color_override("font_color", Color(1, 1, 1))
	cnt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	cnt.add_theme_constant_override("outline_size", 5)
	cnt.text = "0"
	box.add_child(cnt)
	return cnt

func _build_touch() -> void:
	# На web is_touchscreen_available() часто врёт (true на десктопе) → показывал тач-джойстик вместо WASD/мыши.
	# На web по умолчанию десктоп-управление (клавиатура+мышь); тач — только нативный мобайл или флаг --touch.
	show_touch = _touch_flag or _mobile or (DisplayServer.is_touchscreen_available() and not OS.has_feature("web"))
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = show_touch
	layer.add_child(root)
	touch_root = root
	var vp := get_viewport().get_visible_rect().size
	joy_base = ColorRect.new()
	joy_base.color = Color(1, 1, 1, 0.16)
	joy_base.size = Vector2(180, 180)
	joy_base.position = Vector2(70, vp.y - 250)
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(joy_base)
	joy_knob = ColorRect.new()
	joy_knob.color = Color(1, 1, 1, 0.34)
	joy_knob.size = Vector2(76, 76)
	joy_knob.position = joy_base.position + joy_base.size * 0.5 - joy_knob.size * 0.5
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(joy_knob)
	# прижаты к низу-справа (на телефоне в зоне большого пальца при любой высоте экрана)
	_touch_button(root, "БЕГ", Vector2(vp.x - 185, vp.y - 215), Vector2(165, 88), true)
	_touch_button(root, "ПРЫЖОК", Vector2(vp.x - 185, vp.y - 117), Vector2(165, 88), false)

func _touch_button(root: Control, text: String, pos: Vector2, size: Vector2, is_sprint: bool) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = size
	b.size = size
	b.add_theme_font_size_override("font_size", 28)
	if is_sprint:
		b.button_down.connect(func(): touch_sprint = true)
		b.button_up.connect(func(): touch_sprint = false)
	else:
		b.button_down.connect(func(): touch_jump = true)
	root.add_child(b)

func _round_panel(diam: float, color: Color) -> Panel:
	var p := Panel.new()
	p.size = Vector2(diam, diam)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(diam * 0.5))
	p.add_theme_stylebox_override("panel", sb)
	return p

func _build_radar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	radar = Control.new()
	radar.position = Vector2(get_viewport().get_visible_rect().size.x - 212, 18)
	radar.size = Vector2(192, 192)
	layer.add_child(radar)
	# скруглённый фон с обводкой
	var bg := Panel.new()
	bg.size = radar.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bgsb := StyleBoxFlat.new()
	bgsb.bg_color = Color(0.06, 0.11, 0.08, 0.68)
	bgsb.set_corner_radius_all(14)
	bgsb.set_border_width_all(2)
	bgsb.border_color = Color(0.5, 0.68, 0.55, 0.7)
	bg.add_theme_stylebox_override("panel", bgsb)
	radar.add_child(bg)
	# слабое центральное кольцо (ориентир дальности)
	var ring := Panel.new()
	ring.size = Vector2(120, 120)
	ring.position = radar.size * 0.5 - ring.size * 0.5
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ringsb := StyleBoxFlat.new()
	ringsb.bg_color = Color(0, 0, 0, 0)
	ringsb.set_corner_radius_all(60)
	ringsb.set_border_width_all(1)
	ringsb.border_color = Color(0.5, 0.7, 0.55, 0.25)
	ring.add_theme_stylebox_override("panel", ringsb)
	radar.add_child(ring)
	# заголовок с подложкой
	var tbg := Panel.new()
	tbg.size = Vector2(58, 22)
	tbg.position = Vector2(8, 6)
	tbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0, 0, 0, 0.35)
	tsb.set_corner_radius_all(7)
	tbg.add_theme_stylebox_override("panel", tsb)
	radar.add_child(tbg)
	var title := Label.new()
	title.text = "Карта"
	title.position = Vector2(15, 6)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.82, 0.92, 0.82))
	radar.add_child(title)
	# точки квестов (круглые)
	for q in quests:
		var d := _round_panel(10.0, Color(0.95, 0.85, 0.2))
		radar.add_child(d)
		radar_dots.append(d)
	# Мишганчик (круглая красная точка)
	radar_tk = _round_panel(13.0, Color(0.95, 0.2, 0.15))
	radar.add_child(radar_tk)
	# игрок — стрелка-треугольник в центре, вращается по направлению взгляда
	radar_dir = Polygon2D.new()
	radar_dir.polygon = PackedVector2Array([Vector2(0, -9), Vector2(6.5, 7), Vector2(0, 3.5), Vector2(-6.5, 7)])
	radar_dir.color = Color(0.95, 0.97, 1.0)
	radar_dir.position = radar.size * 0.5
	radar.add_child(radar_dir)

func _update_beacons() -> void:
	var tq := _nearest_target()
	var tid := ""
	if not tq.is_empty():
		tid = tq.get("id", "")
	for q in quests:
		if not q.has("beam_mat"):
			continue
		var m: StandardMaterial3D = q["beam_mat"]
		if q["done"]:
			m.emission = Color(0.3, 0.8, 0.35)
			m.emission_energy_multiplier = 0.35
		elif q["id"] == tid:
			m.emission = Color(1.0, 0.85, 0.25)
			m.emission_energy_multiplier = 1.8 + sin(clock * 5.5) * 1.1
		else:
			m.emission = Color(0.95, 0.75, 0.2)
			m.emission_energy_multiplier = 1.0

func _update_radar() -> void:
	if radar == null or player == null:
		return
	var c := radar.size * 0.5
	# стрелка игрока: вращается по направлению взгляда (вверх = -Z)
	if radar_dir != null:
		var f := -player.global_transform.basis.z
		var fd := Vector2(f.x, f.z)
		if fd.length() > 0.01:
			fd = fd.normalized()
			radar_dir.rotation = atan2(fd.x, -fd.y)
	var radar_range := 140.0
	var sc := (radar.size.x * 0.5 - 10.0) / radar_range
	var rtq := _nearest_target()
	var rtid := "" if rtq.is_empty() else str(rtq.get("id", ""))
	for i in quests.size():
		var q = quests[i]
		var d: Panel = radar_dots[i]
		var col := Color(0.95, 0.85, 0.2)
		if q["done"]:
			col = Color(0.3, 0.8, 0.35)
		elif (q["kind"] == "brew" and (wood < 2 or herbs < 2)) or (q["kind"] == "yacht" and quests_done < quests.size() - 1):
			col = Color(0.5, 0.5, 0.55)
		var sz := 10.0
		# пульс целевой точки (та же цель, что у компаса)
		if str(q["id"]) == rtid and not q["done"]:
			sz = 10.0 + 5.0 * (0.5 + 0.5 * sin(clock * 6.0))
			col = Color(1.0, 0.95, 0.4)
		var dsb: StyleBoxFlat = d.get_theme_stylebox("panel")
		dsb.bg_color = col
		dsb.set_corner_radius_all(int(sz * 0.5))
		d.size = Vector2(sz, sz)
		var off: Vector3 = q["pos"] - player.global_position
		var p := c + Vector2(off.x, off.z) * sc
		p.x = clampf(p.x, 6.0, radar.size.x - 6.0)
		p.y = clampf(p.y, 18.0, radar.size.y - 6.0)
		d.position = p - d.size * 0.5
	# Мишганчик: красная точка, пульсирует ночью
	var to: Vector3 = timokha.global_position - player.global_position
	var tsz := 13.0
	if _is_night() and wake <= 0.0:
		tsz = 13.0 + 4.0 * (0.5 + 0.5 * sin(clock * 7.0))
	var tksb: StyleBoxFlat = radar_tk.get_theme_stylebox("panel")
	tksb.set_corner_radius_all(int(tsz * 0.5))
	radar_tk.size = Vector2(tsz, tsz)
	var tp := c + Vector2(to.x, to.z) * sc
	tp.x = clampf(tp.x, 6.0, radar.size.x - 6.0)
	tp.y = clampf(tp.y, 18.0, radar.size.y - 6.0)
	radar_tk.position = tp - radar_tk.size * 0.5

# ── ввод (мышь = взгляд) ──
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * 0.0035)
		pitch = clampf(pitch - event.relative.y * 0.0035, -1.4, 1.4)
		cam.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if won:
			get_tree().quit()
		else:
			_toggle_pause()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not show_touch and not paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif show_touch and event is InputEventScreenTouch:
		var vp := get_viewport().get_visible_rect().size
		if event.pressed:
			if event.position.x < vp.x * 0.45 and joy_id < 0:
				joy_id = event.index
				joy_origin = event.position
			elif look_id < 0:
				look_id = event.index
		else:
			if event.index == joy_id:
				joy_id = -1
				touch_move = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
	elif show_touch and event is InputEventScreenDrag:
		if event.index == joy_id:
			touch_move = ((event.position - joy_origin) / 95.0).limit_length(1.0)
		elif event.index == look_id:
			player.rotate_y(-event.relative.x * 0.005)
			pitch = clampf(pitch - event.relative.y * 0.005, -1.4, 1.4)
			cam.rotation.x = pitch

func _process(delta: float) -> void:
	if rain != null and player != null:
		rain.global_position = player.global_position + Vector3(0, 16, 0)
	if show_touch and joy_base != null:
		if joy_id >= 0:
			joy_base.position = joy_origin - joy_base.size * 0.5
		var center := joy_base.position + joy_base.size * 0.5
		joy_knob.position = center + touch_move * 62.0 - joy_knob.size * 0.5
	if catch_flash != null:
		flash_v = maxf(0.0, flash_v - delta * 1.6)
		catch_flash.color.a = flash_v * 0.5
	if done_label != null:
		done_t = maxf(0.0, done_t - delta)
		done_label.modulate.a = clampf(done_t, 0.0, 1.0)
	if danger_overlay != null:
		var dval := 0.0
		var vstr := 0.42   # базовый кинотон виньетки
		if _is_night() and wake <= 0.0 and timokha != null:
			var dd := player.global_position.distance_to(timokha.global_position)
			if dd < 24.0:
				dval = (1.0 - dd / 24.0) * 0.30 * (0.75 + 0.25 * sin(clock * 8.0))
			vstr += clampf(1.0 - dd / 38.0, 0.0, 1.0) * 0.45   # края темнеют сильнее, чем ближе Мишганчик (с 38 м)
		danger_overlay.color.a = dval
		if vignette != null and vignette.material != null:
			(vignette.material as ShaderMaterial).set_shader_parameter("strength", vstr)
	if cam != null:
		if shake > 0.0:
			shake = maxf(0.0, shake - delta * 2.2)
			cam.position = Vector3(0, 0.7, 0) + Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * (shake * 0.08)
		else:
			# покачивание головы при ходьбе (амплитуда и частота растут со скоростью)
			var hv := 0.0
			if player != null and player.is_on_floor() and stun <= 0.0:
				hv = Vector2(player.velocity.x, player.velocity.z).length()
			bob_amt = lerpf(bob_amt, clampf(hv / SPRINT, 0.0, 1.0), clampf(delta * 8.0, 0.0, 1.0))
			bob_t += delta * (hv * 1.1 + 0.001)
			var by := sin(bob_t * 2.0) * 0.05 * bob_amt    # вертикаль: двойной отскок на шаг
			var bx := sin(bob_t) * 0.035 * bob_amt         # горизонтальное покачивание
			cam.position = Vector3(bx, 0.7 + by, 0)
	if fire_light != null:   # мерцание костра
		fire_light.light_energy = 2.2 + sin(clock * 9.0) * 0.4 + sin(clock * 23.0) * 0.2
	if mill_blades != null:   # вращение крыльев мельницы
		mill_blades.rotation.z += delta * 0.6
	# молния + гром (редко, в дождь)
	if light_flash != null:
		if _light_v > 0.0:
			_light_v = maxf(0.0, _light_v - delta * 3.5)
			light_flash.color.a = _light_v
		if not paused and not won:
			_lightning_t -= delta
			if _lightning_t <= 0.0:
				_light_v = 0.7                       # вспышка
				_thunder_delay = randf_range(0.7, 1.6)   # гром с задержкой (свет быстрее звука)
				_lightning_t = randf_range(20.0, 45.0)
			if _thunder_delay > 0.0:
				_thunder_delay -= delta
				if _thunder_delay <= 0.0:
					_play(snd_thunder)
					_thunder_delay = -1.0
	if tutorial_label != null and _tut_t > 0.0:   # стартовая подсказка гаснет
		_tut_t -= delta
		tutorial_label.modulate.a = clampf(_tut_t / 3.0, 0.0, 1.0)
		if _tut_t <= 0.0:
			tutorial_label.visible = false
	for i in star_dots.size():   # мерцание звёзд
		var s: ColorRect = star_dots[i]
		s.modulate.a = 0.6 + 0.4 * sin(clock * 2.2 + i * 1.7)
	_update_radar()
	_update_beacons()
	_refresh_hud()
	if (_shot or _shotin) and not _shot_saved:
		_shot_t += delta
		if _shot_t > 1.2:
			_save_shot()

func _save_shot() -> void:
	_shot_saved = true
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://shot3d.png")
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

# ── симуляция ──
func _physics_process(delta: float) -> void:
	if won or lost or paused:
		return
	clock += delta
	nights = int(clock / DAY_LEN) + 1
	if wake > 0.0:
		wake -= delta
	if stun > 0.0:
		stun -= delta
	_day_night()
	# с наступлением ночи Тимоха появляется рядом с игроком (угроза не зависит от размера карты)
	var nownight := _is_night()
	if nownight and not _was_night and wake <= 0.0:
		var ang := randf() * TAU
		timokha.global_position = Vector3(player.global_position.x + cos(ang) * 45.0, 1.0, player.global_position.z + sin(ang) * 45.0)
		_tele = false
		_dash = false
		_cd = 2.5
		last_seen = player.global_position
		_play(snd_stinger)
		if done_label != null:
			done_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
			done_label.text = "НОЧЬ! Мишганчик рядом — беги!"
			done_t = 1.9
	if (not nownight) and _was_night and done_label != null:   # рассвет — облегчение
		done_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
		done_label.text = "Рассвет — Мишганчик ушёл, делай дела"
		done_t = 2.0
	_was_night = nownight
	# периодическое уханье совы ночью
	if _is_night():
		_owl_t -= delta
		if _owl_t <= 0.0:
			_play(snd_owl)
			_owl_t = randf_range(12.0, 26.0)
	else:
		_owl_t = randf_range(6.0, 12.0)
	if _autoplay:
		_autoplay_move(delta)
	else:
		_move_player(delta)
	_move_timokha(delta)
	_update_quests(delta)
	_check_catch()
	_audio_tick(delta)
	_footsteps(delta)
	if _autoplay:
		_ap_frames += 1
		_autoplay_log()
		if _ap_frames % 600 == 0:
			_ap_summary()   # периодически пишем прогресс в файл (переживёт kill)
		if won or _ap_frames > 12000:
			_ap_summary()
			get_tree().quit()

func _day_night() -> void:
	var t := fmod(clock, DAY_LEN) / DAY_LEN
	sun.rotation_degrees = Vector3(lerpf(-8.0, -172.0, t), -40, 0)
	# плавный коэффициент ночи (0 днём → 1 в глубокой ночи)
	var nf := clampf(smoothstep(0.48, 0.58, t) - smoothstep(0.92, 1.0, t), 0.0, 1.0)
	sun.light_energy = lerpf(1.2, 0.08, nf)
	sun.shadow_enabled = (not _mobile) and (nf < 0.5)   # на телефоне тени выкл; ночью солнце за горизонтом → тоже выкл
	env.ambient_light_energy = lerpf(0.40, 0.12, nf)   # день: ниже заливающий свет → объёмнее, не «прожектор»
	env.background_energy_multiplier = lerpf(1.0, 0.22, nf)   # затемнить само небо ночью (BG_SKY не темнел → было светло)
	env.fog_density = lerpf(0.013, 0.042, nf) + sin(clock * 0.15) * 0.0025   # день: меньше белёсой дымки
	env.fog_light_color = Color(0.70, 0.74, 0.74).lerp(Color(0.18, 0.21, 0.30), nf)   # глубже/холоднее/темнее ночью
	if moon != null:                                   # прохладная лунная подсветка ночью
		moon.visible = nf > 0.02
		moon.light_energy = lerpf(0.0, 0.30, nf)
	if fireflies != null:                              # светлячки только ночью
		var fly := nf > 0.3
		if fireflies.emitting != fly:
			fireflies.emitting = fly
	if pollen != null:                                 # пыльца только днём
		var dayp := nf < 0.3
		if pollen.emitting != dayp:
			pollen.emitting = dayp
	if tk_glow != null:                                # мягкая фронтальная подсветка ночью → видна текстура, без пересвета/bloom
		tk_glow.light_energy = lerpf(0.0, 1.0, nf)
	for tm in tk_mats:                                 # эмиссию почти убрать (она и давала «белый»)
		var sm: StandardMaterial3D = tm
		sm.emission_energy_multiplier = lerpf(0.0, 0.04, nf)
	if moon_hud != null:                               # HUD-луна проявляется ночью
		moon_hud.modulate.a = clampf(nf, 0.0, 1.0)
	if snd_crickets != null:                           # сверчки слышны ночью
		snd_crickets.volume_db = lerpf(-60.0, -30.0, nf)
	for wm in window_mats:                              # окна избы теплеют и светятся ночью
		var m: StandardMaterial3D = wm
		m.emission = Color(0.4, 0.5, 0.6).lerp(Color(1.0, 0.72, 0.36), nf)
		m.emission_energy_multiplier = lerpf(0.3, 2.4, nf)

func _is_night() -> bool:
	return fmod(clock, DAY_LEN) / DAY_LEN > 0.52

func _move_player(delta: float) -> void:
	var fb := 0.0
	var lr := 0.0
	if stun <= 0.0 and not (_shot or _shotin):
		# физические клавиши — работают при любой раскладке (рус. раскладка ломала is_key_pressed: W→Ц)
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			fb += 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			fb -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			lr += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			lr -= 1.0
		if touch_move.length() > 0.1:
			lr += touch_move.x
			fb += -touch_move.y
	var basis := player.global_transform.basis
	var fwd := -basis.z
	fwd.y = 0
	var rgt := basis.x
	rgt.y = 0
	var move := fwd.normalized() * fb + rgt.normalized() * lr
	if move.length() > 1.0:
		move = move.normalized()
	var spd := SPEED
	if Input.is_physical_key_pressed(KEY_SHIFT) or touch_sprint:
		spd = SPRINT
	var vy := player.velocity.y - GRAVITY * delta
	if player.is_on_floor():
		if vy < 0.0:
			vy = -1.0
		if stun <= 0.0 and (Input.is_physical_key_pressed(KEY_SPACE) or touch_jump):
			vy = JUMP
	player.velocity = Vector3(move.x * spd, vy, move.z * spd)
	player.move_and_slide()
	touch_jump = false

func _move_timokha(delta: float) -> void:
	if _shot or _shotin:
		return   # заморозка для скриншотов (иначе уходит с поставленной точки)
	# ДНЁМ (и в грейс) — пассивен, бродит у избы (безопасно делать дела).
	# НОЧЬЮ — охотится: телеграф-рывок, может поймать.
	var hunting := _is_night() and wake <= 0.0
	var target := player.global_position
	var spd := 0.0
	if hunting:
		# НЕОТСТУПНАЯ ОХОТА: ночью Мишганчик всегда знает, где игрок, и бежит к нему (с любого расстояния).
		var dist := player.global_position.distance_to(timokha.global_position)
		last_seen = player.global_position
		target = player.global_position
		spd = TIMOKHA_NIGHT
		tk_aggro = _has_los()
		var close := dist < 16.0 and tk_aggro   # рывок-телеграф только вблизи и при прямой видимости
		if close:
			if not _tele and not _dash:
				_cd -= delta
				if _cd <= 0.0:
					_tele = true
					_t_tele = 0.5
			elif _tele:
				_t_tele -= delta
				if _t_tele <= 0.0:
					_tele = false
					_dash = true
					_t_dash = 0.5
			elif _dash:
				_t_dash -= delta
				if _t_dash <= 0.0:
					_dash = false
					_cd = 5.0
			if _dash:
				spd = TIMOKHA_DASH
				timokha_mat.albedo_color = Color(1.0, 0.15, 0.1)
				tk_state = "РЫВОК!"
			elif _tele:
				spd = TIMOKHA_NIGHT * 0.25
				timokha_mat.albedo_color = Color(1.0, 0.55, 0.1)
				tk_state = "готовится к рывку..."
			else:
				timokha_mat.albedo_color = Color(0.86, 0.25, 0.20)
				tk_state = "ВИДИТ ТЕБЯ!"
		else:
			# далеко или нет прямой видимости — просто неумолимо бежит на игрока, без рывка
			_tele = false
			_dash = false
			_cd = 5.0
			timokha_mat.albedo_color = Color(0.86, 0.25, 0.20)
			tk_state = "идёт на тебя..."
	else:
		_tele = false
		_dash = false
		_cd = 5.0
		spd = 1.5
		tk_state = "спит у избы" if wake > 0.0 else "бродит (день)"
		target = Vector3(3.0, timokha.global_position.y, 6.5)
		timokha_mat.albedo_color = Color(0.55, 0.45, 0.45)

	var to := target - timokha.global_position
	to.y = 0.0
	var hdir := Vector3.ZERO
	if to.length() > 0.6:
		hdir = to.normalized()
	# обход застревания: если уперся между препятствиями — временно идём вбок, не теряя цель
	if tk_detour_t > 0.0 and hdir.length() > 0.1:
		tk_detour_t -= delta
		hdir = (hdir * 0.35 + tk_detour * 0.9).normalized()
	var vy := timokha.velocity.y - GRAVITY * delta
	if timokha.is_on_floor() and vy < 0.0:
		vy = -1.0
	timokha.velocity = Vector3(hdir.x * spd, vy, hdir.z * spd)
	timokha.move_and_slide()
	# детект «застрял»: продвинулись сильно меньше ожидаемого, хотя бежали
	if spd > 2.0 and hdir.length() > 0.1:
		var moved := Vector2(timokha.global_position.x - tk_lastpos.x, timokha.global_position.z - tk_lastpos.z).length()
		if moved < spd * delta * 0.4:
			tk_stuck_t += delta
		else:
			tk_stuck_t = 0.0
		if tk_stuck_t > 0.3 and tk_detour_t <= 0.0:
			var perp := Vector3(-hdir.z, 0.0, hdir.x)   # вбок от направления на цель
			if timokha.get_slide_collision_count() > 0 and perp.dot(timokha.get_wall_normal()) < 0.0:
				perp = -perp   # в сторону от стены
			tk_detour = perp.normalized()
			tk_detour_t = 0.6
			tk_stuck_t = 0.0
	else:
		tk_stuck_t = 0.0
	tk_lastpos = timokha.global_position
	if hdir.length() > 0.1:
		timokha.look_at(timokha.global_position + hdir, Vector3.UP)
	_animate_timokha(delta)

func _animate_timokha(delta: float) -> void:
	# 3D-модель: анимацию бега ведёт AnimationPlayer; скорость воспроизведения растёт с движением
	if tk_model != null:
		if _dbg_clip != "" and tk_anim != null:   # проверочный кадр: форс конкретного клипа
			var dc := ""
			if _dbg_clip == "idle":
				dc = tk_clip_idle
			elif _dbg_clip == "walk":
				dc = tk_clip_walk
			elif _dbg_clip == "run":
				dc = tk_clip_run
			if dc != "":
				if tk_cur_clip != dc:
					tk_anim.play(dc)
					tk_cur_clip = dc
				tk_anim.speed_scale = 1.0
			return
		if tk_anim != null and tk_anim_name != "":
			var msp := Vector2(timokha.velocity.x, timokha.velocity.z).length()
			var want := ""
			if msp > 0.5:                                  # движется (ночная погоня)
				if tk_clip_walk != "" and msp < SPEED * 0.85:
					want = tk_clip_walk                     # неспешно — ходьба (если есть)
				else:
					want = tk_clip_run                      # быстро — бег
			else:
				want = tk_clip_idle                         # стоит (день/грейс) — покой, если есть клип
			if want != "":
				if want != tk_cur_clip:
					tk_anim.play(want)
					tk_cur_clip = want
				if want == tk_clip_run:
					tk_anim.speed_scale = clampf(0.65 + msp / TIMOKHA_NIGHT, 0.65, 1.8)
				else:
					tk_anim.speed_scale = 1.0
			else:
				# нет idle-клипа — замираем стоя на нейтральном кадре (вместо бега на месте)
				if tk_cur_clip != "_freeze":
					tk_anim.play(tk_clip_run)
					tk_anim.seek(0.0, true)
					tk_cur_clip = "_freeze"
				tk_anim.speed_scale = 0.0
		return
	# анимация билборд-спрайта: подпрыгивание/ковыляние + покачивание (сильнее при погоне)
	if tk_sprite != null:
		var sp := Vector2(timokha.velocity.x, timokha.velocity.z).length()
		tk_walk += delta * (1.5 + sp * 0.45)               # ниже частота — плавнее
		var amp := 0.03 + clampf(sp / TIMOKHA_NIGHT, 0.0, 1.0) * 0.06
		tk_sprite.position.y = tk_sprite_y + sin(tk_walk) * amp        # плавный sin (без резкого отскока)
		tk_sprite.position.x = sin(tk_walk * 0.5) * (0.015 + amp * 0.3)
		return
	if tk_legs.size() < 2 or tk_arms.size() < 2:
		return
	var ps := Vector2(timokha.velocity.x, timokha.velocity.z).length()
	if ps > 0.6:
		tk_walk += delta * (4.0 + ps * 0.5)
		var a := sin(tk_walk) * 0.55
		tk_legs[0].rotation.x = a
		tk_legs[1].rotation.x = -a
		tk_arms[0].rotation.x = -a
		tk_arms[1].rotation.x = a
	else:
		for n in tk_legs:
			n.rotation.x = lerpf(n.rotation.x, 0.0, 0.18)
		for n in tk_arms:
			n.rotation.x = lerpf(n.rotation.x, 0.0, 0.18)

func _update_quests(delta: float) -> void:
	for q in quests:
		if q["done"]:
			continue
		var to: Vector3 = player.global_position - q["pos"]
		if Vector2(to.x, to.z).length() < 3.2:
			# варка требует 2 дрова + 2 травы; яхта — после всех остальных
			if q["kind"] == "brew" and (wood < 2 or herbs < 2):
				continue
			if q["kind"] == "yacht" and quests_done < quests.size() - 1:
				continue
			q["prog"] += delta / 3.6
			if q["prog"] >= 1.0:
				q["done"] = true
				quests_done += 1
				if q["kind"] == "wood":
					wood += 1
				elif q["kind"] == "herb":
					herbs += 1
				if q["kind"] == "yacht":
					won = true
					_play(snd_win)
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # курсор для кнопки «Играть снова»
				else:
					_play(snd_ding)
					if catch_flash != null:
						catch_flash.color = Color(0.2, 1.0, 0.4, 0.0)
						flash_v = 0.5
					if done_label != null:
						done_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
						done_label.text = str(q["label"]) + " — готово!"
						done_t = 1.3
						# кульминация: все дела готовы → яхта открыта
						if not _yacht_announced and quests_done >= quests.size() - 1:
							_yacht_announced = true
							done_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
							done_label.text = "Все дела готовы! Чини яхту и беги!"
							done_t = 2.8

func _set_crosshair_size(s: float) -> void:
	if crosshair == null:
		return
	var h := s * 0.5
	crosshair.offset_left = -h
	crosshair.offset_top = -h
	crosshair.offset_right = h
	crosshair.offset_bottom = h

func _update_quest_prompt() -> void:
	if quest_prompt == null:
		return
	var near_q = null
	var near_d := 3.6
	for q in quests:
		if q["done"]:
			continue
		var qo: Vector3 = player.global_position - q["pos"]
		var dd := Vector2(qo.x, qo.z).length()
		if dd < near_d:
			near_d = dd
			near_q = q
	# динамический прицел: опасность > близость квеста > обычный
	if crosshair != null:
		if not won and _is_night() and wake <= 0.0 and tk_aggro:
			crosshair.color = Color(1.0, 0.2, 0.2, 0.95)
			_set_crosshair_size(7.0 + 5.0 * (0.5 + 0.5 * sin(clock * 12.0)))
		elif near_q != null and not won:
			crosshair.color = Color(0.4, 1.0, 0.5, 0.95)
			_set_crosshair_size(9.0)
		else:
			crosshair.color = Color(1, 1, 1, 0.7)
			_set_crosshair_size(5.0)
	if near_q == null or won:
		quest_prompt.visible = false
		qp_bg.visible = false
		qp_fill.visible = false
		return
	quest_prompt.visible = true
	qp_bg.visible = true
	qp_fill.visible = true
	var blocked := ""
	if near_q["kind"] == "brew" and (wood < 2 or herbs < 2):
		blocked = "нужно 2 дрова + 2 травы"
	elif near_q["kind"] == "yacht" and quests_done < quests.size() - 1:
		blocked = "сначала закончи все дела"
	if blocked != "":
		quest_prompt.text = "%s — %s" % [str(near_q["label"]), blocked]
		quest_prompt.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		qp_fill.size.x = 0.0
	else:
		quest_prompt.text = str(near_q["label"])
		quest_prompt.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
		qp_fill.size.x = 220.0 * clampf(float(near_q["prog"]), 0.0, 1.0)

func _check_catch() -> void:
	if stun > 0.0 or wake > 0.0 or not _is_night():
		return
	var to := player.global_position - timokha.global_position
	if Vector2(to.x, to.z).length() < CATCH_DIST:
		caught += 1
		lost = true                       # поймал → проигрыш (game over → рестарт)
		_play(snd_caught)
		_play(snd_laugh)                  # комичный смех Мишганчика вдогонку
		if catch_flash != null:
			catch_flash.color = Color(1.0, 0.1, 0.1, 0.0)
		flash_v = 1.0
		shake = 0.7
		player.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # курсор для кнопок экрана проигрыша

func _hide_gameplay_hud() -> void:
	# финальный экран (победа/проигрыш) — прячем игровой HUD/контролы, оставляя только итог
	for n in [hud, radar, touch_root, pause_btn, qbar_fill, qbar_label, qbar_bg, quest_panel, quest_prompt, qp_bg, qp_fill, catch_label, moon_hud, crosshair, tutorial_label, done_label]:
		if n != null:
			n.visible = false
	if hb_wood != null and hb_wood.get_parent() is CanvasItem:
		(hb_wood.get_parent() as CanvasItem).visible = false
	if hb_herbs != null and hb_herbs.get_parent() is CanvasItem:
		(hb_herbs.get_parent() as CanvasItem).visible = false

func _refresh_hud() -> void:
	if hud == null:
		return
	if hb_wood != null:
		hb_wood.text = str(wood)
	if hb_herbs != null:
		hb_herbs.text = str(herbs)
	if qbar_fill != null:
		qbar_fill.size.x = 340.0 * (float(quests_done) / float(max(1, quests.size())))
		qbar_label.text = "%d / %d дел" % [quests_done, quests.size()]
	if catch_label != null:
		catch_label.text = "Поймали: %d" % caught
		catch_label.visible = caught > 0
	_update_quest_prompt()
	if lost:
		hud.text = ""
		_hide_gameplay_hud()
		if win_overlay != null:
			win_overlay.visible = true
			win_label.visible = true
			win_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
			win_label.text = "МИШГАНЧИК ПОЙМАЛ ТЕБЯ!\n\nПродержался ночей: %d · дел: %d/%d\n\nПопробуй снова" % [nights, quests_done, quests.size()]
		if restart_btn != null:
			restart_btn.visible = true
		if win_quit_btn != null:
			win_quit_btn.visible = true
		return
	if won:
		hud.text = ""
		_hide_gameplay_hud()
		if win_overlay != null:
			win_overlay.visible = true
			win_label.visible = true
			win_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
			win_label.text = "СБЕЖАЛ НА ЯХТЕ!\n\nНочей пережито: %d\nПойман: %d раз\nВремя: %d:%02d" % [nights, caught, int(clock) / 60, int(clock) % 60]
		if restart_btn != null:
			restart_btn.visible = true
		if win_quit_btn != null:
			win_quit_btn.visible = true
		return
	var t := fmod(clock, DAY_LEN) / DAY_LEN
	var phase := ""
	if t <= 0.52:
		phase = "ДЕНЬ — делай дела (до ночи %0.0f с)" % ((0.52 - t) * DAY_LEN)
	else:
		phase = "НОЧЬ — Мишганчик охотится, беги! (до утра %0.0f с)" % ((1.0 - t) * DAY_LEN)
	if wake > 0.0:
		phase = "Мишганчик ещё спит (%0.0f с) — успей сделать дела" % wake
	# верх-лево: только статус (фаза + ресурсы). Управление — в меню паузы.
	hud.text = "Ночь %d · %s\nДрова: %d    Травы: %d" % [nights, phase, wood, herbs]
	# верх-центр: квест-зона (компас к цели + текущее дело), под прогресс-баром
	var qp := ""
	var tq := _nearest_target()
	if not tq.is_empty():
		var tp: Vector3 = tq["pos"]
		var d3: Vector3 = tp - player.global_position
		var dist := Vector2(d3.x, d3.z).length()
		var dn3 := Vector3(d3.x, 0, d3.z).normalized()
		var fwd := -player.global_transform.basis.z
		var rgt := player.global_transform.basis.x
		var fdot := fwd.x * dn3.x + fwd.z * dn3.z
		var sdot := rgt.x * dn3.x + rgt.z * dn3.z
		# ASCII-стрелки (Юникод-стрелки ↑→ нет в шрифте web-экспорта → рендерились квадратами)
		var arrow := "^"
		if fdot < -0.3:
			arrow = "v"
		elif fdot < 0.4:
			arrow = ">" if sdot > 0 else "<"
		qp = "%s  %s  (%0.0f м)" % [arrow, tq["label"], dist]
	var cq := _current_quest()
	if not cq.is_empty():
		if cq["kind"] == "brew" and (wood < 2 or herbs < 2):
			qp += "\nнужно 2 дрова + 2 травы (есть %d / %d)" % [wood, herbs]
		elif cq["kind"] == "yacht" and quests_done < quests.size() - 1:
			qp += "\nсначала закончи все дела (%d/%d)" % [quests_done, quests.size() - 1]
		else:
			qp += "\n%s %d%%" % [_bar(cq["prog"]), int(cq["prog"] * 100.0)]
	if quest_panel != null:
		quest_panel.text = qp

func _current_quest() -> Dictionary:
	var best := {}
	var bd := 3.0
	for q in quests:
		if q["done"]:
			continue
		var to: Vector3 = player.global_position - q["pos"]
		var d := Vector2(to.x, to.z).length()
		if d < bd:
			bd = d
			best = q
	return best

func _bar(f: float) -> String:
	var n := int(round(clampf(f, 0.0, 1.0) * 12.0))
	return "[" + "█".repeat(n) + "░".repeat(12 - n) + "]"

func _build_audio() -> void:
	AudioServer.set_bus_mute(0, false)   # сброс mute после reload_current_scene (mute — глобальное состояние)
	snd_rain = _make_audio_player(_load_wav("rain", true), -26.0)
	snd_heart = _make_audio_player(_load_wav("heartbeat", false), -5.0)
	snd_ding = _make_audio_player(_load_wav("ding", false), -7.0)
	snd_caught = _make_audio_player(_load_wav("caught", false), -3.0)
	snd_win = _make_audio_player(_load_wav("win", false), -3.0)
	snd_step1 = _make_audio_player(_load_wav("step1", false), -11.0)
	snd_step2 = _make_audio_player(_load_wav("step2", false), -11.0)
	snd_wind = _make_audio_player(_load_wav("wind", true), -30.0)
	snd_stinger = _make_audio_player(_load_wav("stinger", false), -3.0)
	snd_laugh = _make_audio_player(_load_wav("laugh", false), -5.0)
	snd_crickets = _make_audio_player(_load_wav("crickets", true), -60.0)   # громкость растёт ночью (в _day_night)
	snd_owl = _make_audio_player(_load_wav("owl", false), -16.0)
	snd_thunder = _make_audio_player(_load_wav("thunder", false), -7.0)
	snd_dread = _make_audio_player(_load_wav("dread", true), -60.0)   # громкость рулится в _audio_tick (саспенс)
	if snd_rain.stream != null:
		snd_rain.play()
	if snd_wind != null and snd_wind.stream != null:
		snd_wind.play()
	if snd_crickets != null and snd_crickets.stream != null:
		snd_crickets.play()
	if snd_dread != null and snd_dread.stream != null:
		snd_dread.play()

func _make_audio_player(stream: AudioStream, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	add_child(p)
	return p

func _load_wav(name: String, loop: bool) -> AudioStream:
	var path := "res://audio/sfx3d/%s.wav" % name
	if not ResourceLoader.exists(path):
		return null
	var res: Variant = load(path)
	if res is AudioStreamWAV and loop:
		res.loop_mode = AudioStreamWAV.LOOP_FORWARD
		res.loop_begin = 0
		res.loop_end = res.data.size() / 2
	if res is AudioStream:
		return res
	return null

func _play(p: AudioStreamPlayer) -> void:
	if p != null and p.stream != null:
		p.play()

func _footsteps(delta: float) -> void:
	if player == null or not player.is_on_floor() or stun > 0.0:
		step_t = 0.0
		return
	var ps := Vector2(player.velocity.x, player.velocity.z).length()
	if ps < 1.5:
		step_t = 0.0
		return
	step_t -= delta
	if step_t <= 0.0:
		step_alt = not step_alt
		var p := snd_step1 if step_alt else snd_step2
		if p != null and p.stream != null:
			p.play()
		step_t = clampf(3.4 / ps, 0.30, 0.6)

func _has_los() -> bool:
	if space == null:
		return true
	var from := timokha.global_position + Vector3(0, 1.2, 0)
	var to := player.global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [timokha.get_rid(), player.get_rid()]
	var hit := space.intersect_ray(q)
	return hit.is_empty()

func _audio_tick(delta: float) -> void:
	# тревожное сердцебиение ночью при близости Тимохи (чем ближе — тем чаще)
	if _is_night() and wake <= 0.0 and snd_heart != null and snd_heart.stream != null:
		var dist := player.global_position.distance_to(timokha.global_position)
		if dist < 24.0:
			heart_t -= delta
			if heart_t <= 0.0:
				snd_heart.volume_db = lerpf(-4.0, -15.0, clampf(dist / 24.0, 0.0, 1.0))
				snd_heart.play()
				heart_t = lerpf(0.34, 1.2, clampf(dist / 24.0, 0.0, 1.0))
			_dread_tick()
			return
	heart_t = 0.0
	_dread_tick()

func _dread_tick() -> void:
	# слендер-саспенс: дрон нарастает по близости Мишганчика И прогрессу к финалу
	if snd_dread == null:
		return
	var dd := player.global_position.distance_to(timokha.global_position)
	var prox := clampf(1.0 - dd / 45.0, 0.0, 1.0)                       # ближе → выше
	var prog := float(quests_done) / float(max(1, quests.size()))       # ближе к финалу → выше
	var tension := prox * 0.65 + prog * 0.45
	if not (_is_night() and wake <= 0.0):
		tension *= 0.25                                                 # днём почти нет
	snd_dread.volume_db = lerpf(-55.0, -11.0, clampf(tension, 0.0, 1.0))

func _autoplay_move(delta: float) -> void:
	var qid := ""
	for id in _AP_ORDER:
		var done := false
		for q in quests:
			if q["id"] == id:
				done = q["done"]
		if not done:
			qid = id
			break
	var tp := player.global_position
	if qid != "":
		for q in quests:
			if q["id"] == qid:
				tp = q["pos"]
	var to := tp - player.global_position
	to.y = 0.0
	var vy := player.velocity.y - GRAVITY * delta
	if player.is_on_floor() and vy < 0.0:
		vy = -1.0
	var move := Vector3.ZERO
	if to.length() > 2.2:
		move = to.normalized()
	player.velocity = Vector3(move.x * SPRINT, vy, move.z * SPRINT)   # бот «спринтует», как человек ночью
	player.move_and_slide()

func _autoplay_log() -> void:
	for q in quests:
		if q["done"] and not _ap_log.has(q["id"]):
			_ap_log[q["id"]] = {"t": clock, "night": nights, "caught": caught}
			print("[autoplay] done %s @ t=%.1f night=%d caught=%d" % [q["id"], clock, nights, caught])

func _ap_summary() -> void:
	var s := "won=%s clock=%.1f nights=%d caught=%d frames=%d\n" % [str(won), clock, nights, caught, _ap_frames]
	for id in _AP_ORDER:
		if _ap_log.has(id):
			var e: Dictionary = _ap_log[id]
			s += "  %s done t=%.1f night=%d\n" % [id, e["t"], e["night"]]
		else:
			s += "  %s NOT DONE\n" % id
	print("=== AUTOPLAY SUMMARY ===\n" + s)
	var f := FileAccess.open("user://autoplay_result.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(s)
		f.close()

func _nearest_target() -> Dictionary:
	var best := {}
	var bd := 1.0e9
	for q in quests:
		if q["done"]:
			continue
		if q["kind"] == "brew" and (wood < 2 or herbs < 2):
			continue
		if q["kind"] == "yacht" and quests_done < quests.size() - 1:
			continue
		var to: Vector3 = q["pos"] - player.global_position
		var d := Vector2(to.x, to.z).length()
		if d < bd:
			bd = d
			best = q
	if best.is_empty():
		for q in quests:
			if q["done"]:
				continue
			var to2: Vector3 = q["pos"] - player.global_position
			var d2 := Vector2(to2.x, to2.z).length()
			if d2 < bd:
				bd = d2
				best = q
	return best

# ── вспомогательные пропсы ──
func _woodpile(pos: Vector3) -> void:
	for i in 6:
		var log := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.18
		cm.bottom_radius = 0.18
		cm.height = 1.5
		log.mesh = cm
		log.rotation = Vector3(0, 0, PI * 0.5)
		log.position = pos + Vector3(0, 0.22 + float(i / 3) * 0.38, -0.4 + float(i % 3) * 0.4)
		log.material_override = m_log
		log.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(log)

func _axe_stump(pos: Vector3) -> void:
	var stump := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.42
	cm.bottom_radius = 0.44
	cm.height = 0.7
	stump.mesh = cm
	stump.position = pos + Vector3(0, 0.35, 0)
	stump.material_override = m_log
	add_child(stump)
	var handle := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.06, 0.7, 0.06)
	handle.mesh = hb
	handle.rotation = Vector3(0.5, 0, 0)
	handle.position = pos + Vector3(0, 0.95, 0)
	handle.material_override = _mat(Color(0.42, 0.30, 0.16))
	add_child(handle)
	var head := MeshInstance3D.new()
	var hd := BoxMesh.new()
	hd.size = Vector3(0.3, 0.22, 0.08)
	head.mesh = hd
	head.position = pos + Vector3(0, 1.2, 0.1)
	head.material_override = m_rock
	add_child(head)

func _porch(half: float, h: float) -> void:
	var z := half + 1.3
	_box(self, Vector3(0, 0.1, z), Vector3(3.4, 0.2, 2.6), m_floor, false)
	for x in [-1.5, 1.5]:
		_box(self, Vector3(x, 1.2, z + 1.0), Vector3(0.2, 2.4, 0.2), m_log, false)
	var roof := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(3.6, 0.2, 2.8)
	roof.mesh = rb
	roof.material_override = _mat(Color(0.40, 0.22, 0.16))
	roof.position = Vector3(0, 2.5, z + 0.3)
	roof.rotation_degrees = Vector3(-18, 0, 0)
	add_child(roof)

func _window(pos: Vector3) -> void:
	_box(self, pos, Vector3(0.12, 1.1, 1.3), _mat(Color(0.30, 0.20, 0.12)), false)
	var pane := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.85, 1.05)
	pane.mesh = bm
	var pm := _mat(Color(0.5, 0.6, 0.7, 0.55))
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.emission_enabled = true
	pm.emission = Color(0.4, 0.5, 0.6)
	pm.emission_energy_multiplier = 0.3
	pane.material_override = pm
	pane.position = pos
	add_child(pane)
	window_mats.append(pm)   # ночью теплеют/ярчают (в _day_night)

func _door_leaf(half: float, h: float) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(-0.9, h * 0.5 - 0.3, half)
	pivot.rotation_degrees = Vector3(0, -55, 0)
	var leaf := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.7, 2.4, 0.08)
	leaf.mesh = bm
	leaf.position = Vector3(0.85, 0, 0)
	leaf.material_override = _mat(Color(0.45, 0.30, 0.18))
	pivot.add_child(leaf)
	add_child(pivot)

func _bed(pos: Vector3) -> void:
	_box(self, pos + Vector3(0, 0.25, 0), Vector3(2.0, 0.4, 1.0), m_floor, false)
	_box(self, pos + Vector3(0, 0.55, 0), Vector3(1.9, 0.2, 0.9), _mat(Color(0.55, 0.5, 0.45)), false)
	_box(self, pos + Vector3(-0.65, 0.7, 0), Vector3(0.5, 0.18, 0.7), _mat(Color(0.9, 0.9, 0.85)), false)

func _corner_stove(pos: Vector3) -> void:
	_box(self, pos + Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 1.2), _mat(Color(0.5, 0.48, 0.46)), false)
	_box(self, pos + Vector3(0, 2.4, 0), Vector3(0.45, 0.9, 0.45), _mat(Color(0.45, 0.43, 0.42)), false)
	var fire := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.5, 0.12)
	fire.mesh = bm
	fire.position = pos + Vector3(0, 0.55, 0.62)
	var fmat := _emissive_mat(Color(1.0, 0.5, 0.1), Color(1.0, 0.45, 0.1), 2.2)
	fire.material_override = fmat
	add_child(fire)
	_add_light(pos + Vector3(0, 1.0, 0.9), Color(1.0, 0.6, 0.3), 2.2, 6.0)
