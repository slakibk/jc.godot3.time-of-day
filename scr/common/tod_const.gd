class_name TOD_Const
# Description:
# - Const for TOD.
# License:
# - J. Cuéllar 2022 MIT License
# - See: LICENSE File.

# Transform.
const DEFAULT_BASIS:= Basis(
	Vector3(1.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, 1.0)
)

const APROXIMATE_ZERO_POSITION:= Vector3(0.0000001, 0.0000001, 0.0000001)

# Rendering.
const MAX_EXTRA_CULL_MARGIN: float = 16384.0
