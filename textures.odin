package gea_2026

import rl "vendor:raylib"

texture_registry: [dynamic]rl.Texture

load_texture :: proc(filepath: cstring) -> ^rl.Texture {
    append(&texture_registry, rl.LoadTexture(filepath))
    i := len(texture_registry) - 1
    return &texture_registry[i]
}

unload_textures :: proc() {
    delete(texture_registry)
}
