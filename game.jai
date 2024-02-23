
Player :: struct {
    using #as base: Entity;
    VERSION :: 1;
}

Prop :: struct {
    using #as base: Entity;
    VERSION :: 1;
}

Blocker :: struct {
    using #as base: Entity;
    VERSION :: 1;
}

Test_Struct :: struct {
    my_int2: int;
    my_float2: float;
}

Enemy :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    my_int1: int;
    my_float1: float;
    my_struct: Test_Struct;
    my_bool: bool;
    
    my_colour: Colour; @v1
}

Parallax_Layer :: struct {
    position: Vec2;
    texture: *Texture;
    move_rate: float;
} @do_imgui

Parallax_Background :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    ints: [..] int;
    layers: [..] Parallax_Layer;
}

delta_time, real_time, game_time, old_time: float64;
game_paused: bool;

default_texture_for_entity :: (class: Entity_Class) -> *Texture {
    if class == _Player return _texture_player;
    if class == _Prop return _texture_hall;
    if class == _Blocker return _texture_box;
    if class == _Enemy return _texture_skeleton;
    return null;
}

update_game :: () {
    old_time = real_time;
    
    now := current_time_monotonic();
    real_time = to_float64_seconds(now);
    
    if !game_paused {
        delta_time = real_time - old_time;
        game_time += delta_time;
    } else {
        delta_time = 0.0;
    }
}