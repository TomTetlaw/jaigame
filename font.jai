
Font :: struct {
    path: string;
    texture: *Texture;
    
    line_skip := 0.0;
    scale := 0.0;
    size := 0.0;
    
    info: Stbtt.Fontinfo;
    chars: []Stbtt.Packedchar;
}

load_font :: (path: string, size: float) -> *Font {
    for * fonts {
        if it.path == path && it.size == size return it;
    }
    
    file, success := read_entire_file(path);
    if !success {
        log("Font % failed to load", path);
        return null;
    }
    
    font_info: Stbtt.Fontinfo;
    Stbtt.init_font(*font_info, file.data, Stbtt.get_font_offset_for_index(file.data, 0));
    scale := Stbtt.scale_for_pixel_height(*font_info, size);
    
    width, height: s32 = 512;
    
    pixels: *u8 = alloc(width * height);
    char_data := NewArray(96, Stbtt.Packedchar);
    
    pack_context: Stbtt.PackContext;
    Stbtt.pack_begin(*pack_context, pixels, width, height, width, 1, null);
    Stbtt.pack_font_range(*pack_context, file.data, 0, size, 32, 96, char_data.data);
    
    texture := create_texture(tprint("%_%", path, size), width, height, pixels, .R);
    free(pixels);
    
    ascent, descent, line_gap: s32 = 0;
    Stbtt.get_font_v_metrics(*font_info, *ascent, *descent, *line_gap);
    line_skip := (ascent - descent + line_gap) * scale;
    
    font: Font;
    font.path = path;
    font.texture = texture;
    font.line_skip = line_skip;
    font.scale = scale;
    font.size = size;
    font.info = font_info;
    font.chars = char_data;
    
    _, font_pointer := bucket_array_add(*fonts, font);
    return font_pointer;
}

get_string_size :: (font: *Font, s: string) -> Vec2 {
    width := 0;
    data := s.data;
    while <<data {
        advance: s32 = 0;
        Stbtt.get_codepoint_h_metrics(*font.info, <<data, *advance, null);
        width += advance;
        data += 1;
    }
    
    ascent, descent, line_gap: s32 = 0;
    Stbtt.get_font_v_metrics(*font.info, *ascent, *descent, *line_gap);
    
    return .{width * font.scale, font.line_skip};
}

#scope_file

fonts: Bucket_Array(Font, 128);

#import "Bucket_Array";
#import "File";
Stbtt :: #import "StbTrueType";