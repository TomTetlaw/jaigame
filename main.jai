
main :: () {
    window_width := 1920*.9;
    window_height := 1080*.9;
    
    SDL_Init(SDL_INIT_EVERYTHING);
    window := SDL_CreateWindow("Final", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx window_width, xx window_height, SDL_WINDOW_OPENGL);
    
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, xx SDL_GL_CONTEXT_DEBUG_FLAG);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
    gl_context := SDL_GL_CreateContext(window);
    
    version_string := to_string(glGetString(GL_VERSION));
    
    gl_load(*gl);
    
    load_all_textures();
    
    renderer_init(v2(xx window_width, xx window_height));
    editor_init();
        
    imgui_context := ImGui.CreateContext();
    ImGui_ImplSdl_Init(window);
    imgui_io = ImGui.GetIO();
    
    #if DEBUG_BUILD {
        game_paused = true;
        editor_open = true;
    }
    
    exit := false;
    while true {
        exit = process_window_events();
        if exit break;
        
        ImGui_ImplSdl_NewFrame(window);
        ImGui.NewFrame();
            
        if editor_open {
            editor_update();
            editor_do_imgui();
        }
        
        if !game_paused {
            update_entity_physics();
            update_game();
        }
        
        render_all_entities();
        if editor_open render_editor();
        render_game();
        
        if !game_paused game_do_imgui();

        renderer_do_commands();

        ImGui.Render();
        ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
        
        SDL_GL_SwapWindow(window);
        
        #if DO_PROFILING __Tracy.FrameMark();
    }
}

process_window_events :: () -> bool {
    event: SDL_Event;
    while SDL_PollEvent(*event) {
        if event.type == SDL_QUIT return true;
        
        ImGui_ImplSdl_ProcessEvent(*event);
        if !imgui_io.WantCaptureMouse {
            if event.type == SDL_MOUSEBUTTONUP || event.type == SDL_MOUSEBUTTONDOWN ||
               event.type == SDL_MOUSEMOTION {
                if editor_open editor_handle_mouse_event(*event);
                else game_handle_mouse_event(*event);
            }
        }
        
        if !imgui_io.WantCaptureKeyboard {
            if event.type == SDL_KEYUP || event.type == SDL_KEYDOWN {
                if editor_open editor_handle_keyboard_event(*event);
                else game_handle_keyboard_event(*event);
            }
        }
    }
    
    return false;
}

#scope_file

imgui_io: *ImGui.IO;

#import "Basic";
#import "Math";
#import "SDL";
#import "GL";

#load "C:/jai/modules/ImGui/examples/imgui_sdl_gl.jai";