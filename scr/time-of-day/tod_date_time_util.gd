class_name TOD_DateTimeUtil
# Description:
# - Date time utility functions.
# License:
# - J. Cuéllar 2022 MIT License
# - See: LICENSE File.

# Total hours in earth
const TOTAL_HOURS: int = 24

# Compute leap year
# - year
static func compute_leap_year(year: int) -> bool:
	return (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0)

# Convert hour to float.
# - hour
static func hour_to_total_hours(hour: int) -> float:
	return float(hour)

# Convert hours to float.
# - hour
# - minutes
static func hour_minutes_to_total_hours(hour: int, minutes: int) -> float:
	return float(hour) + float(minutes) / 60.0

# Convert hours to float.
# - hour
# - minutes
# - seconds
static func hours_to_total_hours(hour:int, minutes: int, seconds: int) -> float:
	return float(hour) + float(minutes) / 60.0 + float(seconds) / 3600.0

# Convert hours to float.
# - hour
# - minutes
# - seconds
# - milliseconds
static func full_time_to_total_hours(hour: int, minutes: int, seconds: int, milliseconds: int) -> float: 
	return float(hour) + float(minutes) / 60.0 + float(seconds) / 3600.0 +\
		float(milliseconds) / 3600000.0	
