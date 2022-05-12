class_name TOD_Util
# Description:
# - Utility for TOD.
# License:
# - J. Cuéllar 2022 MIT License
# - See: LICENSE File.

static func interpolate_full(yDir: float) -> float:
	return (1.0 - yDir) * 0.5

static func interpolate_by_above(yDir: float) -> float:
	return 1.0 - yDir

static func interpolate_by_below(yDir: float) -> float:
	return 1.0 + yDir
