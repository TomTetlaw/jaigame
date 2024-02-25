Target_Mode :: enum {
    Debug;
    Release;
}

prepare_build_options :: (mode: Target_Mode, options: *Build_Options) {
    options.output_type = .EXECUTABLE;
    options.output_executable_name = "final";
    options.output_path = "build/";
    options.intermediate_path = "build/.build";
    
    options.backend = .LLVM;
    
    if mode == .Debug {
        set_optimization(options, .VERY_DEBUG);
    } else if mode == .Release {
        set_optimization(options, .VERY_OPTIMIZED);
    } else {
        assert(false, "Unhandled build mode!\n");
    }
}

do_build :: (mode: Target_Mode, options: *Build_Options) {
    workspace := compiler_create_workspace("Final workspace");
    if !workspace {
        print("Workspace creation failed!\n");
        return;
    }
    
    prepare_build_options(mode, options);
    set_build_options(options, workspace);
    
    compiler_begin_intercept(workspace);
    
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
    
    {
        files := file_list("build/textures/");

        builder: String_Builder;
        init_string_builder(*builder);
        
        for files {
            if ends_with(it, ".jpg") || ends_with(it, ".png") {
                path, basename, extension, filename := path_decomp(it);
                append(*builder, tprint("_texture_%: *Texture;\n", basename));
            }
        }
        
        append(*builder, "_all_textures: [..] *Texture;\n");
        
        append(*builder, "load_all_textures :: () {\n");
        for files {
            if ends_with(it, ".jpg") || ends_with(it, ".png") {
                path, basename, extension, filename := path_decomp(it);
                append(*builder, tprint("_texture_% = load_texture(\"textures/%\");\n", basename, filename));
                append(*builder, tprint("array_add(*_all_textures, _texture_%);\n", basename));
            }
        }
        append(*builder, "}\n"); 
     
        append(*builder, "texture_for_path :: (path: string) -> *Texture {\n");
        for files {
            if ends_with(it, ".jpg") || ends_with(it, ".png") {
                path, basename, extension, filename := path_decomp(it);
                append(*builder, tprint("if equal(path, \"textures/%\") return _texture_%;\n", filename, basename));
            }
        }
        append(*builder, "return null;\n");
        append(*builder, "}\n\n");
        
        add_build_string(builder_to_string(*builder), workspace);
    }
    
    print("Files in build: %\n", files_in_build);
    
    message_loop(workspace);
    
    compiler_end_intercept(workspace);
    
    set_build_options_dc(.{ do_output = false, write_added_strings = false });
}

message_loop :: (workspace: Workspace) {
    codegen: Codegen;
    
    while true {
        message := compiler_wait_for_message();
        if !message break;
        
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
    
    entity_structs: [..] *Type_Info_Struct;
}

note_struct :: (codegen: *Codegen, struct_info: *Type_Info_Struct) {
    if is_subclass_of(struct_info, "Entity") array_add_if_unique(*codegen.entity_structs, struct_info);
}

generate_code :: (codegen: *Codegen) -> string {
    print("Generating code...\n");
    
    names: [..] string;
    for codegen.entity_structs array_add(*names, it.name);
    print("Found entity types: %\n", names);
    
    builder: String_Builder;
    init_string_builder(*builder);
    
    append(*builder, "#import \"Bucket_Array\";\n");
    append(*builder, "#import \"File\";\n");
    
    for codegen.entity_structs {
        append(*builder, tprint("_%: Entity_Class = %;\n", it.name, it_index));
    }
    
    append(*builder, "entity_type_names := string.[");
    for codegen.entity_structs {
        append(*builder, tprint("\"%\", ", it.name));
    }
    append(*builder, "];\n\n");
    
    append(*builder, "create_entity_by_type_name :: (name: string) -> *Entity {\n");
    for codegen.entity_structs {
        append(*builder, tprint("    if equal(name, \"%\") return create_entity(%);\n", it.name, it.name));
    }
    append(*builder, "    assert(false);\n");
    append(*builder, "    return null;\n");
    append(*builder, "}\n\n");
    
    append(*builder, "create_entity_from_save :: (class: Entity_Class, id: int) -> *Entity {\n");
    append(*builder, "e: *Entity;\n");
    for codegen.entity_structs {
        append(*builder, tprint("if class == _% e = create_entity(%, id);\n", it.name, it.name));
    }
    append(*builder, "if !e { assert(false); return null; }\n");
    append(*builder, "return e;\n");
    append(*builder, "}\n\n");
    
    append(*builder, "entity_class_for_type :: ($T: Type) -> Entity_Class {\n");
    for codegen.entity_structs {
        append(*builder, tprint("    #if T == % return _%;\n", it.name, it.name));
    }
    append(*builder, "    assert(false);\n");
    append(*builder, "    return -1;\n");
    append(*builder, "}\n\n");
    
    append(*builder, "DERIVED_ENTITY_LISTS :: #string HERE\n");
    for codegen.entity_structs {
        append(*builder, tprint("_%: Bucket_Array(%, ENTITY_BUCKET_SIZE);\n", it.name, it.name));
    }
    append(*builder, "HERE\n\n");
    
    append(*builder, "array_for_entity :: ($T: Type) -> *Bucket_Array(T, ENTITY_BUCKET_SIZE) {\n");
    for codegen.entity_structs {
        append(*builder, tprint("    #if T == % return *entity_list._%;\n", it.name, it.name));
    }
    append(*builder, "    assert(false);\n");
    append(*builder, "    return null;\n");
    append(*builder, "}\n");
    
    append(*builder, "remove_entity :: (entity: *Entity) {\n");
    append(*builder, "    array_unordered_remove_by_value(*entity_list.active_entities, entity);\n");
    for codegen.entity_structs {
        append(*builder, tprint("    if entity.class == _% bucket_array_remove(*entity_list._%, entity.locator);\n", it.name, it.name));
    }
    append(*builder, "}\n");
    
    append(*builder, "remove_all_entities :: () {\n");
    append(*builder, "entity_list.active_entities.count = 0;\n");
    for codegen.entity_structs {
        append(*builder, tprint("for entity_list._% remove it;\n", it.name));
    }
    append(*builder, "}\n");
    
    append(*builder, "get_entity_from_locator :: (ref: Entity_Ref) -> *Entity {\n");
    for codegen.entity_structs {
        append(*builder, tprint("    if ref.class == _% return bucket_array_get(*entity_list._%, ref.locator);\n", it.name, it.name));
    }
    append(*builder, "    assert(false);\n");
    append(*builder, "    return null;\n");
    append(*builder, "}\n\n");
    
    append(*builder, "serialize_entity :: (entity: *Entity) -> string {\n");
    append(*builder, "builder: String_Builder;\n");
    for codegen.entity_structs {
        append(*builder, tprint("if entity.class == _% {\n", it.name));
        append(*builder, tprint("e := entity_cast(entity, %);\n", it.name));
        append(*builder, "v := e.VERSION;\n");
        append(*builder, tprint("append(*builder, tprint(\"%%\\n\", v));\n"));
        append(*builder, "serialize(*builder, \"\", e);\n");
        append(*builder, "}\n");
    }
    append(*builder, "return builder_to_string(*builder);\n");
    append(*builder, "}\n");
    
    append(*builder, "deserialize_entity :: (entity: *Entity, version: int, members: *Table(string, string)) {\n");
    for codegen.entity_structs {
        append(*builder, tprint("if entity.class == _% {\n", it.name));
        append(*builder, tprint("e := entity_cast(entity, %);\n", it.name));
        append(*builder, "deserialize(members, version, \"\", e);\n");
        append(*builder, "}\n");
    }
    append(*builder, "}\n");
    
    append(*builder, "do_entity_imgui :: (entity: *Entity) {\n");
    append(*builder, "ImGui.PushID(tprint(\"%\", entity.id));\n");
    for codegen.entity_structs {
        append(*builder, tprint("if entity.class == _% {\n", it.name));
        append(*builder, tprint("e := cast(*%) entity;\n", it.name));
        append(*builder, "do_custom_imgui(tprint(\"% (%)\", e.id, entity_type_names[e.class]), e);\n");
        append(*builder, "}\n");
    }
    append(*builder, "ImGui.PopID();\n");
    append(*builder, "}\n");
    
    return builder_to_string(*builder);
}

find_note :: (notes: [] string, note: string) -> bool {
    for notes if equal(it, note) return true;
    return false;
}

build :: () {
    options := get_build_options();
    args := options.compile_time_command_line;
    
    mode: Target_Mode = .Debug;
    
    for args {
        if it == {
            case "debug";
            mode = .Debug;
            case "release";
            mode = .Release;
        }
    }
    
    do_build(mode, *options);
}

#run build();

#import "Basic";
#import "Compiler";
#import "File_Utilities";
#import "String" ;