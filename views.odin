package gea_2026

import ecs "ode_ecs/src"

paddle_view, ball_view, blocks_view: ecs.View

view_init :: proc() {
    ecs.view_init(&paddle_view, &db, 
        includes = {&rectangle, &inputAxis, &velocity}
        )
    ecs.view_init(&ball_view, &db, 
        includes = {&rectangle, &velocity},
        excludes = {&inputAxis}
        )
    ecs.view_init(&blocks_view, &db,
        includes = {&rectangle},
        excludes = {&inputAxis, &velocity}
        )
}
