package luna_gfx

import "../base"

material_t :: struct {
	color: base.vec4,
}

material_default := material_t {
	color = base.COLOR_WHITE,
}
