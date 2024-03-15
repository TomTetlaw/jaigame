Target_Mode :: enum {
    Debug;
    Release;
}

prepare_build_options :: (mode: Target_Mode, options: *Build_Options) {
    options.output_type = .EXECUTABLE;
    options.output_executable_name = "final";
    options.output_path = "build/";
    options.intermediate_path = "build/.build";
    
    options.additional_linker_arguments = .["Advapi32.lib"];
    
    options.backend = .LLVM;
    
    if mode == .Debug {
        set_optimization(options, .VERY_DEBUG);
    } else if mode == .Release {
        set_optimization(options, .VERY_OPTIMIZED);
    } else {
        assert(false, "Unhandled build mode!\n");
    }
}

tracy: *Metaprogram_Plugin;

do_build :: (mode: Target_Mode, do_profile: bool, options: *Build_Options) {
    workspace := compiler_create_workspace("Final workspace");
    if !workspace {
        print("Workspace creation failed!\n");
        return;
    }
    
    prepare_build_options(mode, options);
    set_build_options(options, workspace);
    
    if do_profile {
        flags: Intercept_Flags;
	    tracy = Tracy.get_plugin();
	    tracy.workspace = workspace;
	    defer Tracy.finish(tracy);
	    Tracy.before_intercept(tracy, *flags);
	}
    
    compiler_begin_intercept(workspace);
    
    if do_profile {
        Tracy.add_source(tracy);
        add_build_string("DO_PROFILING :: 1;\n", workspace);
    } else {
        add_build_string("DO_PROFILING :: 0;\n", workspace);
    }
    
    if mode == .Debug {
        add_build_string("DEBUG_BUILD :: 1;\n", workspace);
        add_build_string("RELEASE_BUILD :: 0;\n", workspace);
    } else {
        add_build_string("DEBUG_BUILD :: 0;\n", workspace);
        add_build_string("RELEASE_BUILD :: 1;\n", workspace);
    }
    
    files_in_build: [..] string;
    {
        files := file_list("./");
        for files {
            if ends_with(it, ".jai") {
                path := path_filename(it);
                if equal(path, "first.jai") continue; // don't cause infinite loop!
                array_add(*files_in_build, path_filename(path));
                add_build_file(path, workspace);
            }
        }
    }
    
    print("Files in build: %\n", files_in_build);
    
    message_loop(workspace, do_profile);
    
    compiler_end_intercept(workspace);
    
    set_build_options_dc(.{ do_output = false, write_added_strings = false });
}

message_loop :: (workspace: Workspace, do_profile: bool) {
    codegen: Codegen;
    
    while true {
        message := compiler_wait_for_message();
        if !message break;
        
        if do_profile {
            Tracy.message(tracy, message);
        }
        
        if message.kind == {
            case .TYPECHECKED;
            typechecked := cast(*Message_Typechecked) message;
            for typechecked.structs {
                note_struct(*codegen, it.expression.defined_type);
            }
            
            case .PHASE;
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN && !codegen.generated {
                build_string := generate_code(*codegen);
                add_build_string(build_string, workspace);
                codegen.generated = true;
            }
            
            case .COMPLETE;
            break;
        }
    }
}

Codegen :: struct {
    generated := false;
}

note_struct :: (codegen: *Codegen, struct_info: *Type_Info_Struct) {
}

generate_code :: (codegen: *Codegen) -> string {
    return "";
}

find_note :: (notes: [] string, note: string) -> bool {
    for notes if equal(it, note) return true;
    return false;
}

build :: () {
    options := get_build_options();
    args := options.compile_time_command_line;
    
    do_profile := false;
    
    mode: Target_Mode = .Debug;
    for args {
        if it == {
            case "debug";
            mode = .Debug;
            case "release";
            mode = .Release;
            case "profile";
            do_profile = true;
        }
    }
    
    do_build(mode, do_profile, *options);
}

#run build();

#import "Basic";
#import "Compiler";
#import "File_Utilities";
#import "String";
#import "Metaprogram_Plugins";
Tracy :: #import "jai-tracy";