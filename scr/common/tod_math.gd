class_name TOD_Math
# Description:
# - Mathematics library.
# License:
# - J. Cuéllar 2022 MIT License
# - See: LICENSE File.

# **** Constants ****

# PI(π) 3.141592...
# @obsolete: Build in include.
const _PI:= 3.14159265358979

# π/2
const HALF_PI:= 1.5707963267949

# 1/(π/2)
const INV_HALF_PI:= 0.63661977236758

# π * 2
# @Obsolete: Build in include.
const _TAU:= 6.28318530717959

# 1/(π*2)
const INV_TAU:= 0.1591549430919

# π/4
const Q_PI:= 0.78539816339745

# 1/(π/4)
const INV_Q_PI:= 1.27323954473516

# π*4
const PIx4:= 12.56637061435917

# 1/(π*4)
const INV_PIx4:= 0.07957747154595

# 3/(π*8)
const PI3xE:= 0.11936620731892

# 3/(π*16)
const PI3x16:= 0.05968310365946

# e constant.
const e:= 2.71828182845905

# 180/π
const RAD_TO_DEG:= 57.29577951308232

# 1/(180/π)
const DEG_TO_RAD:= 0.01745329251994

# ***Functions.***

# Returns clamped value between zero and one.
# - value: value to clamp.
static func saturate(value: float) -> float:
	return 0.0 if value < 0.0 else 1.0 if value > 1.0 else value

static func saturate_vec3(value: Vector3) -> Vector3:
	var ret: Vector3
	ret.x = 0.0 if value.x < 0.0 else 1.0 if value.x > 1.0 else value.x
	ret.y = 0.0 if value.y < 0.0 else 1.0 if value.y > 1.0 else value.y
	ret.z = 0.0 if value.z < 0.0 else 1.0 if value.z > 1.0 else value.z
	return ret

static func saturate_color(value: Color) -> Color:
	var ret: Color
	ret.r = 0.0 if value.r < 0.0 else 1.0 if value.r > 1.0 else value.r
	ret.g = 0.0 if value.g < 0.0 else 1.0 if value.g > 1.0 else value.g
	ret.b = 0.0 if value.b < 0.0 else 1.0 if value.b > 1.0 else value.b
	ret.a = 0.0 if value.a < 0.0 else 1.0 if value.a > 1.0 else value.a
	return ret

static func saturate_rgb(value: Color) -> Color:
	var ret: Color
	ret.r = 0.0 if value.r < 0.0 else 1.0 if value.r > 1.0 else value.r
	ret.g = 0.0 if value.g < 0.0 else 1.0 if value.g > 1.0 else value.g
	ret.b = 0.0 if value.b < 0.0 else 1.0 if value.b > 1.0 else value.b
	ret.a = value.a
	return ret

# Rev function.
# -
static func rev(value: float) -> float:
	return value - int(floor(value / 360.0)) * 360.0

# Linear interpolation between two values(precise method).
# - from: initial value.
# - to: destination.
# - t: amount.
static func lerp_p(from: float, to: float, t: float) -> float:
	return (1.0 - t) * from + t * to

static func lerp_p_vec3(from: Vector3, to: Vector3, t: Vector3) -> Vector3:
	var ret: Vector3
	ret.x = (1.0 - t.x) * from.x + t.x * to.x
	ret.y = (1.0 - t.y) * from.y + t.y * to.y
	ret.z = (1.0 - t.z) * from.z + t.z * to.z
	return ret

static func lerp_p_color(from: Color, to: Color, t: float) -> Color:
	var ret: Color
	ret.r = (1.0 - t) * from.r + t * to.r
	ret.g = (1.0 - t) * from.g + t * to.g
	ret.b = (1.0 - t) * from.b + t * to.b
	ret.a = (1.0 - t) * from.a + t * to.a
	return ret

static func lerp_p_rgb(from: Color, to: Color, t: Color) -> Color:
	var ret: Color
	ret.r = (1.0 - t.r) * from.r + t.r * to.r
	ret.g = (1.0 - t.g) * from.g + t.g * to.g
	ret.b = (1.0 - t.b) * from.b + t.b * to.b
	ret.a = ret.a
	return ret

# Spherical to cartesian coordinates.
# -
static func to_orbit(theta: float, pi: float, radius: float = 1.0) -> Vector3:
	var ret: Vector3
	var sinTheta: float = sin(theta)
	var cosTheta: float = cos(theta)
	var sinPI: float = sin(pi)
	var cosPI: float = cos(pi)
	ret.x = sinTheta * sinPI
	ret.y = cosTheta;
	ret.z = sinTheta * cosPI
	
	return ret * radius

# Measures the distance between two vectors.
# -
static func distance(a: Vector3, b: Vector3) -> float:
	var x: float = a.x - b.x
	var y: float = a.y - b.y
	var z: float = a.z - b.z
	
	return sqrt(x * x + y * y + z * z)
