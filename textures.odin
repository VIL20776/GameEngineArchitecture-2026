package gea_2026

import rl "vendor:raylib"

texture_registry: map[cstring]rl.Texture

load_texture :: proc(filepath: cstring) -> ^rl.Texture {
    if filepath not_in texture_registry {
        texture_registry[filepath] = rl.LoadTexture(filepath)
    }

    return &texture_registry[filepath]
}

unload_textures :: proc() {
    delete(texture_registry)
}
