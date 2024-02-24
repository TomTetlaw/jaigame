
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
} 

Parallax_Background :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    ints: [..] int;
    layers: [..] Parallax_Layer;
}

dt32: float;
delta_time, real_time, game_time, old_time: float64;
game_paused: bool;

default_texture_for_entity :: (class: Entity_Class) -> *Texture {
    if class == _Player return _texture_player;
    if class == _Prop return _texture_hall;
    if class == _Blocker return _texture_box;
    if class == _Enemy return _texture_skeleton;
    return null;
}

game_handle_mouse_event :: (event: *SDL_Event) {
}

player_move: [2] bool;

game_handle_keyboard_event :: (event: *SDL_Event) {
    if event.key.keysym.scancode == SDL_SCANCODE_ESCAPE {
        editor_open = true;
        game_paused = true;
        load_level(current_level_name);
    }

    if !player return;    
    if event.key.keysym.scancode == SDL_SCANCODE_A {
        player_move[0] = event.type == SDL_KEYDOWN;
    } else if event.key.keysym.scancode == SDL_SCANCODE_D {
        player_move[1] = event.type == SDL_KEYDOWN;
    }
}

start_game :: () {
    editor_open = false;
    game_paused = false;
    
    players := find_entities_by_class(_Player);
    if players.count != 1 {
        log("There needs to be exactly one player in the level");
        return;
    }
    
    player = entity_cast(players[0], Player);
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
    
    dt32 = cast(float) delta_time;
    
    if !player return;
    
    if player_move[0] player.position.x -= 100 * dt32;
    if player_move[1] player.position.x += 100 * dt32;
    
    set_camera_position(player.position);
}

#scope_file

player: *Player;