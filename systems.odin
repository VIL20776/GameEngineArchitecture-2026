package gea_2026

import "core:c"
import "core:fmt"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

// Setup systems
setup_paddle :: proc() {
    paddle, _ := ecs.create_entity(&db)

    rect, _ := ecs.add_component(&rectangle, paddle)
    rect.height = 20
    rect.width = WINDOW_WIDTH / 10
    rect.x = (WINDOW_WIDTH / 2) - (rect.width / 2) 
    rect.y = WINDOW_HEIGHT - rect.height

    velo, _ := ecs.add_component(&velocity, paddle)
    velo.speed = (WINDOW_WIDTH - rect.width) / 2

    ecs.add_component(&inputAxis, paddle) 
}

setup_ball :: proc() {
    ball, _ := ecs.create_entity(&db)

    rect, _ := ecs.add_component(&rectangle, ball)
    rect.height = 20
    rect.width = 20
    rect.x = WINDOW_WIDTH / 2
    rect.y = WINDOW_HEIGHT / 2

    velo, _ := ecs.add_component(&velocity, ball)
    velo.dir.xy = 0.7071 // sqrt of 1/2
    velo.speed = (WINDOW_WIDTH - rect.width) / 2
}

setup_block_grid :: proc() {
    block_columns :: 10
    block_rows :: 5
    block_width :: WINDOW_WIDTH / block_columns
    block_height :: 20

    block_y, block_x: c.float
    for block_y = 0; block_y < block_rows * block_height; block_y += block_height {
        for block_x = 0; block_x < block_columns * block_width; block_x += block_width {
            block, _ := ecs.create_entity(&db)
            rect, _ := ecs.add_component(&rectangle, block)
            rect^ = {block_x, block_y, block_width, block_height}
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
update_paddle :: proc() {
    rect_slice := ecs.slice(&paddle_view, rl.Rectangle)
    axis_slice := ecs.slice(&paddle_view, rl.Vector2)
    velo_slice := ecs.slice(&paddle_view, Velocity)

    for i in 0..<len(rect_slice) {
        rect := rect_slice[i]
        axis := axis_slice[i]
        velo := velo_slice[i]

        rect.x += axis.x * velo.speed * dt

        if rect.x < 0 {
            rect.x = 0
        }
        if rect.x >= WINDOW_WIDTH - rect.width {
            rect.x = WINDOW_WIDTH - rect.width
        }
    }
}

update_ball :: proc() {
    rect_slice := ecs.slice(&ball_view, rl.Rectangle)
    velo_slice := ecs.slice(&ball_view, Velocity)

    for i in 0..<len(rect_slice) {
        rect := rect_slice[i]
        velo := velo_slice[i]

        rect.x += velo.dir.x * velo.speed * dt
        rect.y += velo.dir.y * velo.speed * dt

        if rect.x < 0 || rect.x >= WINDOW_WIDTH - rect.width 
        {
            velo.dir.x = -velo.dir.x
        }

        if rect.y < 0 {
            velo.dir.y = -velo.dir.y
        }
    }
}

update_check_collisions :: proc() {
    ball_rect_slice := ecs.slice(&ball_view, rl.Rectangle)
    ball_velo_slice := ecs.slice(&ball_view, Velocity)
    for i in 0..<len(ball_rect_slice) {
        ball_rect := ball_rect_slice[i]
        ball_velo := ball_velo_slice[i]

        blocks_rect_slice := ecs.slice(&blocks_view, rl.Rectangle)
        blocks_eid_slice := ecs.slice(&blocks_view)
        for j in 0..<len(blocks_rect_slice) {
            block_rect := blocks_rect_slice[j]
            block_eid := blocks_eid_slice[j]

            if rl.CheckCollisionRecs(ball_rect^, block_rect^) {
                ecs.pause_packing(&db)
                defer ecs.resume_packing(&db)

                ball_velo.dir.y = -ball_velo.dir.y
                ecs.destroy_entity(&db, block_eid)
                break
            }
        }

        paddle_rect_slice := ecs.slice(&paddle_view, rl.Rectangle)
        paddle_velo_slice := ecs.slice(&paddle_view, Velocity)
        for j in 0..<len(paddle_rect_slice) {
            paddle_rect := paddle_rect_slice[j]
            paddle_velo := paddle_velo_slice[j]

            if rl.CheckCollisionRecs(ball_rect^, paddle_rect^) {
                ball_velo.dir.y = -ball_velo.dir.y
                ball_velo.speed += paddle_velo.speed * 0.01
            }
        }
    }
}

update_check_state :: proc() {
    ball_rect_slice := ecs.slice(&ball_view, rl.Rectangle)

    for i in 0..<len(ball_rect_slice) {
        ball_rect := ball_rect_slice[i]

        if ball_rect.y >= WINDOW_HEIGHT {
            fmt.println("----GAME OVER----")
            game_over = true
        }
    }

    if ecs.view_len(&blocks_view) == 0 {
        fmt.println("----YOU WIN!----")
        game_over = true
    }
}

// Render systems
render_rectangles :: proc() {
    for &rect in ecs.slice(&rectangle) {
        rl.DrawRectangleRec(rect, rl.WHITE)
    }
}
