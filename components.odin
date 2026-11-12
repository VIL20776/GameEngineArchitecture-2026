package gea_2026

import "core:c"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

Position :: rl.Vector2
Axes :: rl.Vector2

Status :: struct {
    health, wealth: c.int
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
    source: rl.Rectangle,
    frames, current_frame: uint,
    time, next_frame_time: c.float,
}

rectangle: ecs.Table(rl.Rectangle)
cameras: ecs.Table(rl.Camera2D)
inputAxes: ecs.Table(Axes) 
positions: ecs.Table(Position) 

animations: ecs.Table(Animation)
intMaps: ecs.Table(IntMap)
tilemaps: ecs.Table(Tilemap)

stats: ecs.Table(Status)

component_init :: proc() {
    ecs.table_init(&rectangle, &active_scene.db, ENTITY_CAP)
    ecs.table_init(&cameras, &active_scene.db, ENTITY_CAP)
    ecs.table_init(&inputAxes, &active_scene.db, ENTITY_CAP)
    ecs.table_init(&positions, &active_scene.db, ENTITY_CAP)

    ecs.table_init(&stats, &active_scene.db, ENTITY_CAP)
    ecs.table_init(&animations, &active_scene.db, ENTITY_CAP)
    ecs.table_init(&intMaps, &active_scene.db, ENTITY_CAP)
    ecs.table_init(&tilemaps, &active_scene.db, ENTITY_CAP)

}
