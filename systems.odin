package gea_2026

import "core:math/rand"
import "core:c"
import "core:fmt"
import "core:time"
import "core:math/noise"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

// Setup systems
setup_game_manager :: proc() {
    if ecs.any_table_len(&playerStats) != 0 do return

    manager, _ := ecs.create_entity(&global_db)

    stats, _ := ecs.add_component(&playerStats, manager)
    stats.health = 5
    stats.level = 1
}

setup_main_menu :: proc() {
    main, _ := ecs.create_entity(&active_scene.db)
    
    menu, _ := ecs.add_component(&menus, main)
    menu.background = load_texture("images/title_bg.png")

    event, _ := ecs.add_component(&inputEvents, main)
    event.next_input_delay = 0.33
}

setup_results_menu :: proc() {
    main, _ := ecs.create_entity(&active_scene.db)
    
    menu, _ := ecs.add_component(&menus, main)
    menu.background = load_texture("images/results_bg.png")

    event, _ := ecs.add_component(&inputEvents, main)
    event.next_input_delay = 0.33

    stats := &ecs.slice(&playerStats)[0]
    stats.wealth_total += stats.wealth
}

setup_player :: proc() {
    player, _ := ecs.create_entity(&active_scene.db)

    anim, _ := ecs.add_component(&animations, player)
    anim.texture = load_texture("images/character.png")
    anim.source = {0, 0, 16, 16}
    anim.frames = 4
    anim.next_frame_time = 0.67

    event, _ := ecs.add_component(&inputEvents, player)
    event.next_input_delay = 0.67

    ecs.add_component(&positions, player)
}

setup_2dmap_generation :: proc() {
    tilemap_height :: 37 
    tilemap_width :: 50

    scene_map, _ := ecs.create_entity(&active_scene.db)

    // Generate noise map
    int_map, _ := ecs.add_component(&intMaps, scene_map)
    int_map.height = tilemap_height
    int_map.width = tilemap_width
    int_map.data = make([dynamic]u8, tilemap_height * tilemap_width)

    seed := time.time_to_unix(time.now())
    // seed :: 3600
    for y in 0..<tilemap_height {
        for x in 0..<tilemap_width {
            i := (y * tilemap_width) + x
            value := noise.noise_2d(seed, {f64(x), f64(y)})

            int_map.data[i] = 0
            if value > 0.1 {
                int_map.data[i] = 1
            }

            if value < -0.75 {
                int_map.data[i] = 2
            }

            if value > 0.75 {
                int_map.data[i] = 3
            }

            if value < -0.8 {
                int_map.data[i] = 4
            }

            if value > 0.8 {
                int_map.data[i] = 5
            }

            if value < -0.9 {
                int_map.data[i] = 6
            }

            if value > 0.9 {
                int_map.data[i] = 7
            }

            if value < -0.95 {
                int_map.data[i] = 8
            }

            if value > 0.95 {
                int_map.data[i] = 9
            }

            // int_map.data[i] = 1 if value > 0.1 else 0
            // fmt.printf("%d", int_map.data[i])
        }
        // fmt.print("\n")
    }

    // Set exit location
    exit_index := rand.uint_range(0, tilemap_width * tilemap_height)
    for int_map.data[exit_index] != 0 {
        exit_index += 1
    }
    int_map.data[exit_index] = 10
    // int_map.data[5] = 10

    tilemap, _ := ecs.add_component(&tilemaps, scene_map)

    tilemap.texture = load_texture("images/tilemap.png")
    tilemap.height = tilemap_height
    tilemap.width = tilemap_width
    tilemap.tiles = make([dynamic]u8, tilemap_height * tilemap_width)

    // Calculate tile values
    dpos: [4][2]int = {
        {-1, 0}, {0, 1}, {0, -1}, {1, 0},
    }

    for y in 0..<tilemap_height {
        for x in 0..<tilemap_width {
            i := (y * tilemap_width) + x
            
            if (int_map.data[i] & 1) == 0 {
                continue
            }

            bitmask: u8 = 0
            for dp, di in dpos {
                nx := x + dp.x
                ny := y + dp.y

                if nx < 0 || nx >= tilemap_width || ny < 0 || ny >= tilemap_height do continue;

                n := (ny * tilemap_width) + nx
                bitmask += (int_map.data[n] & 1) * (1 << u8(3 - di))
            }

            tilemap.tiles[i] = bitmask
        }
    }
}

setup_camera :: proc() {
    scene_camera, _ := ecs.create_entity(&active_scene.db)

    cam, _ := ecs.add_component(&cameras, scene_camera)
    cam.offset = {(WINDOW_HEIGHT / 2) - 16, (WINDOW_HEIGHT / 2) - 16}
    cam.rotation = 0
    cam.zoom = 2

    pos := ecs.slice(&player_view, Position)[0]
    
    cam.target = pos.xy
}

setup_start_positions :: proc() {
    im_slice := ecs.slice(&map_view, IntMap)

    for i in 0..<len(im_slice) {
        im := im_slice[i]

        player_pos := ecs.slice(&player_view, Position)[0]
        for im_index: uint = 0; im_index < im.height * im.width; im_index += 1 {
            x := cast(c.float)(im_index % im.width)
            y := cast(c.float)(im_index / im.height)

            if im.data[im_index] > 0 do continue

            player_pos^ = {x, y}
            return
        }
    }
}

// Input systems
input_axis_event :: proc() {
    for &event in ecs.slice(&inputEvents) {
        event.axes.xy = 0

        event.wait_time = rl.GetTime()
        // if event.wait_time < event.next_input_time + 0.33 do return

        if rl.IsKeyDown(.LEFT) {
            event.axes_buffer = {-1.0, 0}
        }
        if rl.IsKeyDown(.RIGHT) {
            event.axes_buffer = {1.0, 0}
        }
        if rl.IsKeyDown(.UP) {
            event.axes_buffer = {0, -1.0}
        }
        if rl.IsKeyDown(.DOWN) {
            event.axes_buffer = {0, 1.0}
        } 

        if rl.IsKeyDown(.SPACE) {
            event.buttons_buffer += {.accept}
        }

        if event.wait_time < event.next_input_time do return

        event.axes = event.axes_buffer
        event.axes_buffer.xy = 0

        event.buttons = event.buttons_buffer
        event.buttons_buffer = {}

        event.next_input_time = event.wait_time + event.next_input_delay
    }
}

update_main_menu :: proc() {
    menu := ecs.slice(&menu_view, Menu)[0]
    input := ecs.slice(&menu_view, InputEvent)[0]
    
    menu.cursor = (menu.cursor + cast(c.int)input.axes.y) & 1 
    if .accept in input.buttons {
        if menu.cursor == 0 do switch_scene(1); else
        if menu.cursor == 1 do game_over = true
    }
}

update_results_menu :: proc() {
    menu := ecs.slice(&menu_view, Menu)[0]
    input := ecs.slice(&menu_view, InputEvent)[0]
    
    menu.cursor = (menu.cursor + cast(c.int)input.axes.y) & 1 
    if .accept in input.buttons {
        stats := &ecs.slice(&playerStats)[0]
        stats.wealth = 0
        stats.steps = 0
        stats.level += 1
        // if menu.cursor == 0 do 
        // if menu.cursor == 1 do game_over = true
        switch_scene(1)
    }

}

update_camera :: proc() {
    camera := &ecs.slice(&cameras)[0]
    player_pos := ecs.slice(&player_view, Position)[0]
    grid := &ecs.slice(&intMaps)[0]

    // offset := rl.Vector2{10 * 16, 7.5 * 16}

    camera.target = (player_pos.xy * 16)
}

// Update systems
update_player_movement :: proc() {
    event := ecs.slice(&player_view, InputEvent)[0] 
    stats := &ecs.slice(&playerStats)[0]
 
    if stats.health == 0 {
        if .accept in event.buttons {
            stats^ = {}
            stats.level = 1
            stats.health = 5
            switch_scene(0)
        }
        return
    }

    if event.axes.x == 0 && event.axes.y == 0 do return

    pos := ecs.slice(&player_view, Position)[0]
    temp_pos := pos^

    grid := &ecs.slice(&intMaps)[0]
    
    temp_pos += event.axes.xy
    if temp_pos.x < 0 || uint(temp_pos.x) >= grid.width || temp_pos.y < 0 || uint(temp_pos.y) > grid.height {
        return
    }

    stats.steps += 1

    if stats.steps % 10 == 0 {
        stats.health -= 1
    }

    i := (uint(temp_pos.y) * grid.width) + uint(temp_pos.x)
    if bool(grid.data[i] & 1) {
        grid.data[i] -= 1
        return
    } else {
        switch grid.data[i] {
            case 2: stats.wealth += 5
            case 4: stats.wealth += 100
            case 6: stats.wealth += 1000
            case 8: stats.health += 1
            case 10: 
                switch_scene(2)
                return
            case: break
        }
        grid.data[i] = 0
    }

    pos^ = temp_pos
}

update_check_player :: proc() {
    stats := &ecs.slice(&playerStats)[0] 
    if stats.health == 0 {
        anim := ecs.slice(&player_view, Animation)[0] 
        anim.source.y = 16
    }
}

// Render systems
render_rectangles :: proc() {
    for &rect in ecs.slice(&rectangles) {
        rl.DrawRectangleRec(rect, rl.WHITE)
    }
}

render_main_menu :: proc() {
    menu := ecs.slice(&menu_view, &menus)[0]

    rl.DrawTexture(menu.background^, 0, 0, rl.WHITE)

    rl.DrawText("DUNGEON", 240, 80, 32, rl.BLACK) 
    rl.DrawText("EXPLORER", 240, 112, 32, rl.BLACK) 

    rl.DrawText("START", 272, 272, 32, rl.BLACK) 
    rl.DrawText("EXIT", 272, 304, 32, rl.BLACK) 

    rl.DrawText(">", 256, 272 + (menu.cursor * 32), 32, rl.BLACK) 

    rl.DrawText("Press [SPACE] to select", 174, 408, 24, rl.BLACK) 
}

render_results_menu :: proc() {
    menu := ecs.slice(&menu_view, &menus)[0]
    stats := &ecs.slice(&playerStats)[0]

    rl.DrawTexture(menu.background^, 0, 0, rl.WHITE)
    
    rl.DrawText(fmt.caprintf("WEALTH COLLECTED: $%d", stats.wealth), 64, 48, 32, rl.BLACK)
    rl.DrawText(fmt.caprintf("WEALTH TOTAL: $%d", stats.wealth_total), 64, 80, 32, rl.BLACK)

    rl.DrawText(fmt.caprintf("PREPARE FOR LEVEL %d", stats.level + 1), 64, 208, 32, rl.BLACK)

    rl.DrawText("Press [SPACE] to continue", 150, 376, 24, rl.BLACK) 
}

render_begin_camera :: proc() {
    camera := &ecs.slice(&cameras)[0]
    rl.BeginMode2D(camera^)
}

render_end_camera :: proc() {
    rl.EndMode2D()
}

render_animations :: proc() {
    anim_slice := ecs.slice(&anim_view, Animation)
    pos_slice := ecs.slice(&anim_view, Position)

    for i in 0..<len(anim_slice) {
        anim := anim_slice[i]
        if anim.time += dt; anim.time >= anim.next_frame_time {
            anim.time = 0
            anim.current_frame = (anim.current_frame + 1) % anim.frames
            anim.source.x = cast(f32)anim.current_frame * 16 
        }

        pos := pos_slice[i]
        rl.DrawTextureRec(anim.texture^, anim.source, pos.xy * 16, rl.WHITE)
    }
}

render_tilemap :: proc() {
    im_slice := ecs.slice(&map_view, IntMap)
    tm_slice := ecs.slice(&map_view, Tilemap)

    for i in 0..<len(im_slice) {
        tm := tm_slice[i]
        im := im_slice[i]

        for y in 0..<tm.height {
            for x in 0..<tm.width {
                index := (y * tm.width) + x

                if !bool(im.data[index] & 1) {
                    rl.DrawRectangle(
                        cast(c.int)x * 16, 
                        cast(c.int)y * 16, 
                        16, 16, 
                        rl.Color{199, 144, 90, 255})
                } else {
                    tile := tm.tiles[index]
                    tile_pos := tilemap_0[tile]

                    rect: rl.Rectangle = {
                        x = tile_pos.x, 
                        y = tile_pos.y, 
                        height = 16, 
                        width = 16}

                    pos_x := f32(x) * 16
                    pos_y := f32(y) * 16

                    rl.DrawTextureRec(tm.texture^, rect, {pos_x, pos_y}, rl.WHITE)
                }

                pos_value := im.data[index]
                if pos_value == 0 || pos_value == 1 do continue

                rect: rl.Rectangle = {
                    y = 64, 
                    height = 16, 
                    width = 16
                }

                pos_x := f32(x) * 16
                pos_y := f32(y) * 16

                switch (pos_value) {
                    case 2,3:
                    rect.x = 0
                    case 4,5:
                    rect.x = 16
                    case 6,7:
                    rect.x = 32
                    case 8,9:
                    rect.x = 48
                    case 10:
                    rect.y += 16
                }

                rl.DrawTextureRec(tm.texture^, rect, {pos_x, pos_y}, rl.WHITE)
            }
        }
    }
}

render_player_state :: proc() {
    ui_pos_x :: WINDOW_WIDTH - 160

    rl.DrawRectangle(
        posX = ui_pos_x,
        posY = 0,
        width = 160,
        height = WINDOW_HEIGHT,
        color = rl.Color{199, 144, 90, 255}
        )

    stats := &ecs.slice(&playerStats)[0]

    if stats.health == 0 {
        rl.DrawText("YOU", ui_pos_x + 16, 0, 32, rl.BLACK) 
        rl.DrawText("DIED", ui_pos_x + 16, 32, 32, rl.BLACK) 

        rl.DrawText("Press", ui_pos_x + 16, 96, 24, rl.BLACK)
        rl.DrawText("[SPACE] to", ui_pos_x + 16, 120, 24, rl.BLACK)
        rl.DrawText("return to", ui_pos_x + 16, 144, 24, rl.BLACK)
        rl.DrawText("main menu", ui_pos_x + 16, 168, 24, rl.BLACK)
        return
    }

    rl.DrawText("HEALTH", ui_pos_x + 16, 0, 32, rl.BLACK) 
    rl.DrawText(fmt.caprintf(" %d", stats.health), ui_pos_x + 16, 32, 32, rl.BLACK)

    rl.DrawText("WEALTH", ui_pos_x + 16, 80, 32, rl.BLACK)
    rl.DrawText(fmt.caprintf("$%d", stats.wealth), ui_pos_x + 16, 112, 32, rl.BLACK)

    rl.DrawText("STEPS", ui_pos_x + 16, 160, 32, rl.BLACK)
    rl.DrawText(fmt.caprintf(" %d", stats.steps), ui_pos_x + 16, 192, 32, rl.BLACK)

    rl.DrawText("LEVEL", ui_pos_x + 16, 240, 32, rl.BLACK)
    rl.DrawText(fmt.caprintf(" %d", stats.level), ui_pos_x + 16, 272, 32, rl.BLACK)
}
