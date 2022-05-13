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

static func get_color_channel(channel: int) -> Color:
	match(channel):
		TOD_Enums.ColorChannel.Red:
			return Color(1.0, 0.0, 0.0, 0.0)
		TOD_Enums.ColorChannel.Green:
			return Color(0.0, 1.0, 0.0, 0.0)
		TOD_Enums.ColorChannel.Blue:
			return Color(0.0, 0.0, 1.0, 0.0)
		TOD_Enums.ColorChannel.Alpha:
			return Color(0.0, 0.0, 0.0, 1.0)
	return Color.black
