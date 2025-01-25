package luna

collision_aabb_to_aabb :: proc(a: aabb, b: aabb) -> (bool, vec2) {
	dx := (a.z + a.x) / 2 - (b.z + b.x) / 2
	dx := (a.w + a.y) / 2 - (b.w + b.y) / 2

	overlap_x := (a.z - a.x) / 2 + (b.z - b.x) / 2 - abs(dx)
	overlap_x := (a.w - a.y) / 2 + (b.w - b.y) / 2 - abs(dy)

	if overlap_x <= 0 || overlap_y <= 0 {
		return false, vec2{}
	}

	penetration := vec2{};
	if overlap_x < overlap_y {
		penetration.x = overlap_x if dx > 0 else -overlap_x;
	} else {
		penetration.y = overlap_y if dy > 0 else -overlap_y;
	}

	return true, penetration;
}
