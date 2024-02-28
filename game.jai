
Player :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    base.approach_speed = 1000;   
    move_speed := 300.0;
    
    walk_animation: Animation_Player;
}

Parallax_Layer :: struct {
    VERSION :: 1;
    
    position: Vec2;
    texture: *Texture;
    depth := 0;
    colour: Colour = .{1, 1, 1, 1};
    lag_amount: float;
} 

Parallax_Background :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    base.flags = .CustomRender;
    
    layers: [..] Parallax_Layer;
}

delta_time, real_time, game_time, old_time: float;
game_paused: bool;

default_texture_for_entity :: (class: Entity_Class) -> *Texture {
    if class == _Player return _texture_player;
    return null;
}

game_handle_mouse_event :: (event: *SDL_Event) {
}

player_move: [2] bool;

game_handle_keyboard_event :: (event: *SDL_Event) {
    if event.type == SDL_KEYUP {
        if event.key.keysym.scancode == SDL_SCANCODE_F11 {
            editor_open = true;
            game_paused = true;
            load_level(current_level_name);
            set_camera_position(v2(0,0));
        }
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
    
    players := entity_list._Player;
    if players.count != 1 {
        log("There needs to be exactly one player in the level");
        return;
    }
    
    player = *players[0];
    start_animation(player, *player.walk_animation);
}

render_parallax_backgrounds :: () {
    for entity_list._Parallax_Background {
        for layer: it.layers {
            if !layer.texture continue;
            draw_texture(layer.texture, layer.position, layer.colour, depth=layer.depth);
        }
    }
}

update_parallax_backgrounds :: () {
    for entity_list._Parallax_Background {
        distance := player.position.x;
        for * layer: it.layers {
            layer.position.x = distance * layer.lag_amount;
        }
    }
}

update_game :: () {
    old_time = real_time;
    
    now := current_time_monotonic();
    real_time = cast(float) to_float64_seconds(now);
    
    if !game_paused {
        delta_time = real_time - old_time;
        game_time += delta_time;
    } else {
        delta_time = 0.0;
    }
    
    update_entity_physics();

    update_parallax_backgrounds();
    
    if !player return;
    player.goal_velocity = v2(0, 0);
    if player_move[0] {
        player.goal_velocity.x = -player.move_speed;
    }
    if player_move[1] {
        player.goal_velocity.x = player.move_speed;
    }
    
    set_camera_position(player.position);
}

render_game :: () {
    render_parallax_backgrounds();
}

#scope_file

player: *Player;