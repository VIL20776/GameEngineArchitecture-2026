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
    ecs.clear(&db)
}

game_setup :: proc() {
    setup_paddle()
    setup_ball()
    setup_block_grid()
}

game_input :: proc() {
    input_axis()
}

game_update :: proc() {
    dt = rl.GetFrameTime()
    update_paddle()
    update_ball()
    update_check_collisions()
    update_check_state()
}

game_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)
    render_rectangles()
}
