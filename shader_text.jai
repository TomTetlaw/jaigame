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

prepare_basic_shader :: (args: *Basic_Command) {
    final_position := args.position - camera_position + camera_focus_point;
    position_size := Vec4.{final_position.x, final_position.y, args.size.x, args.size.y};
    projection := orthographic_projection_matrix(0, render_size.x, 0, render_size.y, -1, 1);
    
    glUseProgram(basic_shader.program);
    
    set_shader_vec4(*basic_shader, "position_size", position_size);
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

prepare_coloured_shader :: (args: *Coloured_Command) {
    final_position := args.position - camera_position + camera_focus_point;
    position_size := Vec4.{final_position.x, final_position.y, args.size.x, args.size.y};
    projection := orthographic_projection_matrix(0, render_size.x, 0, render_size.y, -1, 1);
    
    glUseProgram(coloured_shader.program);
    
    set_shader_vec4(*basic_shader, "position_size", position_size);
    set_shader_mat4(*basic_shader, "projection_matrix", xx projection, true);
    set_shader_vec4(*basic_shader, "colour", args.colour);    
}

// -------------------------------------------