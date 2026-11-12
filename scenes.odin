package gea_2026

import ecs "ode_ecs/src"

ENTITY_CAP :: 100

Scene :: struct {
    db: ecs.Database,
    setup: [dynamic]proc(),
    input: [dynamic]proc(),
    update: [dynamic]proc(),
    render: [dynamic]proc(),
}

scenes: [dynamic]Scene
active_scene: ^Scene

scenes_init :: proc() {
    scenes = make([dynamic]Scene, 2)

    //Main menu
    main_menu := &scenes[0]
    ecs.init(&main_menu.db, ENTITY_CAP)

    //Game
    game := &scenes[1]
    ecs.init(&game.db, ENTITY_CAP)
    append(&game.setup,
        setup_player,
        setup_2dmap_generation,
        setup_start_positions,
        setup_camera)
    append(&game.input,
        input_axis)
    // append(&game.update,)
    append(&game.render,
        render_begin_camera,
        render_tilemap,
        render_animations,
        render_end_camera)


    active_scene = &scenes[1]
}

scenes_deinit :: proc() {
    for &scene in scenes {
        ecs.clear(&scene.db)
    }
}
