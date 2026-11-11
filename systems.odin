package gea_2026

import "core:c"
import "core:fmt"
import "core:time"
import "core:math/noise"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

// Setup systems
setup_player :: proc() {
    player, _ := ecs.create_entity(&db)
    anim, _ := ecs.add_component(&animations, player)

    anim.texture = load_texture("images/character.png")
}

setup_2dmap_generation :: proc() {
    noise_ceiling :: 0.1
    tilemap_height :: 37 
    tilemap_width :: 50

    scene_map, _ := ecs.create_entity(&db)

    // Generate noise map
    int_map, _ := ecs.add_component(&int_maps, scene_map)
    int_map.height = tilemap_height
    int_map.width = tilemap_width
    int_map.data = make([dynamic]u8, tilemap_height * tilemap_width)

    // seed := time.time_to_unix(time.now())
    seed :: 3600
    for y in 0..<tilemap_height {
        for x in 0..<tilemap_width {
            i := (y * tilemap_width) + x
            value := noise.noise_2d(seed, {f64(x), f64(y)})
            int_map.data[i] = 1 if value > 0.1 else 0
        }
    }

    tilemap, _ := ecs.add_component(&tilemaps, scene_map)

    tilemap.texture = load_texture("images/tilemap_4bit.png")
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
            
            if int_map.data[i] == 0 {
                continue
            }

            bitmask: u8 = 0
            for dp, di in dpos {
                nx := x + dp.x
                ny := y + dp.y

                if nx < 0 || nx >= tilemap_width || ny < 0 || ny >= tilemap_height do continue;

                n := (ny * tilemap_width) + nx
                bitmask += int_map.data[n] * (1 << u8(3 - di))
            }

            tilemap.tiles[i] = bitmask
        }
    }
}

// Input systems
input_axis :: proc() {
    for &axis in ecs.slice(&inputAxis) {
        axis.x = 0
        if rl.IsKeyDown(.LEFT) {
            axis.x = -1.0
        }
        if rl.IsKeyDown(.RIGHT) {
            axis.x = 1.0
        }
    }
}

// Update systems

// Render systems
render_rectangles :: proc() {
    for &rect in ecs.slice(&rectangle) {
        rl.DrawRectangleRec(rect, rl.WHITE)
    }
}

render_tilemap :: proc() {
    im_slice := ecs.slice(&map_view, &int_maps)
    tm_slice := ecs.slice(&map_view, &tilemaps)

    for i in 0..<len(im_slice) {
        tm := tm_slice[i]
        im := im_slice[i]

        for y in 0..<tm.height {
            for x in 0..<tm.width {
                index := (y * tm.width) + x
                if im.data[index] <= 0 do continue 

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
        }
    }
}
