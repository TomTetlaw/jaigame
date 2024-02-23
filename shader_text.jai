basic_shader_text := #string HERE

INOUT vec2 frag_tex_coord;
INOUT vec4 frag_colour;

#if VERTEX_SHADER

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec2 vertex_tex_coord;

uniform vec4 position_size;
uniform mat4 projection_matrix;
uniform vec4 colour;

void main() {
    vec3 position = vertex_position;
    position *= vec3(position_size.z, position_size.w, 0);
    position += vec3(position_size.x, position_size.y, 0);
    
    frag_tex_coord = vertex_tex_coord;
    frag_colour = colour;
    
    gl_Position = projection_matrix * vec4(position, 1);
}

#endif

#if FRAGMENT_SHADER

uniform sampler2D base_texture;
out vec4 output_colour;

void main() {
    vec4 final_colour = frag_colour * texture(base_texture, frag_tex_coord);
    if (final_colour.a < .5) discard;
    output_colour = final_colour;
}

#endif

HERE

basic_shader: Shader;

prepare_basic_shader :: (position: Vec2, size: Vec2, colour: Vec4, texture: u32) {
    program := basic_shader.program;
    
    glUseProgram(program);
    
    position_size_loc := glGetUniformLocation(program, "position_size");
    final_position := position - camera_position;
    glUniform4f(position_size_loc, final_position.x, final_position.y, size.x, size.y);
    
    projection: Matrix4 = orthographic_projection_matrix(0, 1366, 0, 768, -1, 1);
    projection_loc := glGetUniformLocation(program, "projection_matrix");
    glUniformMatrix4fv(projection_loc, 1, GL_TRUE, cast (*float) *projection);
    
    colour_loc := glGetUniformLocation(program, "colour");
    glUniform4f(colour_loc, colour.x, colour.y, colour.z, colour.w);
    
    texture_loc := glGetUniformLocation(program, "base_texture");
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(texture_loc, 0);
}

// -------------------------------------------

coloured_shader_text := #string HERE

INOUT vec2 frag_tex_coord;
INOUT vec4 frag_colour;

#if VERTEX_SHADER

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec2 vertex_tex_coord;

uniform vec4 position_size;
uniform mat4 projection_matrix;
uniform vec4 colour;

void main() {
    vec3 position = vertex_position;
    position *= vec3(position_size.z, position_size.w, 0);
    position += vec3(position_size.x, position_size.y, 0);
    
    frag_tex_coord = vertex_tex_coord;
    frag_colour = colour;
    
    gl_Position = projection_matrix * vec4(position, 1);
}

#endif

#if FRAGMENT_SHADER

uniform sampler2D base_texture;
out vec4 output_colour;

void main() {
    output_colour = frag_colour;
}

#endif

HERE

coloured_shader: Shader;

prepare_coloured_shader :: (position: Vec2, size: Vec2, colour: Vec4) {
    program := coloured_shader.program;
    
    glUseProgram(program);

    final_position := position - camera_position;
    position_size_loc := glGetUniformLocation(program, "position_size");
    glUniform4f(position_size_loc, final_position.x, final_position.y, size.x, size.y);
    
    projection: Matrix4 = orthographic_projection_matrix(0, 1366, 0, 768, -1, 1);
    projection_loc := glGetUniformLocation(program, "projection_matrix");
    glUniformMatrix4fv(projection_loc, 1, GL_TRUE, cast (*float) *projection);
    
    colour_loc := glGetUniformLocation(program, "colour");
    glUniform4f(colour_loc, colour.x, colour.y, colour.z, colour.w);
}

// -------------------------------------------