package gea_2026

import ecs "ode_ecs/src"

ENTITY_CAP :: 100

Scene :: struct {
    db: ecs.Database,
    init: proc(),
    setup: [dynamic]proc(),
    input: [dynamic]proc(),
    update: [dynamic]proc(),
    render: [dynamic]proc(),
    deinit: proc()
}

scenes: []Scene
active_scene: ^Scene

scenes_init :: proc() {
    scenes = make([]Scene, 3)

    //Main menu
    main_menu := &scenes[0]
    // ecs.init(&main_menu.db, ENTITY_CAP)
    main_menu.init = proc() {
        ecs.table_init(&menus, &active_scene.db, ENTITY_CAP)
        ecs.table_init(&inputEvents, &active_scene.db, 1)

        ecs.view_init(&menu_view, &active_scene.db, 
            includes = {&menus, &inputEvents}
        ) 
    }

    main_menu.deinit = proc() {
        ecs.table_terminate(&menus)
        ecs.table_terminate(&inputEvents)

        ecs.view_terminate(&menu_view) 
    }

    append(&main_menu.setup,
        setup_main_menu)
    append(&main_menu.input,
        input_axis_event)
    append(&main_menu.update,
        update_main_menu)
    append(&main_menu.render,
        render_main_menu)

    // Level
    level := &scenes[1]
    // ecs.init(&game.db, ENTITY_CAP)
    level.init = proc() {
        ecs.table_init(&rectangles, &active_scene.db, ENTITY_CAP)
        ecs.table_init(&cameras, &active_scene.db, ENTITY_CAP)
        ecs.table_init(&positions, &active_scene.db, ENTITY_CAP)
        ecs.table_init(&tilemaps, &active_scene.db, ENTITY_CAP)
        ecs.table_init(&animations, &active_scene.db, ENTITY_CAP)
        ecs.table_init(&inputEvents, &active_scene.db, 1)
        ecs.table_init(&intMaps, &active_scene.db, 1) 

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

    level.deinit = proc() {
        ecs.table_terminate(&rectangles)
        ecs.table_terminate(&cameras)
        ecs.table_terminate(&positions)
        ecs.table_terminate(&tilemaps)
        ecs.table_terminate(&animations)
        ecs.table_terminate(&inputEvents)
        ecs.table_terminate(&intMaps)  

        ecs.view_terminate(&map_view)
        ecs.view_terminate(&anim_view)
        ecs.view_terminate(&player_view)
    }

    append(&level.setup,
        setup_game_manager,
        setup_player,
        setup_2dmap_generation,
        setup_start_positions,
        setup_camera)
    append(&level.input,
        input_axis_event)
    append(&level.update,
        update_player_movement,
        update_check_player,
        update_camera)
    append(&level.render,
        render_begin_camera,
        render_tilemap,
        render_animations,
        render_end_camera,
        render_player_state)

    // Results
    results := &scenes[2]
    results.init = proc() {
        ecs.table_init(&menus, &active_scene.db, ENTITY_CAP)
        ecs.table_init(&inputEvents, &active_scene.db, 1)

        ecs.view_init(&menu_view, &active_scene.db, 
            includes = {&menus, &inputEvents}
        ) 
    }
    results.deinit = proc() {
        ecs.table_terminate(&menus)
        ecs.table_terminate(&inputEvents)

        ecs.view_terminate(&menu_view) 
    }
    append(&results.setup,
        setup_game_manager,
        setup_results_menu)
    append(&results.input,
        input_axis_event)
    append(&results.update,
        update_results_menu)
    append(&results.render,
        render_results_menu) 

    active_scene = &scenes[0]

    ecs.init(&active_scene.db, ENTITY_CAP)
    active_scene.init()
}

scenes_deinit :: proc() {
    active_scene.deinit()
    ecs.terminate(&active_scene.db)

    for &scene in scenes {
        delete(scene.setup)
        delete(scene.input)
        delete(scene.update)
        delete(scene.render)
    }
}

switch_scene :: proc(scene: uint) {
    active_scene.deinit()
    ecs.terminate(&active_scene.db)

    active_scene = &scenes[scene]

    ecs.init(&active_scene.db, ENTITY_CAP)
    active_scene.init()

    for i in 0..<len(active_scene.setup) do active_scene.setup[i]()
}
