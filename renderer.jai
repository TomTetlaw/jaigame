
camera_position: Vec2;

renderer_init :: () {
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
}

draw_texture :: (texture: *Texture, position: Vec2, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    prepare_basic_shader(position, .{ xx texture.width, xx texture.height }, colour, texture.object);
    glBindVertexArray(vertex_array);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
}

draw_quad :: (position: Vec2, size: Vec2, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    prepare_coloured_shader(position, size, colour);
    glBindVertexArray(vertex_array);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
}

draw_wireframe_quad :: (position: Vec2, size: Vec2, thickness: float, colour: Vec4 = .{ 1, 1, 1, 1 }) {
    top_position := position + Vec2.{ 0, size.y * 0.5 - thickness * 0.5 };
    top_size := Vec2.{ size.x, thickness };
    prepare_coloured_shader(top_position, top_size, colour);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
    
    bottom_position := position - Vec2.{ 0, size.y * 0.5 - thickness * 0.5 };
    bottom_size := Vec2.{ size.x, thickness };
    prepare_coloured_shader(bottom_position, bottom_size, colour);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
    
    left_position := position - Vec2.{ size.x * 0.5 - thickness * 0.5, 0 };
    left_size := Vec2.{ thickness, size.y };
    prepare_coloured_shader(left_position, left_size, colour);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
    
    right_position := position + Vec2.{ size.x * 0.5 - thickness * 0.5, 0 };
    right_size := Vec2.{ thickness, size.y };
    prepare_coloured_shader(right_position, right_size, colour);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
}

renderer_begin_frame :: () {
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);
}

bind_textures :: (textures: [] u32) {
    assert(textures.count <= 8);
    
    for 0..textures.count-1 {
        glActiveTexture(GL_TEXTURE0 + cast(u32) it);
        glBindTexture(GL_TEXTURE_2D, textures[it]);
    }
}

#scope_file

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