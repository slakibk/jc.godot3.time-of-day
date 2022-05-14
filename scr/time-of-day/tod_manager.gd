tool
class_name TOD_Manager extends Node

# **** Skydome ****
var _dome: TOD_Skydome = null
var _dome_ready: bool = false

var dome_path: NodePath setget _set_dome_path
func _set_dome_path(value: NodePath) -> void:
	dome_path = value
	
	if value != null:
		_dome = get_node_or_null(value) as TOD_Skydome
	
	_dome_ready = false if _dome == null else true
	_set_celestials_coords()

# **** Date Time ****
var system_sync: bool = false
var total_cycle_in_minutes: float = 15.0
var date_time_os: Dictionary

signal total_hours_changed(value)
signal day_changed(value)
signal month_changed(value)
signal year_changed(value)

var total_hours: float = 7.0 setget _set_total_hours
func _set_total_hours(value: float) -> void:
	total_hours = value
	emit_signal("total_hours_changed", value)
	if Engine.editor_hint:
		_set_celestials_coords()

var day: int = 12 setget _set_day
func _set_day(value: int) -> void:
	day = value 
	emit_signal("day_changed", value)
	if Engine.editor_hint:
		_set_celestials_coords()

var month: int = 2 setget _set_month
func _set_month(value: int) -> void:
	month = value 
	emit_signal("month_changed", value)
	if Engine.editor_hint:
		_set_celestials_coords()


var year: int = 2021 setget _set_year
func _set_year(value: int) -> void:
	year = value 
	emit_signal("year_changed", value)
	if Engine.editor_hint:
		_set_celestials_coords()

# Compute leap year.
# -
func is_learp_year() -> bool:
	return TOD_DateTimeUtil.compute_leap_year(year)

# Get max days per month.
# -
func max_days_per_month() -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		2:
			return 29 if is_learp_year() else 28
	return 30

# Get time cycle duration.
# -
func time_cycle_duration() -> float:
	return total_cycle_in_minutes * 60.0

# Get begin of time.
# -
func is_begin_of_time() -> bool:
	return year == 1 && month == 1 && day == 1

# Get end of time.
# -
func is_end_of_time() -> bool:
	return year == 9999 && month == 12 && day == 31


# **** Planetary ****
var celestials_update_time: float = 0.0
var _celestials_update_timer: float = 0.0

var celestials_calculations: int = 0 setget _set_celestials_calculations
func _set_celestials_calculations(value: int) -> void:
	celestials_calculations = value
	if Engine.editor_hint:
		_set_celestials_coords()
	
	property_list_changed_notify()

var latitude: float = 0.0 setget _set_latitude
func _set_latitude(value: float) -> void:
	latitude = value
	if Engine.editor_hint:
		_set_celestials_coords()

var longitude: float = 0.0 setget _set_longitude
func _set_longitude(value: float) -> void:
	longitude = value
	if Engine.editor_hint:
		_set_celestials_coords()

var utc: float = 0.0 setget _set_utc
func _set_utc(value: float) -> void:
	utc = value
	if Engine.editor_hint:
		_set_celestials_coords()

var compute_moon_coords: bool = false setget _set_compute_moon_coords
func _set_compute_moon_coords(value: bool) -> void:
	compute_moon_coords = value
	if Engine.editor_hint:
		_set_celestials_coords()
	
	property_list_changed_notify()

var compute_deep_space_coords: bool = false setget _set_compute_deep_space_coords
func _set_compute_deep_space_coords(value: bool) -> void:
	compute_deep_space_coords = value
	if Engine.editor_hint:
		_set_celestials_coords()

var moon_coords_offset := Vector2(0.0, 0.0) setget _set_moon_coords_offset
func _set_moon_coords_offset(value: Vector2) -> void:
	moon_coords_offset = value
	if Engine.editor_hint:
		_set_celestials_coords()

func _get_latitude_rad() -> float:
	return latitude * TOD_Math.DEG_TO_RAD

func _get_total_hours_utc() -> float:
	return total_hours - utc

func _get_time_scale() -> float:
	return (367.0 * year - (7.0 * (year + ((month + 9.0) / 12.0))) / 4.0 +\
		(275.0 * month) / 9.0 + day - 730530.0) + total_hours / 24.0

func _get_oblecl() -> float:
	return (23.4393 - 2.563e-7 * _get_time_scale()) * TOD_Math.DEG_TO_RAD

var _sun_coords:= Vector2.ZERO
var _moon_coords:= Vector2.ZERO
var _sun_distance: float
var _true_sun_longitude: float 
var _mean_sun_longitude: float
var _sideral_time: float
var _local_sideral_time: float

var _sun_orbital_elements:= TOD_OrbitalElements.new()
var _moon_orbital_elements:= TOD_OrbitalElements.new()


func _init() -> void:
	_set_total_hours(total_hours)
	_set_day(day)
	_set_month(month)
	_set_year(year)
	_set_latitude(latitude)
	_set_longitude(longitude)
	_set_utc(utc)

func _ready() -> void:
	_set_dome_path(dome_path)

func _process(delta) -> void:
	if Engine.editor_hint:
		return
	
	if not system_sync:
		_time_process(delta)
		_repeat_full_cycle()
		_check_cycle()
	else:
		_get_date_time_os()
	
	_celestials_update_timer += delta;
	if _celestials_update_timer > celestials_update_time:
		_set_celestials_coords()
		_celestials_update_timer = 0.0

# **** Date Time. ****

func set_time(hour: int, minute: int, second: int) -> void:
	_set_total_hours(TOD_DateTimeUtil.hours_to_total_hours(hour, minute, second))

func _time_process(delta: float) -> void:
	if time_cycle_duration() != 0.0:
		_set_total_hours(total_hours + delta / time_cycle_duration() * TOD_DateTimeUtil.TOTAL_HOURS)

func _get_date_time_os() -> void:
	date_time_os = OS.get_datetime()
	set_time(date_time_os.hour, date_time_os.minute, date_time_os.second)
	_set_day(date_time_os.day)
	_set_month(date_time_os.month)
	_set_year(date_time_os.year)

func _repeat_full_cycle() -> void:
	if is_end_of_time() && total_hours >= 23.9999:
		_set_year(1); _set_month(1); _set_day(1)
		_set_total_hours(0.0)
		
	if is_begin_of_time() && total_hours < 0.0:
		_set_year(9999); _set_month(12); _set_day(31)
		_set_total_hours(23.9999)

func _check_cycle() -> void:
	if total_hours > 23.9999:
		_set_day(day + 1)
		_set_total_hours(0.0)
	if total_hours < 0.0000:
		_set_day(day - 1)
		_set_total_hours(23.9999)
	
	if day > max_days_per_month():
		_set_month(month + 1)
		_set_day(1)
	
	if day < 1:
		_set_month(month - 1)
		_set_day(31)
	
	if month > 12:
		_set_year(year + 1)
		_set_month(1)
	
	if month < 1:
		_set_year(year - 1)
		_set_month(12)


# **** Planetary ****

func _compute_simple_sun_coords() -> void:
	var altitude = (_get_total_hours_utc() + (TOD_Math.DEG_TO_RAD * longitude)) * (360/24)
	_sun_coords.y = (180.0 - altitude)
	_sun_coords.x = latitude

func _compute_simple_moon_coords() -> void:
	_moon_coords.y = (180.0 - _sun_coords.y) + moon_coords_offset.y
	_moon_coords.x = (180.0 + _sun_coords.x) + moon_coords_offset.x

func _compute_realistic_sun_coords() -> void:
	## Orbital Elements.
	_sun_orbital_elements.compute_orbital_elements(0, _get_time_scale())
	_sun_orbital_elements.M = TOD_Math.rev(_sun_orbital_elements.M)
	
	# Mean anomaly in radians.
	var MRad: float = TOD_Math.DEG_TO_RAD * _sun_orbital_elements.M
	
	## Eccentric Anomaly
	var E: float = _sun_orbital_elements.M + TOD_Math.RAD_TO_DEG * _sun_orbital_elements.e *\
		sin(MRad) * (1 + _sun_orbital_elements.e * cos(MRad))
	
	var ERad: float = E * TOD_Math.DEG_TO_RAD
	
	## Rectangular coordinates.
	# Rectangular coordinates of the sun in the plane of the ecliptic.
	var xv: float = cos(ERad) - _sun_orbital_elements.e
	var yv: float = sin(ERad) * sqrt(1 - _sun_orbital_elements.e * _sun_orbital_elements.e)
	
	## Distance and true anomaly.
	# Convert to distance and true anomaly(r = radians, v = degrees).
	var r: float = sqrt(xv * xv + yv * yv)
	var v: float = TOD_Math.RAD_TO_DEG * atan2(yv, xv)
	_sun_distance = r
	
	## True longitude.
	var lonSun: float = v + _sun_orbital_elements.w
	lonSun = TOD_Math.rev(lonSun)
	
	var lonSunRad = TOD_Math.DEG_TO_RAD * lonSun
	_true_sun_longitude = lonSunRad
	
	## Ecliptic and ecuatorial coords.
	
	# Ecliptic rectangular coords.
	var xs: float = r * cos(lonSunRad)
	var ys: float = r * sin(lonSunRad)
	
	# Ecliptic rectangular coordinates rotate these to equatorial coordinates
	var obleclCos: float = cos(_get_oblecl())
	var obleclSin: float = sin(_get_oblecl())
	
	var xe: float = xs 
	var ye: float = ys * obleclCos - 0.0 * obleclSin
	var ze: float = ys * obleclSin + 0.0 * obleclCos
	
	## Ascencion and declination.
	var RA: float = TOD_Math.RAD_TO_DEG * atan2(ye, xe) / 15 # right ascension.
	var decl: float = atan2(ze, sqrt(xe * xe + ye * ye)) # declination
	
	# Mean longitude.
	var L: float = _sun_orbital_elements.w + _sun_orbital_elements.M
	L = TOD_Math.rev(L)
	
	_mean_sun_longitude = L
	
	## Sideral time and hour angle.
	var GMST0: float = ((L/15) + 12)
	_sideral_time = GMST0 + _get_total_hours_utc() + longitude / 15 # +15/15
	_local_sideral_time = TOD_Math.DEG_TO_RAD * _sideral_time * 15
	
	var HA: float = (_sideral_time - RA) * 15
	var HARAD: float = TOD_Math.DEG_TO_RAD * HA
	
	## Hour angle and declination in rectangular coords
	# HA and Decl in rectangular coords.
	var declCos: float = cos(decl)
	var x = cos(HARAD) * declCos # X Axis points to the celestial equator in the south.
	var y = sin(HARAD) * declCos # Y axis points to the horizon in the west.
	var z = sin(decl) # Z axis points to the north celestial pole.
	
	# Rotate the rectangualar coordinates system along of the Y axis.
	var sinLat: float = sin(latitude * TOD_Math.DEG_TO_RAD)
	var cosLat: float = cos(latitude * TOD_Math.DEG_TO_RAD)
	var xhor: float = x * sinLat - z * cosLat
	var yhor: float = y 
	var zhor: float = x * cosLat + z * sinLat
	
	## Azimuth and altitude.
	_sun_coords.x = atan2(yhor, xhor) + PI
	_sun_coords.y = (PI * 0.5) - asin(zhor) # atan2(zhor, sqrt(xhor * xhor + yhor * yhor))


func _compute_realistic_moon_coords() -> void:
	## Orbital Elements.
	_moon_orbital_elements.compute_orbital_elements(1, _get_time_scale())
	_moon_orbital_elements.N = TOD_Math.rev(_moon_orbital_elements.N)
	_moon_orbital_elements.w = TOD_Math.rev(_moon_orbital_elements.w)
	_moon_orbital_elements.M = TOD_Math.rev(_moon_orbital_elements.M)
	
	var NRad: float = TOD_Math.DEG_TO_RAD * _moon_orbital_elements.N
	var IRad: float = TOD_Math.DEG_TO_RAD * _moon_orbital_elements.i
	var MRad: float = TOD_Math.DEG_TO_RAD * _moon_orbital_elements.M
	
	## Eccentric anomaly.
	var E: float = _moon_orbital_elements.M + TOD_Math.RAD_TO_DEG * _moon_orbital_elements.e * sin(MRad) *\
		(1 + _sun_orbital_elements.e * cos(MRad))
	
	var ERad = TOD_Math.DEG_TO_RAD * E
	
	## Rectangular coords and true anomaly
	# Rectangular coordinates of the sun in the plane of the ecliptic
	var xv: float = _moon_orbital_elements.a * (cos(ERad) - _moon_orbital_elements.e)
	var yv: float = _moon_orbital_elements.a * (sin(ERad) * sqrt(1 - _moon_orbital_elements.e * \
		_moon_orbital_elements.e)) * sin(ERad)
		
	# Convert to distance and true anomaly(r = radians, v = degrees)
	var r: float = sqrt(xv * xv + yv * yv)
	var v: float = TOD_Math.RAD_TO_DEG * atan2(yv, xv)
	v = TOD_Math.rev(v)
	
	var l: float = TOD_Math.DEG_TO_RAD * v + _moon_orbital_elements.w
	
	var cosL: float = cos(l)
	var sinL: float = sin(l)
	var cosNRad: float = cos(NRad)
	var sinNRad: float = sin(NRad)
	var cosIRad: float = cos(IRad)
	
	var xeclip: float = r * (cosNRad * cosL - sinNRad * sinL * cosIRad)
	var yeclip: float = r * (sinNRad * cosL + cosNRad * sinL * cosIRad)
	var zeclip: float = r * (sinL * sin(IRad))
	
	## Geocentric coords.
	# Geocentric position for the moon and Heliocentric position for the planets
	var lonecl: float = TOD_Math.RAD_TO_DEG * atan2(yeclip, xeclip)
	lonecl = TOD_Math.rev(lonecl)
	
	var latecl: float = TOD_Math.RAD_TO_DEG * atan2(zeclip, sqrt(xeclip * xeclip + yeclip * yeclip))
	
	# Get true sun longitude.
	var lonsun: float = _true_sun_longitude
	
	# Ecliptic longitude and latitude in radians
	var loneclRad: float = TOD_Math.DEG_TO_RAD * lonecl
	var lateclRad: float = TOD_Math.DEG_TO_RAD * latecl
	
	var nr: float = 1.0
	var xh: float = nr * cos(loneclRad) * cos(lateclRad)
	var yh: float = nr * sin(loneclRad) * cos(lateclRad)
	var zh: float = nr * sin(lateclRad)
	
	# Geocentric coords.
	var xs: float = 0.0
	var ys: float = 0.0
	
	# Convert the geocentric position to heliocentric position.
	var xg: float = xh + xs
	var yg: float = yh + ys
	var zg: float = zh
	
	## Ecuatorial coords.
	# Cobert xg, yg un equatorial coords.
	var obleclCos: float = cos(_get_oblecl())
	var obleclSin: float = sin(_get_oblecl())
	
	var xe: float = xg 
	var ye: float = yg * obleclCos - zg * obleclSin
	var ze: float = yg * obleclSin + zg * obleclCos
	
	# Right ascention.
	var RA: float = TOD_Math.RAD_TO_DEG * atan2(ye, xe)
	RA = TOD_Math.rev(RA)
	
	# Declination.
	var decl: float = TOD_Math.RAD_TO_DEG * atan2(ze, sqrt(xe * xe + ye * ye))
	var declRad: float = TOD_Math.DEG_TO_RAD * decl
	
	## Sideral time and hour angle.
	# Hour angle.
	var HA: float = ((_sideral_time * 15) - RA)
	HA = TOD_Math.rev(HA)
	var HARAD: float = TOD_Math.DEG_TO_RAD * HA
	
	# HA y Decl in rectangular coordinates.
	var declCos: float = cos(declRad)
	var xr: float = cos(HARAD) * declCos
	var yr: float = sin(HARAD) * declCos
	var zr: float = sin(declRad)
	
	# Rotate the rectangualar coordinates system along of the Y axis(radians).
	var sinLat: float = sin(_get_latitude_rad())
	var cosLat: float = cos(_get_latitude_rad())
	
	var xhor: float = xr * sinLat - zr * cosLat
	var yhor: float = yr 
	var zhor: float = xr * cosLat + zr * sinLat
	
	## Azimuth and altitude
	_moon_coords.x = atan2(yhor, xhor) + PI
	_moon_coords.y = (PI *0.5) - atan2(zhor, sqrt(xhor * xhor + yhor * yhor)) # Mathf.Asin(zhor)

func _set_celestials_coords() -> void:
	if not _dome_ready: return
	match celestials_calculations:
		TOD_Enums.CelestialCalcMode.Simple:
			_compute_simple_sun_coords()
			_dome.sun_altitude = _sun_coords.y
			_dome.sun_azimuth = _sun_coords.x
			
			if compute_moon_coords:
				_compute_simple_moon_coords()
				_dome.moon_altitude = _moon_coords.y
				_dome.moon_azimuth = _moon_coords.x
			
			if compute_deep_space_coords:
				var x = Quat(Vector3( (90 + latitude) * TOD_Math.DEG_TO_RAD, 0.0, 0.0))
				var y = Quat(Vector3(0.0, 0.0, _sun_coords.y * TOD_Math.DEG_TO_RAD))
				_dome.deep_space_quat = x * y
		
		TOD_Enums.CelestialCalcMode.Realistic:
			_compute_realistic_sun_coords()
			_dome.sun_altitude = _sun_coords.y * TOD_Math.RAD_TO_DEG
			_dome.sun_azimuth = _sun_coords.x * TOD_Math.RAD_TO_DEG
			
			if compute_moon_coords:
				_compute_realistic_moon_coords()
				_dome.moon_altitude = _moon_coords.y * TOD_Math.RAD_TO_DEG
				_dome.moon_azimuth = _moon_coords.x * TOD_Math.RAD_TO_DEG
			
			if compute_deep_space_coords:
				var x = Quat(Vector3( (90 + latitude) * TOD_Math.DEG_TO_RAD, 0.0, 0.0) )
				var y = Quat(Vector3(0.0, 0.0,  (180.0 - _local_sideral_time * TOD_Math.RAD_TO_DEG) * TOD_Math.DEG_TO_RAD)) 
				_dome.deep_space_quat = x * y


func _get_property_list() -> Array:
	var ret: Array 
	ret.push_back({name = "Time Of Day Manager", type=TYPE_NIL, usage=PROPERTY_USAGE_CATEGORY})
	
	ret.push_back({name = "Target", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP})
	ret.push_back({name = "dome_path", type=TYPE_NODE_PATH})
	
	ret.push_back({name = "DateTime", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP})
	ret.push_back({name = "system_sync", type=TYPE_BOOL})
		
	ret.push_back({name = "total_cycle_in_minutes", type=TYPE_REAL})
	ret.push_back({name = "total_hours", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="0.0, 24.0"})
	ret.push_back({name = "day", type=TYPE_INT, hint=PROPERTY_HINT_RANGE, hint_string="0, 31"})
	ret.push_back({name = "month", type=TYPE_INT, hint=PROPERTY_HINT_RANGE, hint_string="0, 12"})
	ret.push_back({name = "year", type=TYPE_INT, hint=PROPERTY_HINT_RANGE, hint_string="-9999, 9999"})

	ret.push_back({name = "Planetary And Location", type=TYPE_NIL, usage=PROPERTY_USAGE_GROUP})
	ret.push_back({name = "celestials_calculations", type=TYPE_INT, hint=PROPERTY_HINT_ENUM, hint_string="Simple, Realistic"})
	ret.push_back({name = "compute_moon_coords", type=TYPE_BOOL})

	if celestials_calculations == 0 && compute_moon_coords:
		ret.push_back({name = "moon_coords_offset", type=TYPE_VECTOR2})
		
	ret.push_back({name = "compute_deep_space_coords", type=TYPE_BOOL})
	ret.push_back({name = "latitude", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="-90.0, 90.0"})
	ret.push_back({name = "longitude", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="-180.0, 180.0"})
	ret.push_back({name = "utc", type=TYPE_REAL, hint=PROPERTY_HINT_RANGE, hint_string="-12.0, 12.0"})
	ret.push_back({name = "celestials_update_time", type=TYPE_REAL})
	
	return ret
