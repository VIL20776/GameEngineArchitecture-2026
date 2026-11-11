package gea_2026

import rl "vendor:raylib"


WINDOW_HEIGHT :: 600
WINDOW_WIDTH :: 800

game_over := false

main :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Dungeon Explorer");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    game_init()
    defer game_deinit()

    game_setup()
    for !rl.WindowShouldClose() && !game_over {
        game_input()
        game_update()
        game_render()
    }
}
