package gea_2026

import ecs "ode_ecs/src"

map_view, player_view, anim_view: ecs.View

view_init :: proc() {
    ecs.view_init(&map_view, &active_scene.db, 
        includes = {&intMaps, &tilemaps}
        )
    ecs.view_init(&anim_view, &active_scene.db,
        includes = {&animations, &positions}
        )
    ecs.view_init(&player_view, &active_scene.db,
        includes = {&animations, &positions, &inputEvents}
        )
}
