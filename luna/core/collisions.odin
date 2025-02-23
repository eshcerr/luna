package luna_core

import "../base"
import "core:math"

collision_aabb_to_aabb :: proc(a: base.aabb, b: base.aabb) -> (bool, base.vec2) {
	using base

	dx: f32 = (a.z + a.x) / 2 - (b.z + b.x) / 2
	dy: f32 = (a.w + a.y) / 2 - (b.w + b.y) / 2

	overlap_x := (a.z - a.x) / 2 + (b.z - b.x) / 2 - abs(dx)
	overlap_y := (a.w - a.y) / 2 + (b.w - b.y) / 2 - abs(dy)

	if overlap_x <= 0 || overlap_y <= 0 {
		return false, vec2{}
	}

	penetration := vec2{}
	if overlap_x < overlap_y {
		penetration.x = overlap_x if dx > 0 else -overlap_x
	} else {
		penetration.y = overlap_y if dy > 0 else -overlap_y
	}

	return true, penetration
}
collision_aabb_to_circle :: proc(a: base.aabb, c: base.circle) -> (bool, base.vec2) {
	using base

	// Find the closest point on the AABB to the circle center
	closest := vec2{math.clamp(c.center.x, a.x, a.z), math.clamp(c.center.y, a.y, a.w)}

	// Vector from circle center to closest point
	delta := vec2{c.center.x - closest.x, c.center.y - closest.y}
	dist_sq := delta.x * delta.x + delta.y * delta.y
	radius_sq := c.radius * c.radius

	if dist_sq >= radius_sq {
		return false, vec2{}
	}

	dist := math.sqrt(dist_sq)
	penetration := vec2{}
	if dist > 0 {
		penetration.x = (delta.x / dist) * (c.radius - dist)
		penetration.y = (delta.y / dist) * (c.radius - dist)
	} else {
		// Handle case where circle is inside the AABB
		penetration = vec2{c.radius, 0}
	}

	return true, penetration
}

collision_circle_to_circle :: proc(c1: base.circle, c2: base.circle) -> (bool, base.vec2) {
	using base

	delta := vec2{c2.center.x - c1.center.x, c2.center.y - c1.center.y}
	dist_sq := delta.x * delta.x + delta.y * delta.y
	radius_sum := c1.radius + c2.radius
	radius_sq := radius_sum * radius_sum

	if dist_sq >= radius_sq {
		return false, vec2{}
	}

	dist := math.sqrt(dist_sq)
	penetration := vec2{}
	if dist > 0 {
		penetration.x = (delta.x / dist) * (radius_sum - dist)
		penetration.y = (delta.y / dist) * (radius_sum - dist)
	} else {
		// If circles are at the same position, push one out arbitrarily
		penetration = vec2{radius_sum, 0}
	}

	return true, penetration
}

collision_circle_to_polygon :: proc(c: base.circle, poly: []base.vec2) -> (bool, base.vec2) {
	using base

	closest := poly[0]
	min_dist_sq :=
		(c.center.x - closest.x) * (c.center.x - closest.x) +
		(c.center.y - closest.y) * (c.center.y - closest.y)

	// Find the closest point on the polygon to the circle center
	for v1, i in poly {
		v2 := poly[(i + 1) % len(poly)]

		// Project circle center onto edge v1-v2
		edge := vec2{v2.x - v1.x, v2.y - v1.y}
		edge_to_circle := vec2{c.center.x - v1.x, c.center.y - v1.y}
		edge_len_sq := edge.x * edge.x + edge.y * edge.y

		t := math.clamp(dot(edge_to_circle, edge) / edge_len_sq, 0.0, 1.0)
		closest_point := vec2{v1.x + t * edge.x, v1.y + t * edge.y}

		// Check distance
		dist_sq :=
			(c.center.x - closest_point.x) * (c.center.x - closest_point.x) +
			(c.center.y - closest_point.y) * (c.center.y - closest_point.y)

		if dist_sq < min_dist_sq {
			min_dist_sq = dist_sq
			closest = closest_point
		}
	}

	// Check if within circle radius
	if min_dist_sq >= c.radius * c.radius {
		return false, vec2{}
	}

	dist := math.sqrt_f32(min_dist_sq)
	penetration := vec2{}
	if dist > 0 {
		penetration.x = (c.center.x - closest.x) / dist * (c.radius - dist)
		penetration.y = (c.center.y - closest.y) / dist * (c.radius - dist)
	} else {
		// If the circle center is exactly on the polygon, push out arbitrarily
		penetration = vec2{c.radius, 0}
	}

	return true, penetration
}

collision_aabb_to_polygon :: proc(a: base.aabb, poly: []base.vec2) -> (bool, base.vec2) {
	using base

	// Convert AABB to a polygon
	aabb_poly := []vec2 {
		{a.x, a.y},
		{a.z, a.y},
		{a.z, a.w},
		{a.x, a.w},
	}

	// Use SAT to check for collision
	collided, penetration := collision_polygon_to_polygon(aabb_poly, poly)
	return collided, penetration
}

collision_polygon_to_polygon :: proc(poly1, poly2: []base.vec2) -> (bool, base.vec2) {
	using base

	min_penetration := math.inf_f32(1)
	penetration_axis := base.vec2{}

	check_separating_axis := proc(polyA, polyB: []base.vec2) -> (bool, vec2, f32) {
		min_overlap := math.inf_f32(1)
		best_axis := vec2{}

		for v1, i in polyA {
			v2 := polyA[(i + 1) % len(polyA)]
			edge := vec2{v2.x - v1.x, v2.y - v1.y}

			// Get perpendicular axis
			axis := vec2{-edge.y, edge.x}
			axis_len := math.sqrt(axis.x * axis.x + axis.y * axis.y)
			axis.x /= axis_len
			axis.y /= axis_len

			// Project both polygons onto the axis
			min1, max1 := project_polygon_on_axis(polyA, axis)
			min2, max2 := project_polygon_on_axis(polyB, axis)

			// Check for overlap
			if max1 < min2 || max2 < min1 {
				return false, vec2{}, 0
			}

			// Calculate penetration depth
			overlap := math.min(max1 - min2, max2 - min1)
			if overlap < min_overlap {
				min_overlap = overlap
				best_axis = axis
			}
		}

		return true, best_axis, min_overlap
	}

	// Check both sets of edges
	collided1, axis1, overlap1 := check_separating_axis(poly1, poly2)
	collided2, axis2, overlap2 := check_separating_axis(poly2, poly1)

	if !collided1 || !collided2 {
		return false, vec2{}
	}

	// Use the smallest penetration depth
	if overlap1 < overlap2 {
		min_penetration = overlap1
		penetration_axis = axis1
	} else {
		min_penetration = overlap2
		penetration_axis = axis2
	}

	// Ensure the penetration vector points in the right direction
	center1 := compute_polygon_center(poly1)
	center2 := compute_polygon_center(poly2)
	direction := base.vec2{center2.x - center1.x, center2.y - center1.y}
	if (penetration_axis.x * direction.x + penetration_axis.y * direction.y) < 0 {
		penetration_axis.x = -penetration_axis.x
		penetration_axis.y = -penetration_axis.y
	}

	return true, vec2{penetration_axis.x * min_penetration, penetration_axis.y * min_penetration}
}

project_polygon_on_axis :: proc(poly: []base.vec2, axis: base.vec2) -> (f32, f32) {
	using base

	min_proj := dot(poly[0], axis)
	max_proj := min_proj

	for i in poly[1:] {
		proj := dot(i, axis)
		min_proj = math.min(min_proj, proj)
		max_proj = math.max(max_proj, proj)
	}

	return min_proj, max_proj
}

dot :: proc(a, b: base.vec2) -> f32 {
	return a.x * b.x + a.y * b.y
}

compute_polygon_center :: proc(poly: []base.vec2) -> base.vec2 {
	using base

	center := vec2{}
	for p in poly {
		center.x += p.x
		center.y += p.y
	}
	center.x /= f32(len(poly))
	center.y /= f32(len(poly))
	return center
}

iaabb_contains :: proc(iaabb: base.iaabb, point: base.ivec2) -> bool {
    return point.x < iaabb.x || point.x > iaabb.x + iaabb.z || point.y < iaabb.y || point.y > iaabb.y + iaabb.w
}
