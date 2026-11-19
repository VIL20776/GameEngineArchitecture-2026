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

setup_scores_menu :: proc() {
    main, _ := ecs.create_entity(&active_scene.db)
    
    menu, _ := ecs.add_component(&menus, main)
    menu.background = load_texture("images/results_bg.png")

    event, _ := ecs.add_component(&inputEvents, main)
    event.next_input_delay = 0.33
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
    tilemap_size :: tilemap_width * tilemap_height

    scene_map, _ := ecs.create_entity(&active_scene.db)

    // Generate noise map
    int_map, _ := ecs.add_component(&intMaps, scene_map)
    int_map.height = tilemap_height
    int_map.width = tilemap_width
    int_map.data = make([dynamic]u8, tilemap_size)

    // seed := time.time_to_unix(time.now())
    seed :: 3600
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

    // Set unique locations
    // 0 = exit
    // 1 = telescope
    // 2 = health machine
    for loc in 0..<3 {
        loc_index := rand.uint_range(0, 20)
        // loc_index := rand.uint_range(0, tilemap_size)
        for int_map.data[loc_index] != 0 {
            loc_index = (loc_index + 1) % tilemap_size
        }

        int_map.data[loc_index] = u8(10 + (loc * 2))
    }

    tilemap, _ := ecs.add_component(&tilemaps, scene_map)

    tilemap.texture = load_texture("images/tilemap.png")
    tilemap.height = tilemap_height
    tilemap.width = tilemap_width
    tilemap.tiles = make([dynamic]u8, tilemap_size)

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
        if event.wait_time < event.next_input_time - (event.next_input_delay / 2) do return

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
    
    menu.cursor = (menu.cursor + cast(c.int)input.axes.y) % 3 
    if .accept in input.buttons {
        switch menu.cursor {
        case 0:
            stats := &ecs.slice(&playerStats)[0]
            score, _ := ecs.create_entity(&global_db)
            ecs.add_component(&scores, score)
            stats.score_eid = score
            stats.flags += {.payment}
            stats.bonus = .cupon

            switch_scene(1)
        case 1:
            switch_scene(3)
        case 2:
            game_over = true
        }
    }
}

update_results_menu :: proc() {
    menu := ecs.slice(&menu_view, Menu)[0]
    input := ecs.slice(&menu_view, InputEvent)[0]

    menu.cursor = (menu.cursor + cast(c.int)input.axes.y) & 3 
    if .accept in input.buttons {
        stats := &ecs.slice(&playerStats)[0]
        // Next level bonuses 
        switch menu.cursor {
        case 0: 
            if stats.wealth_total < 5000 do return

            stats.wealth_total -= 5000
            stats.health += 5
            stats.bonus = .health
        case 1:
            if stats.wealth_total < 7500 do return

            stats.wealth_total -= 7500
            stats.bonus = .multiplier
        case 2:
            if stats.wealth_total < 10000 do return

            stats.wealth_total -= 10000
            stats.flags += { .payment }
            stats.bonus = .cupon
        case:
            stats.bonus = .none
        }

        score := ecs.get_component(&scores, stats.score_eid)
        append(&score.bonuses, stats.bonus)

        stats.wealth = 0
        stats.steps = 0
        stats.level += 1

        // if stats.health < 3 do stats.health = 3
        switch_scene(1)
    }

}
update_scores_menu :: proc() {
    input := ecs.slice(&menu_view, InputEvent)[0]

    if .accept in input.buttons do switch_scene(0)
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

    if stats.flags >= {.telescope, .payment } {
        cam := &ecs.slice(&cameras)[0] 
        cam.zoom = 1
    } else {
        cam := &ecs.slice(&cameras)[0]
        cam.zoom = 2
    }
 
    if stats.health == 0 {
        if .accept in event.buttons {
            score := ecs.get_component(&scores, stats.score_eid)
            score.max_level = stats.level
            score.max_wealth = stats.wealth_total

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
    } else {
        pos^ = temp_pos 
    }

    update_check_player()
}

update_check_player :: proc() {
    grid := &ecs.slice(&intMaps)[0]
    stats := &ecs.slice(&playerStats)[0] 
    pos := ecs.slice(&player_view, Position)[0]
    
    i := (uint(pos.y) * grid.width) + uint(pos.x)
    switch grid.data[i] {
    case 2: 
        stats.wealth += 5 if stats.bonus != .multiplier else 10
        grid.data[i] = 0
    case 4: 
        stats.wealth += 100 if stats.bonus != .multiplier else 200
        grid.data[i] = 0
    case 6: 
        stats.wealth += 1000 if stats.bonus != .multiplier else 2000
        grid.data[i] = 0
    case 8: 
        stats.health += 1
        grid.data[i] = 0
    case 10: 
        switch_scene(2)
        return
    case 12: 
        stats.flags += {.telescope}
        if .payment not_in stats.flags && stats.wealth >= 1500 {
            stats.flags += {.payment}
            stats.wealth -= 1500 
        }
    case 14: 
        stats.flags += {.dispenser}
        if .payment in stats.flags {
            stats.health += 5
        } else
        if stats.wealth >= 5000 {
            stats.flags += {.payment}
            stats.wealth -= 5000
            stats.health += 5
        }
    case: 
        break
    }

    if (.dispenser in stats.flags || .telescope in stats.flags) && 
        grid.data[i] <= 10 { 
            stats.flags -= {.dispenser, .telescope, .payment}
    }

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

    rl.DrawText("START", 272, 240, 32, rl.BLACK) 
    rl.DrawText("SCORE", 272, 272, 32, rl.BLACK) 
    rl.DrawText("EXIT", 272, 304, 32, rl.BLACK) 

    rl.DrawText(">", 256, 240 + (menu.cursor * 32), 32, rl.BLACK) 

    rl.DrawText("Press [SPACE] to select", 174, 408, 24, rl.BLACK) 
}

render_results_menu :: proc() {
    menu := ecs.slice(&menu_view, &menus)[0]
    stats := &ecs.slice(&playerStats)[0]

    rl.DrawTexture(menu.background^, 0, 0, rl.WHITE)
    
    rl.DrawText(fmt.caprintf("WEALTH COLLECTED: $%d", stats.wealth), 64, 48, 32, rl.BLACK)
    rl.DrawText(fmt.caprintf("WEALTH TOTAL: $%d", stats.wealth_total), 64, 80, 32, rl.BLACK)

    rl.DrawText("DUNGEON MASTER MAKES YOU AN OFFER: ", 64, 208, 24, rl.BLACK)

    rl.DrawText(">", 64, 240 + (menu.cursor * 24), 24, rl.BLACK) 

    rl.DrawText("1. 5 health for $5000", 80, 240, 24, rl.BLACK)
    rl.DrawText("2. 2x wealth multiplier for $7500", 80, 264, 24, rl.BLACK)
    rl.DrawText("3. Premium cupon for $10000", 80, 288, 24, rl.BLACK)
    rl.DrawText("4. Nothing", 80, 312, 24, rl.BLACK)

    rl.DrawText("Press [SPACE] to select", 150, 408, 24, rl.BLACK) 
}

render_scores_menu :: proc() {
    menu := ecs.slice(&menu_view, &menus)[0]
    stats := &ecs.slice(&playerStats)[0]

    card_texture := load_texture("images/tilemap.png")

    rl.DrawTexture(menu.background^, 0, 0, rl.WHITE)

    max_wealth, max_level: c.int
    
    scores_slice := ecs.slice(&scores)

    y: c.int = 208
    for i := len(scores_slice) - 1; i >= 0; i -= 1 {
        score := scores_slice[i]
        if score.max_wealth > max_wealth do max_wealth = score.max_wealth
        if score.max_level > max_level do max_level = score.max_level

        rl.DrawText(fmt.caprintf("Wealth total: $%d", score.max_wealth), 64, y, 24, rl.BLACK)

        for &bonus, j in score.bonuses {
            if j > 15 do break

            bonus_src: rl.Rectangle = {
                x = 16 * c.float(transmute(uint)bonus),
                y = 96, 
                height = 16, 
                width = 16
            }

            bonus_dest: rl.Rectangle = {
                x = 64 + f32(32 * j), 
                y = f32(y + 24),
                height = 32, 
                width = 32
            }

            rl.DrawTexturePro(card_texture^, bonus_src, bonus_dest, {0,0}, 0, rl.WHITE)
        }

        y += 64
        if (y + 64) > 376 do break
    }
    
    rl.DrawText(fmt.caprintf("BEST WEALTH TOTAL: $%d", max_wealth), 64, 48, 32, rl.BLACK)
    rl.DrawText(fmt.caprintf("HIGHEST LEVEL REACHED: %d", max_level), 64, 80, 32, rl.BLACK)

    rl.DrawText("Latest scores:", 64, 176, 24, rl.BLACK)

    rl.DrawText("Press [SPACE] to select", 150, 408, 24, rl.BLACK) 
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
                    rect.y = 80
                    rect.x = 0
                    case 12:
                    rect.y = 80
                    rect.x = 16
                    case 14:
                    rect.y = 80
                    rect.x = 32
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
    tm := ecs.slice(&map_view, Tilemap)[0]

    if stats.health == 0 {
        rl.DrawText("YOU", ui_pos_x + 16, 0, 32, rl.BLACK) 
        rl.DrawText("DIED!", ui_pos_x + 16, 32, 32, rl.BLACK) 

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

    bonus_src: rl.Rectangle = {
        x = 16 * c.float(transmute(uint)stats.bonus),
        y = 96, 
        height = 16, 
        width = 16
    }

    bonus_dest: rl.Rectangle = {
        x = ui_pos_x + 16, 
        y = 352,
        height = 32, 
        width = 32
    }

    rl.DrawText("BONUS", ui_pos_x + 16, 320, 32, rl.BLACK)
    rl.DrawTexturePro(tm.texture^, bonus_src, bonus_dest, {0,0}, 0, rl.WHITE)

    if .dispenser in stats.flags {
        if .payment in stats.flags {
            rl.DrawText("Thanks", ui_pos_x + 16, 400, 24, rl.BLACK) 
            rl.DrawText("for your", ui_pos_x + 16, 424, 24, rl.BLACK) 
            rl.DrawText("payment", ui_pos_x + 16, 448, 24, rl.BLACK)
        } else {
            rl.DrawText("Sorry", ui_pos_x + 16, 400, 24, rl.BLACK) 
            rl.DrawText("you need", ui_pos_x + 16, 424, 24, rl.BLACK) 
            rl.DrawText("$5000", ui_pos_x + 16, 448, 24, rl.BLACK) 
        }
    }

    if .telescope in stats.flags {
        if .payment in stats.flags {
            rl.DrawText("Thanks", ui_pos_x + 16, 400, 24, rl.BLACK) 
            rl.DrawText("for your", ui_pos_x + 16, 424, 24, rl.BLACK) 
            rl.DrawText("payment", ui_pos_x + 16, 448, 24, rl.BLACK) 
        } else {
            rl.DrawText("Sorry", ui_pos_x + 16, 400, 24, rl.BLACK) 
            rl.DrawText("you need", ui_pos_x + 16, 424, 24, rl.BLACK) 
            rl.DrawText("$1500", ui_pos_x + 16, 448, 24, rl.BLACK) 
        }
    }
}
