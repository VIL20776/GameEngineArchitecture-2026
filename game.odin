package gea_2026

import "core:c"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

dt: c.float

game_init :: proc() {
    scenes_init()
    component_init()
    view_init()
}

game_deinit :: proc() {
    unload_textures()
    scenes_deinit()
}

game_setup :: proc() {
    for sys in active_scene.setup do sys()
}

game_input :: proc() {
    for sys in active_scene.input do sys()
}

game_update :: proc() {
    dt = rl.GetFrameTime()
    for sys in active_scene.update do sys()
}

game_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.GRAY)

    for sys in active_scene.render do sys()
}
