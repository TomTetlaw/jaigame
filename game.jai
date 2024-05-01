
real_time, game_time, delta_time := 0.0;
game_paused := true;

init_game :: () {
    debug_font = load_font("fonts/consolas.ttf", 16.0);
}

game_draw :: () {
    debug_show_vars(real_time, game_time, delta_time, game_paused);
    debug_string("Hello");
    debug_show_vars(real_time, game_time, delta_time, game_paused);
    debug_string("Hello");
    debug_show_vars(real_time, game_time, delta_time, game_paused);
    debug_string("Hello");
    debug_show_vars(real_time, game_time, delta_time, game_paused);
    debug_string("Hello");
    debug_show_vars(real_time, game_time, delta_time, game_paused);
}

game_update :: () {
    // update time
    {
        now := current_time_monotonic();
        delta := now - old_time;
        
        real_time = xx to_float64_seconds(now);
        
        if game_paused {
            delta_time = 0.0;
        } else {
            delta_time = xx to_float64_seconds(delta);
            game_time += delta_time;
        }
        
        old_time = now;
    }
    
    if key_pressed(SDLK_SPACE) game_paused = !game_paused;
    
    keys_this_frame.count = 0;
}

game_input :: (down: bool, code: SDL_Keycode) {
    if down array_add(*keys_this_frame, code);
}

#scope_file

old_time: Apollo_Time;

debug_font: *Font;

key_pressed :: (code: SDL_Keycode) -> bool {
    for keys_this_frame if it == code return true;
    return false;
}

keys_this_frame: [..] SDL_Keycode;

#import "SDL";