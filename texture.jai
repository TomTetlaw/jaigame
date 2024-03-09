
Texture :: struct {
    object: u32;
    path: string;
    width, height: int;
}

load_texture :: (path: string) -> *Texture {
    for * textures {
        if equal(it.path, path) return it;
    }
    
    width, height, channels: s32;
    pixels := stbi_load(path.data, *width, *height, *channels, 4);
    if !pixels return null;
    
    object: u32;
    glGenTextures(1, *object);
    glBindTexture(GL_TEXTURE_2D, object);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    texture: Texture;
    texture.object = object;
    texture.path = path;
    texture.width = xx width;
    texture.height = xx height;
    
    _, texture_pointer := bucket_array_add(*textures, texture);
    return texture_pointer;
}

create_texture :: (name: string, width: int, height: int, pixels: *u8) -> *Texture {
    object: u32;
    glGenTextures(1, *object);
    glBindTexture(GL_TEXTURE_2D, object);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    texture: Texture;
    texture.object = object;
    texture.path = name;
    texture.width = width;
    texture.height = height;
    
    _, texture_pointer := bucket_array_add(*created_textures, texture);
    return texture_pointer;
}

#scope_file

textures: Bucket_Array(Texture, 128);
created_textures: Bucket_Array(Texture, 128);

#import "Basic";
#import "stb_image";