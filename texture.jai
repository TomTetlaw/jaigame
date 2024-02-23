
Texture :: struct {
    object: u32;
    path: string;
    width, height: int;
}

load_texture :: (path: string) -> *Texture {
    width, height, channels: s32;
    pixels := stbi_load(path.data, *width, *height, *channels, 4);
    if !pixels return null;
        
    texture := New(Texture);
    texture.path = path;
    texture.width = xx width;
    texture.height = xx height;
    
    glGenTextures(1, *texture.object);
    glBindTexture(GL_TEXTURE_2D, texture.object);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    return texture;
}

create_texture :: (name: string, width: int, height: int, pixels: *u8) -> *Texture {
    texture := New(Texture);
    texture.path = name;
    texture.width = width;
    texture.height = height;
    
    glGenTextures(1, *texture.object);
    glBindTexture(GL_TEXTURE_2D, texture.object);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    return texture;
}

#import "Basic";
#import "stb_image";