basic_shader_text := #string HERE

INOUT vec2 frag_tex_coord;
INOUT vec4 frag_colour;

#if VERTEX_SHADER

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec2 vertex_tex_coord;

uniform mat4 projection_matrix;
uniform vec4 colour;

void main() {
    vec3 position = vertex_position;
    
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
    output_colour = final_colour;
}

#endif

HERE

basic_shader: Shader;

prepare_basic_shader :: (args: *Draw_Command) {
    projection := orthographic_projection_matrix(0, render_size.x, render_size.y, 0, -1, 1);
    
    glUseProgram(basic_shader.program);
    
    set_shader_mat4(*basic_shader, "projection_matrix", xx projection, true);
    set_shader_vec4(*basic_shader, "colour", args.colour);
    set_shader_texture(*basic_shader, "base_texture", args.texture, 0);
}

// -------------------------------------------

coloured_shader_text := #string HERE

INOUT vec2 frag_tex_coord;
INOUT vec4 frag_colour;

#if VERTEX_SHADER

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec2 vertex_tex_coord;

uniform mat4 projection_matrix;
uniform vec4 colour;

void main() {
    vec3 position = vertex_position;
    
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

prepare_coloured_shader :: (args: *Draw_Command) {
    projection := orthographic_projection_matrix(0, render_size.x, render_size.y, 0, -1, 1);
    
    glUseProgram(coloured_shader.program);
    
    set_shader_mat4(*coloured_shader, "projection_matrix", xx projection, true);
    set_shader_vec4(*coloured_shader, "colour", args.colour);    
}

// -------------------------------------------

font_shader_text := #string HERE

INOUT vec2 frag_tex_coord;
INOUT vec4 frag_colour;

#if VERTEX_SHADER

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec2 vertex_tex_coord;

uniform mat4 projection_matrix;
uniform vec4 colour;

void main() {
    vec3 position = vertex_position;
    
    frag_tex_coord = vertex_tex_coord;
    frag_colour = colour;
    
    gl_Position = projection_matrix * vec4(position, 1);
}

#endif

#if FRAGMENT_SHADER

uniform sampler2D base_texture;
out vec4 output_colour;

void main() {
    vec4 sample = texture(base_texture, frag_tex_coord);
    output_colour = vec4(1, 1, 1, sample.r) * frag_colour;
}

#endif

HERE

font_shader: Shader;

prepare_font_shader :: (args: *Draw_Command) {
    projection := orthographic_projection_matrix(0, render_size.x, render_size.y, 0, -1, 1);
    
    glUseProgram(font_shader.program);
    
    set_shader_mat4(*font_shader, "projection_matrix", xx projection, true);
    set_shader_vec4(*font_shader, "colour", args.colour);
    set_shader_texture(*font_shader, "base_texture", args.texture, 0);
}