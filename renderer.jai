
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
    
    verts: [4] Vertex;
    verts[0].position = v3(-0.5, 0.5, 0);
    verts[0].tex_coord = v2(0, 0);
    
    verts[1].position = v3(-0.5, -0.5, 0);
    verts[1].tex_coord = v2(0, 1);
    
    verts[2].position = v3(0.5, 0.5, 0);
    verts[2].tex_coord = v2(1, 0);
    
    verts[3].position = v3(0.5, -0.5, 0);
    verts[3].tex_coord = v2(1, 1);
    
    glGenVertexArrays(1, *vertex_array);
    glBindVertexArray(vertex_array);
    
    vertex_buffer = create_buffer(GL_ARRAY_BUFFER, size_of(Vertex) * 4, verts.data);
    
    indices := u32.[ 0, 1, 2, 1, 3, 2 ];
    index_buffer = create_buffer(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * 6, indices.data);
    
    basic_shader = make_shader_program(basic_shader_text);
    coloured_shader = make_shader_program(coloured_shader_text);
    
    offset: *Vertex: null;
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), xx 0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), xx size_of(Vec3));
    
    set_camera_position(v2(0,0));
}

draw_texture :: (texture: *Texture, position: Vec2, colour: Vec4 = .{ 1, 1, 1, 1 }, custom_size := Vec2.{-1, -1}, depth := 0, tex_coords: [4] Vec2 = .[.{0,0}, .{0,1}, .{1,0}, .{1,1}]) {
    size := custom_size;
    if custom_size.x == -1 || custom_size.y == -1 {
        size = .{ xx texture.width, xx texture.height };
    }
    
    basic: Draw_Command;
    basic.type = .Basic;
    basic.basic = .{position, size, colour, texture.object};
    basic.depth = depth;
    add_render_command(basic);
}

draw_quad :: (position: Vec2, size: Vec2, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    coloured: Draw_Command;
    coloured.type = .Coloured;
    coloured.coloured = .{position, size, colour};
    add_render_command(coloured);
}

draw_wireframe_quad :: (position: Vec2, size: Vec2, thickness: float, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    top_position := position + Vec2.{ 0, size.y * 0.5 - thickness * 0.5 };
    top_size := Vec2.{ size.x, thickness };
    bottom_position := position - Vec2.{ 0, size.y * 0.5 - thickness * 0.5 };
    bottom_size := Vec2.{ size.x, thickness };
    left_position := position - Vec2.{ size.x * 0.5 - thickness * 0.5, 0 };
    left_size := Vec2.{ thickness, size.y };
    right_position := position + Vec2.{ size.x * 0.5 - thickness * 0.5, 0 };
    right_size := Vec2.{ thickness, size.y };
    
    coloured0: Draw_Command;
    coloured0.type = .Coloured;
    coloured0.coloured = .{top_position, top_size, colour};
    add_render_command(coloured0);
    
    coloured1: Draw_Command;
    coloured1.type = .Coloured;
    coloured1.coloured = .{bottom_position, bottom_size, colour};
    add_render_command(coloured1);
    
    coloured2: Draw_Command;
    coloured2.type = .Coloured;
    coloured2.coloured = .{left_position, left_size, colour};
    add_render_command(coloured2);
    
    coloured3: Draw_Command;
    coloured3.type = .Coloured;
    coloured3.coloured = .{right_position, right_size, colour};
    add_render_command(coloured3);
}

get_commands_of_type :: (commands: [] Draw_Command, type: Draw_Command_Type) -> [..] Draw_Command {
    out := tarray(Draw_Command);
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
    
    for basic_commands {
        prepare_basic_shader(*it.basic);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
    }
    
    for coloured_commands {
        prepare_coloured_shader(*it.coloured);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
    }
    
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
}

Basic_Command :: struct {
    position: Vec2;
    size: Vec2;
    colour: Vec4;
    texture: u32;
}

Coloured_Command :: struct {
    position: Vec2;
    size: Vec2;
    colour: Vec4;
}

Draw_Command :: struct {
    type: Draw_Command_Type;
    depth := 0;
    union {
        basic: Basic_Command;
        coloured: Coloured_Command;
    }
}

#scope_file

render_commands: [..] Draw_Command;

add_render_command :: (command: Draw_Command) {
    array_add(*render_commands, command);
}

Vertex :: struct {
    position: Vec3;
    tex_coord: Vec2;
}

vertex_buffer: u32;
index_buffer: u32;
vertex_array: u32;

create_buffer :: (target: u32, size: int, data: *void) -> u32 {
    object: u32;
    glGenBuffers(1, *object);
    glBindBuffer(target, object);
    glBufferData(target, xx size, data, GL_STATIC_DRAW);
    return object;
}

#import "Basic";
#import "GL";
#import "Sort";