package Main

import "core:fmt"
import rl "vendor:raylib"

import "core:c"

WINDOW_HEIGHT :: 600
WINDOW_WIDTH :: 800

block_columns :: 10
block_rows :: 5

paddle, ball: rl.Rectangle
blocks: [block_columns * block_rows]rl.Rectangle

paddle_dir, paddle_speed: c.float

ball_dir: rl.Vector2
ball_speed: c.float 

block_offset := 0

game_over := false

setup :: proc() {
    paddle_height :: 20
    paddle_width :: WINDOW_WIDTH / 10
    paddle_x :: (WINDOW_WIDTH / 2) - (paddle_width / 2) 
    paddle_y :: WINDOW_HEIGHT - paddle_height

    paddle = rl.Rectangle{
        x = paddle_x,
        y = paddle_y,
        width = paddle_width,
        height = paddle_height
    }

    paddle_speed = (WINDOW_WIDTH - paddle_width) / 2

    ball_size :: 20
    ball_x :: WINDOW_WIDTH / 2
    ball_y :: WINDOW_HEIGHT / 2

    ball = rl.Rectangle{
        x = ball_x,
        y = ball_y,
        width = ball_size,
        height = ball_size
    }
    ball_dir.xy = 0.7071
    ball_speed = paddle_speed

    block_width :: WINDOW_WIDTH / block_columns
    block_height :: 20

    i: uint = 0
    block_y, block_x: c.float
    for block_y = 0; block_y < block_rows * block_height; block_y += block_height {
        for block_x = 0; block_x < block_columns * block_width; block_x += block_width {
            blocks[i] = rl.Rectangle{block_x, block_y, block_width, block_height}
            i += 1
        }
    }
}

handle_input :: proc() {
    paddle_dir = 0
    if rl.IsKeyDown(.LEFT) {
        paddle_dir = -1.0
    }
    if rl.IsKeyDown(.RIGHT) {
        paddle_dir = 1.0
    }
}

update :: proc() {
    paddle.x += paddle_dir * paddle_speed * rl.GetFrameTime()

    if paddle.x < 0 {
        paddle.x = 0
    }
    if paddle.x >= WINDOW_WIDTH - paddle.width {
        paddle.x = WINDOW_WIDTH - paddle.width
    }

    ball.x += ball_dir.x * ball_speed * rl.GetFrameTime()
    ball.y += ball_dir.y * ball_speed * rl.GetFrameTime()

    if ball.x < 0 || ball.x >= WINDOW_WIDTH - ball.width 
    {
        ball_dir.x = -ball_dir.x
    }

    if ball.y < 0 {
        ball_dir.y = -ball_dir.y
    }

    for i := block_offset; i < len(blocks); i += 1 {
        if rl.CheckCollisionRecs(ball, blocks[i]) {
            ball_dir.y = -ball_dir.y

            temp := blocks[block_offset]
            blocks[block_offset] = blocks[i]
            blocks[i] = temp

            block_offset += 1
            break
        }
    }

    if rl.CheckCollisionRecs(ball, paddle) {
        ball_dir.y = -ball_dir.y
        ball_speed += paddle_speed * 0.01
    }

    if ball.y >= WINDOW_HEIGHT {
        fmt.println("----GAME OVER----")
        game_over = true
    }

    if block_offset == len(blocks) {
        fmt.println("----YOU WIN!----")
        game_over = true
    }
}

render :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(rl.BLACK)

    rl.DrawRectangleRec(paddle, rl.WHITE)
    rl.DrawRectangleRec(ball, rl.WHITE)

    for i := block_offset; i < len(blocks); i += 1 {
        rl.DrawRectangleRec(blocks[i], rl.WHITE)
    }
}

main :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Breakout");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    setup()
    for !rl.WindowShouldClose() && !game_over {
        handle_input()
        update()
        render()
    }
}
