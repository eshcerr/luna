package luna_utils

dynamic_array_find_element :: proc(arr: ^$T/[dynamic]$E, target: E) -> i32 {
	for v, i in arr {
		if v == target {
			return i32(i)
		}
	}
	return -1
}