package gea_2026

import "core:c"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

ButtonsSet :: bit_set[enum{accept, back}]

Position :: distinct rl.Vector2

InputEvent :: struct {
    wait_time, next_input_time, next_input_delay: c.double,
    axes, axes_buffer: rl.Vector2,
    buttons, buttons_buffer: ButtonsSet
}

PlayerStatus :: struct {
    health, wealth, steps, level: c.int
}

Menu :: struct {
    background: ^rl.Texture,
    cursor: c.int
}

IntMap :: struct {
    height, width: uint,
    data: [dynamic]u8
}

Tilemap :: struct {
    texture: ^rl.Texture,
    height, width: uint,
    tiles: [dynamic]u8
}

Animation :: struct {
    texture: ^rl.Texture,
    source: rl.Rectangle,
    frames, current_frame: uint,
    time, next_frame_time: c.float,
}

rectangles: ecs.Table(rl.Rectangle)
cameras: ecs.Table(rl.Camera2D)
inputEvents: ecs.Table(InputEvent) 
positions: ecs.Table(Position) 

menus: ecs.Table(Menu)
animations: ecs.Table(Animation)
intMaps: ecs.Table(IntMap)
tilemaps: ecs.Table(Tilemap)

playerStats: ecs.Table(PlayerStatus)

