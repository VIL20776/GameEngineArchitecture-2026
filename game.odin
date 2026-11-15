package gea_2026

import "core:c"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

global_db: ecs.Database
dt: c.float

game_init :: proc() {
    ecs.init(&global_db, ENTITY_CAP)
        
    ecs.table_init(&playerStats, &global_db, 1)

    scenes_init()
}

game_deinit :: proc() {
    unload_textures()
    scenes_deinit()
}

game_setup :: proc() {
    for i in 0..<len(active_scene.setup) do active_scene.setup[i]()
}

game_input :: proc() {
    for i in 0..<len(active_scene.input) do active_scene.input[i]()
}

game_update :: proc() {
    dt = rl.GetFrameTime()
    for i in 0..<len(active_scene.update) do active_scene.update[i]()
}

game_render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.GRAY)

    for i in 0..<len(active_scene.render) do active_scene.render[i]()
}
