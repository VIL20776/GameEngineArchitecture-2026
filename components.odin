package gea_2026

import "core:c"

import rl "vendor:raylib"
import ecs "ode_ecs/src"

Velocity :: struct {
    dir: rl.Vector2,
    speed: c.float
}

rectangle: ecs.Table(rl.Rectangle)
inputAxis: ecs.Table(rl.Vector2) 

velocity: ecs.Table(Velocity)

component_init :: proc() {
    ecs.table_init(&rectangle, &db, ENTITY_CAP)
    ecs.table_init(&inputAxis, &db, ENTITY_CAP)
    ecs.table_init(&velocity, &db, ENTITY_CAP)
}
