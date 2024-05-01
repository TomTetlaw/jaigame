
camera_position: Vec2;
camera_focus_point: Vec2;
render_size: Vec2;
render_half_size: Vec2;

set_camera_position :: (position: Vec2) {
    camera_position = position;
}

renderer_init :: (screen_size: Vec2) {
    render_size = screen_size;
    render_half_size = screen_size * 0.5;
    camera_focus_point = render_half_size;
    
    glGenVertexArrays(1, *vertex_array);
    glBindVertexArray(vertex_array);
    
    position_buffer = create_buffer(GL_ARRAY_BUFFER, size_of(Vec3) * MAX_VERTICES, "position_buffer");
    tex_coord_buffer = create_buffer(GL_ARRAY_BUFFER, size_of(Vec2) * MAX_VERTICES, "tex_coord_buffer");
    index_buffer = create_buffer(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * MAX_INDICES, "index_buffer");
    
    basic_shader = make_shader_program(basic_shader_text);
    coloured_shader = make_shader_program(coloured_shader_text);
    font_shader = make_shader_program(font_shader_text);
    
    glBindBuffer(GL_ARRAY_BUFFER, position_buffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vec3), xx 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, tex_coord_buffer);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(Vec2), xx 0);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    set_camera_position(v2(0,0));
    
    debug_font = load_font("fonts/consolas.ttf", 16.0);
}

draw_texture :: (texture: *Texture, position: Vec2, colour: Vec4 = .{ 1, 1, 1, 1 }, custom_size := Vec2.{-1, -1}, tex_coords: [4] Vec2 = .[.{0,0}, .{0,1}, .{1,0}, .{1,1}]) {
    size := custom_size;
    if custom_size.x == -1 || custom_size.y == -1 {
        size = .{ xx texture.width, xx texture.height };
    }
    
    positions: [4] Vec3;
    indices := u32.[0, 1, 2, 1, 3, 2];
    
    positions[0] = .{position.x, position.y, 0};
    positions[1] = .{position.x, position.y + size.y, 0};
    positions[2] = .{position.x + size.x, position.y, 0};
    positions[3] = .{position.x + size.x, position.y + size.y, 0};
    
    first_index, first_vertex := write_render_buffers(indices, positions, tex_coords);
    
    basic: Draw_Command;
    basic.type = .Basic;
    basic.first_index = first_index;
    basic.first_vertex = first_vertex;
    basic.index_count = indices.count;
    basic.colour = colour;
    basic.texture = texture.object;
    basic.alpha_blended = true;
    add_render_command(basic);
}

draw_quad :: (position: Vec2, size: Vec2, colour: Vec4 = .{1, 1, 1, 1}, tex_coords: [4] Vec2 = .[.{0,0}, .{0,1}, .{1,0}, .{1,1}]) {
    positions: [4] Vec3;
    tex_coords: [4] Vec2;
    indices := u32.[0, 1, 2, 1, 3, 2];
    
    positions[0] = .{position.x, position.y, 0};
    positions[1] = .{position.x, position.y + size.y, 0};
    positions[2] = .{position.x + size.x, position.y, 0};
    positions[3] = .{position.x + size.x, position.y + size.y, 0};
    
    first_index, first_vertex := write_render_buffers(indices, positions, tex_coords);
    
    coloured: Draw_Command;
    coloured.type = .Basic;
    coloured.first_index = first_index;
    coloured.first_vertex = first_vertex;
    coloured.index_count = indices.count;
    coloured.type = .Coloured;
    coloured.colour = colour;
    add_render_command(coloured);
}

draw_text :: (font: *Font, origin: Vec2, text: string, colour := Vec4.{1,1,1,1}, with_camera := false, $PROCESS_NEWLINES := false) -> float {
    position := origin;
    
    positions: [..] Vec3;
    positions.allocator = temp;
    
    tex_coords: [..] Vec2;
    tex_coords.allocator = temp;
    
    indices: [..] u32;
    indices.allocator = temp;
    
    quad_indices :: u32.[0, 1, 2, 1, 3, 2];
    
    quad_index := 0;
    
    for 0..text.count-1 {
        c := text[it];
        
#if PROCESS_NEWLINES {
            if c == #char "\n" {
                position.x = origin.x;
                position.y += font.line_skip;
                continue;
            }
        }
        
        if c < 32 || c >= 128 continue;
        
        quad: Stbtt.AlignedQuad;
        Stbtt.get_packed_quad(font.chars.data, xx font.texture.width, xx font.texture.height, c-32, *position.x, *position.y, *quad, 1);
        
        quad.y0 += font.size;
        quad.y1 += font.size;
        
        w := quad.x1 - quad.x0;
        h := quad.y1 - quad.y0;
        
        array_add(*positions, .{quad.x0, quad.y0, 0}); 
        array_add(*positions, .{quad.x0, quad.y1, 0});
        array_add(*positions, .{quad.x1, quad.y0, 0});
        array_add(*positions, .{quad.x1, quad.y1, 0});
        
        array_add(*tex_coords, .{quad.s0, quad.t0});
        array_add(*tex_coords, .{quad.s0, quad.t1});
        array_add(*tex_coords, .{quad.s1, quad.t0});
        array_add(*tex_coords, .{quad.s1, quad.t1});
        
        array_add(*indices, cast(u32) (quad_index * 4) + quad_indices[0]);
        array_add(*indices, cast(u32) (quad_index * 4) + quad_indices[1]);
        array_add(*indices, cast(u32) (quad_index * 4) + quad_indices[2]);
        array_add(*indices, cast(u32) (quad_index * 4) + quad_indices[3]);
        array_add(*indices, cast(u32) (quad_index * 4) + quad_indices[4]);
        array_add(*indices, cast(u32) (quad_index * 4) + quad_indices[5]);
        quad_index += 1;
    }
    
    first_index, first_vertex := write_render_buffers(indices, positions, tex_coords);
    
    font_command: Draw_Command;
    font_command.type = .Font;
    font_command.first_index = first_index;
    font_command.first_vertex = first_vertex;
    font_command.index_count = indices.count;
    font_command.colour = colour;
    font_command.texture = font.texture.object;
    font_command.with_camera = with_camera;
    font_command.alpha_blended = true;
    
    add_render_command(font_command);
    
    return position.y - font.line_skip;
}

// code taken from Print_Vars.jai and modified
debug_show_vars :: ($args: .. Code) #expand {
    config: Print_Vars_Config;
    config.after_value = "";
    config.control_flags = .PRINT_NAME | .PRINT_VALUE;
    
    builder: String_Builder;
    debug_string_helper(*builder, config, args);
    message := builder_to_string(*builder);
    
    final_y := draw_text(debug_font, debug_string_position, message, PROCESS_NEWLINES = true);
    debug_string_position = .{debug_string_position.x, final_y + debug_font.line_skip*2};
}

debug_string :: (format: string, args: ..Any) {
    builder: String_Builder;
    print_to_builder(*builder, format, ..args);
    message := builder_to_string(*builder);
    
    draw_text(debug_font, debug_string_position, message);
    debug_string_position += .{0, debug_font.line_skip*2};
}

draw_wireframe_quad :: (position: Vec2, size: Vec2, thickness: float, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    indices: [24] u32;
    for 0..3 {
        for i: 0..5 
            indices[it*6+i] = u32.[0, 1, 2, 1, 3, 2][i] + cast(u32) (it * 4);
    }
    
    tex_coords: [16] Vec2;
    for 0..3 {
        for i: 0..3 {
            tex_coords[it*4+i] = Vec2.[.{0, 0}, .{0, 1}, .{1, 0}, .{1, 1}][i];
        }
    }
    
    positions: [16] Vec3;
    
    // top
    positions[0] = .{position.x, position.y, 0};
    positions[1] = .{position.x, position.y + thickness, 0};
    positions[2] = .{position.x + size.x, position.y, 0};
    positions[3] = .{position.x + size.x, position.y + thickness, 0};
    
    // left
    positions[4] = .{position.x, position.y, 0};
    positions[5] = .{position.x, position.y + size.y, 0};
    positions[6] = .{position.x + thickness, position.y, 0};
    positions[7] = .{position.x + thickness, position.y + size.y, 0};
    
    // bottom
    positions[8] = .{position.x + size.x - thickness, position.y, 0};
    positions[9] = .{position.x + size.x - thickness, position.y + size.y, 0};
    positions[10] = .{position.x + size.x, position.y, 0};
    positions[11] = .{position.x + size.x, position.y + size.y, 0};
    
    // right
    positions[12] = .{position.x, position.y + size.y, 0};
    positions[13] = .{position.x, position.y + size.y - thickness, 0};
    positions[14] = .{position.x + size.x, position.y + size.y, 0};
    positions[15] = .{position.x + size.x, position.y + size.y - thickness, 0};
    
    first_index, first_vertex := write_render_buffers(indices, positions, tex_coords);
    
    coloured: Draw_Command;
    coloured.type = .Coloured;
    coloured.first_index = first_index;
    coloured.first_vertex = first_vertex;
    coloured.index_count = indices.count;
    coloured.colour = colour;
    add_render_command(coloured);
}

renderer_do_commands :: () {
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    for render_commands {
        if it.type == {
            case .Basic;
            prepare_basic_shader(*it);
            case .Coloured;
            prepare_coloured_shader(*it);
            case .Font;
            prepare_font_shader(*it);
        }
        
        if it.alpha_blended glEnable(GL_BLEND);
        glDrawElementsBaseVertex(GL_TRIANGLES, xx it.index_count, GL_UNSIGNED_INT, cast(*void) (it.first_index * size_of(u32)), xx it.first_vertex);
        if it.alpha_blended glDisable(GL_BLEND);
    }
    
    written_indices = 0;
    written_vertices = 0;
    render_commands.count = 0;
    
    debug_string_position = DEBUG_STRING_ORIGIN;
}

bind_textures :: (textures: [] u32) {
    assert(textures.count <= 8);
    
    for 0..textures.count-1 {
        glActiveTexture(GL_TEXTURE0 + cast(u32) it);
        glBindTexture(GL_TEXTURE_2D, textures[it]);
    }
}

Draw_Command_Type :: enum {
    Basic;
    Coloured;
    Font;
    Tilemap;
}

Draw_Command :: struct {
    type: Draw_Command_Type;
    index_count := 0;
    first_index := 0;
    first_vertex := 0;
    texture: u32;
    colour := Vec4.{1, 1, 1, 1};
    with_camera := false;
    alpha_blended := false;
}

add_render_command :: (command: Draw_Command) {
    array_add(*render_commands, command);
}

write_render_buffers :: (indices: [] u32, positions: [] Vec3, tex_coords: [] Vec2) -> int, int {
    assert(tex_coords.count == positions.count);
    
    if written_indices + indices.count >= MAX_INDICES fatal_error("Out of indices, wanted %, used %, max is %", indices.count, written_indices, MAX_INDICES);
    if written_vertices + positions.count >= MAX_VERTICES fatal_error("Out of vertices: wanted %, used %, max is %", positions.count, written_vertices, MAX_VERTICES);
    
    first_index := written_indices;
    first_vertex := written_vertices;
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_buffer);
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, written_indices * size_of(u32), indices.count * size_of(u32), indices.data);
    glBindBuffer(GL_ARRAY_BUFFER, position_buffer);
    glBufferSubData(GL_ARRAY_BUFFER, written_vertices * size_of(Vec3), positions.count * size_of(Vec3), positions.data);
    glBindBuffer(GL_ARRAY_BUFFER, tex_coord_buffer);
    glBufferSubData(GL_ARRAY_BUFFER, written_vertices * size_of(Vec2), tex_coords.count * size_of(Vec2), tex_coords.data);
    
    written_indices += indices.count;
    written_vertices += positions.count;
    
    return first_index, first_vertex;
}

#scope_file

written_indices := 0;
written_vertices := 0;

render_commands: [..] Draw_Command;

MAX_VERTICES :: 50000;
MAX_INDICES :: 50000;

position_buffer: u32;
tex_coord_buffer: u32;
index_buffer: u32;
vertex_array: u32;

create_buffer :: (target: u32, size: int, name: string) -> u32 {
    object: u32;
    glGenBuffers(1, *object);
    glBindBuffer(target, object);
    glBufferData(target, xx size, null, GL_STATIC_DRAW);
    glObjectLabel(GL_BUFFER, object, xx name.count, name.data);
    return object;
}

DEBUG_STRING_LEFT :: 16.0;
DEBUG_STRING_TOP :: 16.0;
DEBUG_STRING_ORIGIN :: Vec2.{DEBUG_STRING_LEFT, DEBUG_STRING_TOP};
debug_string_position := DEBUG_STRING_ORIGIN;
debug_font: *Font;

// code taken from Print_Vars.jai 
debug_string_helper :: (builder: *String_Builder, config: Print_Vars_Config, $args: [$N] Code) #expand {
    names:         [N] string;
    value_strings: [N] string;
    
    // We go in two passes; in the first, we compute the names, because we want to know how
    // wide those are for formatting purposes. In the second pass, we do the values.
    
    // Pass 1, names.
#insert -> string {
        my: String_Builder;
        
        for 0..args.count-1 {
            print_to_builder(*my, "    names[%1] = #run get_code_name(args[%1]);\n", it);
            print_to_builder(*my, "    value%1 := #insert args[%1];\n", it);
            print_to_builder(*my, "    value_strings[%1] = tprint(\"\%\", value%1);\n", it);
        }
        
        return builder_to_string(*my);
    }
    
    name_width  := 0;
    value_width := 0;
    
    for names          name_width  = Max(name_width,  it.count);
    for value_strings  value_width = Max(value_width, it.count);
    
    // Pass 2, values.
#insert -> string {
        my: String_Builder;
        
        for 0..args.count-1 {
            print_to_builder(*my, "    print_helper(builder, config, name_width, value_width, names[%1], value_strings[%1], type_of(value%1));\n", it);
        }
        
        return builder_to_string(*my);
    };
}

#import "Basic";
#import "GL";
#import "Sort";
Stbtt :: #import "StbTrueType";