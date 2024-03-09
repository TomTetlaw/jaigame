
Player :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    base.flags = .Physics | .Animation;
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

Prop :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    base.flags = .Blocking;
}

Marker :: struct {
    using #as base: Entity;
    VERSION :: 1;
    
    name: string;
}

delta_time, real_time, game_time: float;
real_time_s128, old_time_s128, delta_time_s128: Apollo_Time;
game_paused: bool;

default_texture_for_entity :: (class: Entity_Class) -> string {
    if class == _Player return "textures/player.png";
    return "";
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

    if event.key.keysym.scancode == SDL_SCANCODE_A {
        player_move[0] = event.type == SDL_KEYDOWN;
    } else if event.key.keysym.scancode == SDL_SCANCODE_D {
        player_move[1] = event.type == SDL_KEYDOWN;
    }
}

find_marker :: (name: string) -> (Vec2, bool) {
    for * entity_list._Marker if it.name == name return it.position, true;
    return .{0, 0}, false;
}

start_game :: () {
    editor_open = false;
    game_paused = false;
    
    game_time = 0.0;
    
    // so that the first frame DT isn't huge
    now := current_time_monotonic();
    old_time_s128 = now;
    real_time_s128 = now;
    
    focus_marker, found := find_marker("camera_focus");
    if found camera_focus_point = focus_marker;
    
    players := entity_list._Player;
    if players.count != 1 {
        fatal_error("There needs to be exactly one player in the level");
        return;
    }
    
    player = *players[0];
    start_animation(player, *player.walk_animation);
}

game_do_imgui :: () {
    ImGui.Begin("Game State");
    
    ImGui.Text(tprint("real_time: %", real_time));
    ImGui.Text(tprint("game_time: %", game_time));
    ImGui.Text(tprint("delta_time: %", delta_time));
    
    ImGui.End();
}

render_parallax_backgrounds :: () {
    for entity_list._Parallax_Background {
        for layer: it.layers {
            if !layer.texture continue;
            
            if player {
                player_pos := player.position;
                player_relative_slot := truncate((player_pos.x-layer.position.x) / layer.texture.width);
                
                position0 := Vec2.{
                    layer.position.x + (player_relative_slot - 1) * layer.texture.width, 
                    layer.position.y
                };
                position1 := Vec2.{
                    layer.position.x + (player_relative_slot) * layer.texture.width, 
                    layer.position.y
                };
                position2 := Vec2.{
                    layer.position.x + (player_relative_slot + 1) * layer.texture.width, 
                    layer.position.y
                };
                
                draw_texture(layer.texture, position0, layer.colour, depth=layer.depth);
                draw_texture(layer.texture, position1, layer.colour, depth=layer.depth);
                draw_texture(layer.texture, position2, layer.colour, depth=layer.depth);
            } else {
                draw_texture(layer.texture, layer.position, layer.colour, depth=layer.depth);
            }
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
    old_time_s128 = real_time_s128;
    real_time_s128 = current_time_monotonic();
    delta_time_s128 = real_time_s128 - old_time_s128;
    
    real_time = cast(float) to_float64_seconds(real_time_s128);
    
    if !game_paused {
        delta_time = cast(float) to_float64_seconds(delta_time_s128);
        game_time = game_time + delta_time;
    } else {
        delta_time = 0.0;
    }

    update_parallax_backgrounds();
    
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