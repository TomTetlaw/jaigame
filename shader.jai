
Shader :: struct {
    program: u32;
    uniforms: [..] s32;
    hash_map: [] int;
}

get_shader_location :: (shader: *Shader, name: string) -> s32 {
    hash_index := get_hash(name) % 1024;
    index := shader.hash_map[hash_index];
    loc := shader.uniforms[index];
    log_vars(hash_index);
    return loc;
}

set_shader_int :: (shader: *Shader, name: string, value: s32) {
    loc := get_shader_location(shader, name);
    glUniform1i(loc, value);
}

set_shader_vec2 :: (shader: *Shader, name: string, value: Vec2) {
    loc := get_shader_location(shader, name);
    glUniform2f(loc, value.x, value.y);
}

set_shader_vec4 :: (shader: *Shader, name: string, value: Vec4) {
    loc := get_shader_location(shader, name);
    glUniform4f(loc, value.x, value.y, value.z, value.w);
}

set_shader_mat4 :: (shader: *Shader, name: string, value: Mat4, transpose := false) {
    loc := get_shader_location(shader, name);
    glUniformMatrix4fv(loc, 1, ifx transpose then GL_TRUE else GL_FALSE, cast (*float) *value);
}

set_shader_texture :: (shader: *Shader, name: string, value: u32, unit: u32) {
    loc := get_shader_location(shader, name);
    glActiveTexture(GL_TEXTURE0 + unit);
    glBindTexture(GL_TEXTURE_2D, value);
    glUniform1ui(loc, unit);
}

make_shader_program :: (shader_text: string) -> Shader {
    make_shader_object :: (shader: string, prefix: string, shader_type : u32) -> u32 {
        shader_object := glCreateShader(shader_type);
        
        shaders: [2] *u8;
        lengths: [2] s32;
        
        shaders[0] = prefix.data;
        shaders[1] = shader.data;
        lengths[0] = xx prefix.count;
        lengths[1] = xx shader.count;
        
        glShaderSource(shader_object, 2, shaders.data, lengths.data);
        
        glCompileShader(shader_object);
        
        success : GLint;
        glGetShaderiv(shader_object, GL_COMPILE_STATUS, *success);
        
        if !success then {
            log_data: [4096] u8;
            glGetShaderInfoLog(shader_object, log_data.count, null, log_data.data);
            log(to_string(log_data.data));
            return 0;
        }
        
        return shader_object;
    }
    
    PREFIX_V := #string HERE
#version 330 core
#define VERTEX_SHADER 1
#define FRAGMENT_SHADER 0
#define INOUT out
        HERE;
    
    PREFIX_F := #string HERE
#version 330 core
#define VERTEX_SHADER 0
#define FRAGMENT_SHADER 1
#define INOUT in
        HERE;
    
    shader_v := make_shader_object(shader_text, PREFIX_V, GL_VERTEX_SHADER);
    shader_f := make_shader_object(shader_text, PREFIX_F, GL_FRAGMENT_SHADER);
    shader_p := glCreateProgram();
    
    glAttachShader(shader_p, shader_v);
    glAttachShader(shader_p, shader_f);
    glLinkProgram(shader_p);
    
    success : GLint = 0;
    glGetProgramiv(shader_p, GL_LINK_STATUS, *success);
    
    if !success {
        log_data: [4096] u8;
        glGetProgramInfoLog(shader_p, log_data.count, null, log_data.data);
        log(to_string(log_data.data));
        return .{};
    }
    
    glDeleteShader(shader_v);
    glDeleteShader(shader_f);
    
    glValidateProgram(shader_p);
    glGetProgramiv(shader_p, GL_VALIDATE_STATUS, *success);
    
    if !success {
        log_data: [4096] u8;
        glGetProgramInfoLog(shader_p, log_data.count, null, log_data.data);
        log(to_string(log_data.data));
        return .{};
    }
    
    shader: Shader;
    shader.program = shader_p;
    shader.hash_map = NewArray(1024, int);
    
    active_uniform_count: s32;
    glGetProgramiv(shader_p, GL_ACTIVE_UNIFORMS, *active_uniform_count);
    for 0..active_uniform_count-1 {
        buffer: [128] u8;
        length: u32;
        size: s32;
        type: u32;
        glGetActiveUniform(shader_p, xx it, 128, *length, *size, *type, buffer.data);
        loc := glGetUniformLocation(shader_p, buffer.data);
        
        uniform_name := cast(string) buffer;
        uniform_name.count = c_style_strlen(buffer.data);
        hash_index := get_hash(uniform_name) % 1024;
        shader.hash_map[hash_index] = shader.uniforms.count;
        array_add(*shader.uniforms, loc);
    }
    
    return shader;
}

#import "Hash";
#import "Print_Vars";