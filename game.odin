package gea_2026

import "core:c"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

ENTITY_CAP :: 100

db: ecs.Database
dt: c.float

game_init :: proc() {
    ecs.init(&db, ENTITY_CAP)

    component_init()
    view_init()
}

game_deinit :: proc() {
    unload_textures()
    ecs.clear(&db)
}

game_setup :: proc() {
    setup_2dmap_generation()
}

game_input :: proc() {
}

game_update :: proc() {
    dt = rl.GetFrameTime()
}

game_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)

    render_tilemap()
}
