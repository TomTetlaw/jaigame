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
        append(*builder, "assert(false); return null;\n");
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
    append(*builder, "    entity_list := *context.entity_list;\n");
    for codegen.entity_structs {
        append(*builder, tprint("    #if T == % return *entity_list._%;\n", it.name, it.name));
    }
    append(*builder, "    assert(false);\n");
    append(*builder, "    return null;\n");
    append(*builder, "}\n");
    
    append(*builder, "remove_entity :: (entity: *Entity) {\n");
    append(*builder, "    entity_list := *context.entity_list;\n");
    append(*builder, "    array_unordered_remove_by_value(*entity_list.active_entities, entity);\n");
    for codegen.entity_structs {
        append(*builder, tprint("    if entity.class == _% bucket_array_remove(*entity_list._%, entity.locator);\n", it.name, it.name));
    }
    append(*builder, "}\n");
    
    append(*builder, "remove_all_entities :: () {\n");
    append(*builder, "    entity_list := *context.entity_list;\n");
    append(*builder, "entity_list.active_entities.count = 0;\n");
    for codegen.entity_structs {
        append(*builder, tprint("for entity_list._% remove it;\n", it.name));
    }
    append(*builder, "}\n");
    
    append(*builder, "delete_entity :: (entity: *Entity) {\n");
    append(*builder, "    entity_list := *context.entity_list;\n");
    for codegen.entity_structs {
        append(*builder, tprint("    if entity.class == _% bucket_array_remove(*entity_list._%, entity.locator);\n", it.name, it.name));
    }
    append(*builder, "}\n\n");
    
    append(*builder, "get_entity_from_locator :: (ref: Entity_Ref) -> *Entity {\n");
    append(*builder, "    entity_list := *context.entity_list;\n");
    for codegen.entity_structs {
        append(*builder, tprint("    if ref.class == _% return bucket_array_get(*entity_list._%, ref.locator);\n", it.name, it.name));
    }
    append(*builder, "    assert(false);\n");
    append(*builder, "    return null;\n");
    append(*builder, "}\n\n");
    
    append(*builder, "save_entity :: (level_name: string, entity: *Entity) -> string {\n");
    append(*builder, "builder: String_Builder;\n");
    for codegen.entity_structs { 
        array := collect_entity_members(it);
        append(*builder, tprint("if entity.class == _% {\n", it.name));
        append(*builder, tprint("e := entity_cast(entity, %);\n", it.name));
        append(*builder, tprint("append(*builder, tprint(\"%%\\n\", %.VERSION));\n", it.name));
        generate_save_code_for_members(*builder, array);
        append(*builder, "}\n");
    }
    append(*builder, "return builder_to_string(*builder);\n");
    append(*builder, "}\n\n");

    append(*builder, "load_entity :: (entity: *Entity, version: int, members: *Table(string, string)) {\n");
    for codegen.entity_structs {
        array := collect_entity_members(it);
        append(*builder, tprint("if entity.class == _% {\n", it.name));
        append(*builder, tprint("e := entity_cast(entity, %);\n", it.name));
        generate_load_code_for_members(*builder, array);
        append(*builder, "}\n");
    }
    append(*builder, "}\n\n");
    
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

Entity_Member_Type :: enum {
    Int;
    Float;
    Bool;
    Colour;
    Texture;
    Vec2;
    Vec4;
    Struct;
}

Entity_Member :: struct {
    type: Entity_Member_Type;
    full_name: string;
    name: string;
    version := 1;
    no_imgui: bool;
    no_serialize: bool;
    members: [..] Entity_Member; // for structs
}

collect_entity_members :: (s: *Type_Info_Struct, member_prefix := "e.") -> [..] Entity_Member {
    array: [..] Entity_Member;
    
    for s.members {
        if equal(it.name, "VERSION") continue;
        
        member: Entity_Member;
        member.no_imgui = find_note(it.notes, "no_imgui");
        member.no_serialize = find_note(it.notes, "no_serialize");
        member.name = it.name;
        member.full_name = tprint("%0%", member_prefix, it.name);
        
        for note: it.notes {
            if note.data[0] == #char "v" {
                version: int;
                success := scan2(note, "v%", *version);
                if success member.version = version;
            }
        }
        
        supported_type: bool;
        if it.type.type == .INTEGER {
            member.type = .Int;
            array_add(*array, member);
        } else if it.type.type == .FLOAT {
            member.type = .Float;
            array_add(*array, member);
        } else if it.type.type == .STRUCT {
            s_type_info := cast(*Type_Info_Struct) it.type;
            if equal(s_type_info.name, "Vec4") {
                member.type = .Vec4;
                array_add(*array, member);
            } else if equal(s_type_info.name, "Vec2") {
                member.type = .Vec2;
                array_add(*array, member);
            } else {
                member.type = .Struct;
                new_prefix := tprint("%0%0.", member_prefix, it.name);
                member_array := collect_entity_members(s_type_info, new_prefix);
                member.members = member_array;
                array_add(*array, member);
            }
        } else if it.type.type == .BOOL {
            member.type = .Bool;
        } else if it.type.type == .POINTER {
            info := cast(*Type_Info_Pointer) it.type;
            pointer_to := info.pointer_to;
            if pointer_to.type == .STRUCT {
                s_type_info := cast(*Type_Info_Struct) pointer_to;
                if equal(s_type_info.name, "Texture") {
                    member.type = .Texture;
                    array_add(*array, member);
                }
            }
        } else if it.type.type == .VARIANT {
            info := cast(*Type_Info_Variant) it.type;
            variant_of := info.variant_of;
            if equal(info.name, "Colour") {
                    member.type = .Colour;
                    array_add(*array, member);
            }
        }
    }
    
    return array;
}

generate_imgui_for_members :: (builder: *String_Builder, members: [..] Entity_Member) {
    for members {
        if it.no_imgui continue;
        
        if it.type != .Struct && it.type != .Texture {
            append(builder, "if ");
        }
        
        if it.type == {
            case .Int;
                append(builder, tprint("ImGui.DragScalar(\"%\", .S64, *%)", it.name, it.full_name));
            case .Float;
                append(builder, tprint("ImGui.DragFloat(\"%\", *%)", it.name, it.full_name)); 
            case .Bool;
                append(builder, tprint("ImGui.Checkbox(\"%\", *%)", it.name, it.full_name));
            case .Colour;
                append(builder, tprint("ImGui.ColorEdit4(\"%\", *%.component)", it.name, it.full_name));
            case .Vec2;
                append(builder, tprint("ImGui.DragFloat2(\"%\", *%.component)", it.name, it.full_name));
            case .Vec4;
                append(builder, tprint("ImGui.DragFloat4(\"%\", *%.component)", it.name, it.full_name));
            case .Texture;
                append(builder, tprint("texture_imgui(\"%\", *%);\n", it.name, it.full_name));
            case .Struct;
                append(builder, tprint("if ImGui.CollapsingHeader(\"%\") {\n", it.name));
                append(builder, "ImGui.Indent();\n");
                generate_imgui_for_members(builder, it.members);
                append(builder, "ImGui.Unindent();\n");
                append(builder, "}\n");
        }
        
        if it.type != .Struct && it.type != .Texture {
            append(builder, " editor_unsaved_changes = true;\n");
        }
    }
}

generate_save_code_for_members :: (builder: *String_Builder, members: [..] Entity_Member) {
    for members {
        if it.no_serialize continue;
        
        if it.type == {
            case .Int; 
            #through;
            case .Float; 
            #through;
            case .Bool; 
            append(builder, tprint("append(*builder, tprint(\"% = %%\\n\", %));\n", it.full_name, it.full_name));
            
            case .Vec2; 
            append(builder, tprint("append(*builder, tprint(\"% = %%,%%\\n\", %.x, %.y));\n", it.full_name, it.full_name, it.full_name));
            case .Vec4;
            #through;
            case .Colour; 
            append(builder, tprint("append(*builder, tprint(\"% = %%,%%,%%,%%\\n\", %.x, %.y, %.z, %.w));\n", it.full_name, it.full_name, it.full_name, it.full_name, it.full_name));
            
            case .Texture;
            append(builder, tprint("append(*builder, tprint(\"% = %%\\n\", %.path));\n", it.full_name, it.full_name));
            case .Struct;
            generate_save_code_for_members(builder, it.members);
        }
    }
}

generate_load_code_for_members :: (builder: *String_Builder, members: [..] Entity_Member) {
    for members {
        if it.no_serialize continue;
        
        if it.type != .Struct {
            append(builder, tprint("\t{\n\t\tvalue := table_find_pointer(members, \"%\");\n\t\tif value ", it.full_name));
        }
        
        if it.type == {
            case .Int;
            append(builder, tprint("% = parse_int(value);\n", it.full_name));
            case .Float;
            append(builder, tprint("% = parse_float(value);\n", it.full_name));
            case .Bool; 
            append(builder, tprint("% = parse_bool(value);\n", it.full_name));
            case .Vec4;
            append(builder, tprint("% = parse_vec4(<<value);\n", it.full_name));
            case .Colour; 
            append(builder, tprint("% = parse_colour(<<value);\n", it.full_name));
            case .Vec2;
            append(builder, tprint("% = parse_vec2(<<value);\n", it.full_name));
            case .Texture;
            append(builder, tprint("% = texture_for_path(<<value);\n", it.full_name));
            case .Struct;
            generate_load_code_for_members(builder, it.members);
        }
        
        if it.type != .Struct {
            append(builder, "\t}\n");
        }
    }
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