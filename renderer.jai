
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
}

draw_texture :: (texture: *Texture, position: Vec2, colour: Vec4 = .{ 1, 1, 1, 1 }, custom_size := Vec2.{-1, -1}, depth := 0, tex_coords: [4] Vec2 = .[.{0,0}, .{0,1}, .{1,0}, .{1,1}]) {
    size := custom_size;
    if custom_size.x == -1 || custom_size.y == -1 {
        size = .{ xx texture.width, xx texture.height };
    }
    
    positions: [4] Vec3;
    tex_coords: [4] Vec2;
    indices := u32.[0, 1, 2, 1, 3, 2];
    
    tex_coords[0] = .{0, 0};
    tex_coords[1] = .{0, 1};
    tex_coords[2] = .{1, 0};
    tex_coords[3] = .{1, 1};
    
    positions[0] = .{position.x, position.y, 0};
    positions[1] = .{position.x, position.y + size.y, 0};
    positions[2] = .{position.x + size.x, position.y, 0};
    positions[3] = .{position.x + size.x, position.y + size.y, 0};
    
    first_index, first_vertex := write_buffers(indices, positions, tex_coords);
    
    basic: Draw_Command;
    basic.type = .Basic;
    basic.first_index = first_index;
    basic.first_vertex = first_vertex;
    basic.index_count = indices.count;
    basic.basic = .{colour, texture.object, tex_coords};
    basic.depth = depth;
    add_render_command(basic);
}

draw_quad :: (position: Vec2, size: Vec2, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    positions: [4] Vec3;
    tex_coords: [4] Vec2;
    indices := u32.[0, 1, 2, 1, 3, 2];
    
    tex_coords[0] = .{0, 0};
    tex_coords[1] = .{0, 1};
    tex_coords[2] = .{1, 0};
    tex_coords[3] = .{1, 1};
    
    positions[0] = .{position.x, position.y, 0};
    positions[1] = .{position.x, position.y + size.y, 0};
    positions[2] = .{position.x + size.x, position.y, 0};
    positions[3] = .{position.x + size.x, position.y + size.y, 0};
    
    first_index, first_vertex := write_buffers(indices, positions, tex_coords);
    
    coloured: Draw_Command;
    coloured.type = .Basic;
    coloured.first_index = first_index;
    coloured.first_vertex = first_vertex;
    coloured.index_count = indices.count;
    coloured.type = .Coloured;
    coloured.coloured = .{colour};
    add_render_command(coloured);
}

draw_text :: (font: *Font, origin: Vec2, text: string, colour := Vec4.{1,1,1,1}, depth := 0, with_camera := false) {
    position := origin;
    
    indices := u32.[0, 1, 2, 1, 3, 2];
    
    for 0..text.count-1 {
        c := text.data[it];
        if c < 32 || c >= 128 continue;
        
        quad: Stbtt.AlignedQuad;
        Stbtt.get_packed_quad(font.chars.data, xx font.texture.width, xx font.texture.height, c-32, *position.x, *position.y, *quad, 1);
        
        tex_coords := Vec2.[
            .{quad.s0, quad.t0},
            .{quad.s0, quad.t1},
            .{quad.s1, quad.t0},
            .{quad.s1, quad.t1}
        ];
        
        quad.y0 += font.size;
        quad.y1 += font.size;
        positions := Vec3.[.{quad.x0, quad.y0, 0}, .{quad.x0, quad.y1, 0}, .{quad.x1, quad.y0, 0}, .{quad.x1, quad.y1, 0}];
        
        first_index, first_vertex := write_buffers(indices, positions, tex_coords);
        
        font_command: Draw_Command;
        font_command.type = .Font;
        font_command.first_index = first_index;
        font_command.first_vertex = first_vertex;
        font_command.index_count = indices.count;
        font_command.font = .{colour, font.texture.object, tex_coords, with_camera};
        font_command.depth = depth;
        
        add_render_command(font_command);
    }
}

draw_wireframe_quad :: (position: Vec2, size: Vec2, thickness: float, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    // top
    {
        positions: [4] Vec3;
        tex_coords: [4] Vec2;
        indices := u32.[0, 1, 2, 1, 3, 2];
        
        tex_coords[0] = .{0, 0};
        tex_coords[1] = .{0, 1};
        tex_coords[2] = .{1, 0};
        tex_coords[3] = .{1, 1};
        
        positions[0] = .{position.x, position.y, 0};
        positions[1] = .{position.x, position.y + thickness, 0};
        positions[2] = .{position.x + size.x, position.y, 0};
        positions[3] = .{position.x + size.x, position.y + thickness, 0};
    
        first_index, first_vertex := write_buffers(indices, positions, tex_coords);
        
        coloured: Draw_Command;
        coloured.type = .Coloured;
        coloured.first_index = first_index;
        coloured.first_vertex = first_vertex;
        coloured.index_count = indices.count;
        coloured.coloured = .{colour};
        add_render_command(coloured);
    }
    
    // left
    {
        positions: [4] Vec3;
        tex_coords: [4] Vec2;
        indices := u32.[0, 1, 2, 1, 3, 2];
        
        tex_coords[0] = .{0, 0};
        tex_coords[1] = .{0, 1};
        tex_coords[2] = .{1, 0};
        tex_coords[3] = .{1, 1};
        
        positions[0] = .{position.x, position.y, 0};
        positions[1] = .{position.x, position.y + size.y, 0};
        positions[2] = .{position.x + thickness, position.y, 0};
        positions[3] = .{position.x + thickness, position.y + size.y, 0};
        
        first_index, first_vertex := write_buffers(indices, positions, tex_coords);
        
        coloured: Draw_Command;
        coloured.type = .Coloured;
        coloured.first_index = first_index;
        coloured.first_vertex = first_vertex;
        coloured.index_count = indices.count;
        coloured.coloured = .{colour};
        add_render_command(coloured);
    }
    
    // right
    {
        positions: [4] Vec3;
        tex_coords: [4] Vec2;
        indices := u32.[0, 1, 2, 1, 3, 2];
        
        tex_coords[0] = .{0, 0};
        tex_coords[1] = .{0, 1};
        tex_coords[2] = .{1, 0};
        tex_coords[3] = .{1, 1};
        
        positions[0] = .{position.x + size.x - thickness, position.y, 0};
        positions[1] = .{position.x + size.x - thickness, position.y + size.y, 0};
        positions[2] = .{position.x + size.x, position.y, 0};
        positions[3] = .{position.x + size.x, position.y + size.y, 0};
        
        first_index, first_vertex := write_buffers(indices, positions, tex_coords);
        
        coloured: Draw_Command;
        coloured.type = .Coloured;
        coloured.first_index = first_index;
        coloured.first_vertex = first_vertex;
        coloured.index_count = indices.count;
        coloured.coloured = .{colour};
        add_render_command(coloured);
    }
    
    // bottom
    {
        positions: [4] Vec3;
        tex_coords: [4] Vec2;
        indices := u32.[0, 1, 2, 1, 3, 2];
        
        tex_coords[0] = .{0, 0};
        tex_coords[1] = .{0, 1};
        tex_coords[2] = .{1, 0};
        tex_coords[3] = .{1, 1};
        
        positions[0] = .{position.x, position.y + size.y, 0};
        positions[1] = .{position.x, position.y + size.y - thickness, 0};
        positions[2] = .{position.x + size.x, position.y + size.y, 0};
        positions[3] = .{position.x + size.x, position.y + size.y - thickness, 0};
        
        first_index, first_vertex := write_buffers(indices, positions, tex_coords);
        
        coloured: Draw_Command;
        coloured.type = .Coloured;
        coloured.first_index = first_index;
        coloured.first_vertex = first_vertex;
        coloured.index_count = indices.count;
        coloured.coloured = .{colour};
        add_render_command(coloured);
    }
}

get_commands_of_type :: (commands: [] Draw_Command, type: Draw_Command_Type) -> [..] Draw_Command {
    out: [..] Draw_Command;
    out.allocator = temp;
    for commands if it.type == type array_add(*out, it);
    return out;
}

renderer_do_commands :: () {
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    commands := array_view(render_commands, 0);
    quick_sort(commands, (a, b) => a.depth - b.depth);
    
    basic_commands := get_commands_of_type(commands, .Basic);
    coloured_commands := get_commands_of_type(commands, .Coloured);
    font_commands := get_commands_of_type(commands, .Font);
    
    for basic_commands {
        prepare_basic_shader(*it.basic);
        glDrawElementsBaseVertex(GL_TRIANGLES, xx it.index_count, GL_UNSIGNED_INT, cast(*void) (it.first_index * size_of(u32)), xx it.first_vertex);
    }
    
    for coloured_commands {
        prepare_coloured_shader(*it.coloured);
        glDrawElementsBaseVertex(GL_TRIANGLES, xx it.index_count, GL_UNSIGNED_INT, cast(*void) (it.first_index * size_of(u32)), xx it.first_vertex);
    }
    
    for font_commands {
        prepare_font_shader(*it.font);
        
        glEnable(GL_BLEND);
        glDrawElementsBaseVertex(GL_TRIANGLES, xx it.index_count, GL_UNSIGNED_INT, cast(*void) (it.first_index * size_of(u32)), xx it.first_vertex);
        glDisable(GL_BLEND);
    }
    
    written_indices = 0;
    written_vertices = 0;
    render_commands.count = 0;
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
}

Basic_Command :: struct {
    colour: Vec4;
    texture: u32;
    tex_coords: [4] Vec2;
}

Font_Command :: struct {
    colour: Vec4;
    texture: u32;
    tex_coords: [4] Vec2;
    with_camera := false;
}

Coloured_Command :: struct {
    colour: Vec4;
}

Draw_Command :: struct {
    type: Draw_Command_Type;
    depth := 0;
    index_count := 0;
    first_index := 0;
    first_vertex := 0;
    
    union {
        basic: Basic_Command;
        coloured: Coloured_Command;
        font: Font_Command;
    }
}

#scope_file

written_indices := 0;
written_vertices := 0;

write_buffers :: (indices: [] u32, positions: [] Vec3, tex_coords: [] Vec2) -> int, int {
    assert(tex_coords.count == positions.count);
    
    if written_indices + indices.count >= MAX_INDICES fatal_error("Out of indices");
    if written_vertices + positions.count >= MAX_VERTICES fatal_error("Out of vertices");
    
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

render_commands: [..] Draw_Command;

add_render_command :: (command: Draw_Command) {
    array_add(*render_commands, command);
}

MAX_VERTICES :: 1000;
MAX_INDICES :: 3000;

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

#import "Basic";
#import "GL";
#import "Sort";
Stbtt :: #import "StbTrueType";