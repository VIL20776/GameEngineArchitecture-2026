package gea_2026

import "core:c"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

Velocity :: struct {
    dir: rl.Vector2,
    speed: c.float
}

Texture :: struct {
    texture: rl.Texture,
    path: string
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
    rect: rl.Rectangle,
    offset, frames: int,
    time, nextTiem: f64,
}

rectangle: ecs.Table(rl.Rectangle)
inputAxis: ecs.Table(rl.Vector2) 

animations: ecs.Table(Animation)
int_maps: ecs.Table(IntMap)
tilemaps: ecs.Table(Tilemap)

velocity: ecs.Table(Velocity)

component_init :: proc() {
    ecs.table_init(&rectangle, &db, ENTITY_CAP)
    ecs.table_init(&inputAxis, &db, ENTITY_CAP)
    ecs.table_init(&velocity, &db, ENTITY_CAP)

    ecs.table_init(&animations, &db, ENTITY_CAP)
    ecs.table_init(&int_maps, &db, ENTITY_CAP)
    ecs.table_init(&tilemaps, &db, ENTITY_CAP)
}
