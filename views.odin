package gea_2026

import ecs "ode_ecs/src"

map_view: ecs.View

view_init :: proc() {
    ecs.view_init(&map_view, &db, 
        includes = {&int_maps, &tilemaps}
        )
}
