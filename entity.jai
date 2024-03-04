
Entity_List :: struct {
    next_id: int;
    active_entities: [..] *Entity;
#insert DERIVED_ENTITY_LISTS;
}

entity_list: Entity_List;

Entity_Class :: #type,distinct s32;

Entity_Flags :: enum_flags u32 {
    Physics;
    CustomRender;
    Animation;
}

Animation_Mode :: enum {
    Once;
    Repeating;
}

Animation_Player :: struct {
    num_frames: int;
    frame_size: Vec2;
    fps: float;
    last_switch_time: float;            @no_imgui
    tex_coords: [4] Vec2;               @no_imgui
    texture: *Texture;
    mode: Animation_Mode;
    current_frame: int;                 @no_imgui
}

Entity :: struct {
    id: int;                            @no_imgui @no_serialize
    locator: Bucket_Locator;            @no_imgui @no_serialize
    class: Entity_Class;                @no_imgui @no_serialize
    flags: Entity_Flags = .Physics;
    
    position: Vec2;
    size := Vec2.{ -1, -1 };
    colour := Colour.{ 1, 1, 1, 1 };
    texture: *Texture;
    depth: int;
       
    // todo: serialize this
    animation: *Animation_Player;       @no_imgui @no_serialize
       
    velocity: Vec2;
    goal_velocity: Vec2;
    approach_speed := 100.0;
}

get_entity_size :: (using entity: *Entity) -> Vec2 {
    if !texture return .{0, 0};
    if size == .{ -1, -1 } return .{ xx texture.width, xx texture.height };
    return size;
}

entity_derived :: (default_texture: *Texture = null) #expand {
    `default_texture :: default_texture;
}

Entity_Ref:: struct {
    locator: Bucket_Locator;
    class: Entity_Class;
    id: int;
};

get_entity_ref :: (entity: *Entity) -> Entity_Ref {
    return .{ entity.locator, entity.class, entity.id };
}

get_entity_from_ref :: (ref: Entity_Ref) -> *Entity {
    entity := get_entity_from_locator(ref);
    if !entity return null;
    if entity.id != ref.id return null;
    return entity;
}

entity_cast :: (entity: *Entity, $T: Type) -> *T {
    array := array_for_entity(T);
    type_class := entity_class_for_type(T);
    
    if entity.class != type_class {
        log("Attempted to cast an entity to a type that it isn't! (was: %, given: %)", entity.class, type_class);
        return null;
    }
    
    return cast(*T) entity;
}

create_entity :: ($T: Type, id := -1) -> *T {
    array := array_for_entity(T);
    
    dummy: T;
    locator, entity := bucket_array_add(array, dummy);

    if id >= 0 {
        entity.id = id;
        entity_list.next_id = id + 1;
    } else {    
        entity.id = entity_list.next_id;
        entity_list.next_id += 1;
    }
    
    entity.locator = locator;
    entity.class = entity_class_for_type(T);
    entity.texture = default_texture_for_entity(entity.class);
    
    array_add(*entity_list.active_entities, entity);
    
    return entity;
}

start_animation :: (entity: *Entity, using animation: *Animation_Player) {
    if !animation.texture return;
    
    entity.animation = animation;
    last_switch_time = game_time;
    
    // set the tex coords for the first frame
    tex_coords[0] = .{0, 0};
    tex_coords[1] = .{0, 1};
    tex_coords[2] = .{frame_size.x / texture.width, 0};
    tex_coords[3] = .{frame_size.x / texture.width, 1};
}

stop_animation :: (entity: *Entity) {
    entity.animation = null;
}

update_animation :: (entity: *Entity, using animation: *Animation_Player) {
    if !animation return;
    if !texture return;
    
    if game_time > last_switch_time + (1.0 / fps) {
        last_switch_time = game_time;
        current_frame = (current_frame + 1) % num_frames;
        frame_x := (current_frame % num_frames) * frame_size.x;
        
        tex_coords[0] = .{frame_x / texture.width,                0};
        tex_coords[1] = .{frame_x / texture.width,                1};
        tex_coords[2] = .{(frame_x + frame_size.x) / texture.width, 0};
        tex_coords[3] = .{(frame_x + frame_size.x) / texture.width, 1};
        
        if mode == .Once && current_frame >= num_frames {
            stop_animation(entity);
        }
    }
}

render_all_entities :: () {
    for entity_list.active_entities {
        if it.flags & .CustomRender continue;
        
        position := it.position;
        size := get_entity_size(it);
        texture := it.texture;
        colour := it.colour;

        if (it.flags & .Animation) && it.animation {
            update_animation(it, it.animation);
            draw_texture(it.animation.texture, position, colour, size, it.depth, it.animation.tex_coords);
        } else {        
            if texture draw_texture(texture, position, colour, size, it.depth);
            else draw_quad(position, size, colour);
        }
    }
}

save_level :: (level_name: string) {
    make_directory_if_it_does_not_exist(tprint("levels/%", level_name));
    
    path := level_name;
    if equal(level_name, "") path = "_temp";
    files := file_list(tprint("levels/%", path));
    for files file_delete(it);
    
    for entity_list.active_entities {
        file_name := tprint("levels/%/%.entity", path, it.id);
        string_to_write := serialize_entity(it);
        write_entire_file(file_name, string_to_write);
    }
}

load_level :: (level_name: string) {
    remove_all_entities();
    
    path := level_name;
    if equal(level_name, "") path = "_temp";
    files := file_list(tprint("levels/%", path));
    for files {
        success1, lines := file_to_array(it);
        if !success1 continue;
 
        class: string;
        id, version: int;
        scan2(lines[0], "[%, %, %]", *class, *version, *id);
        advance(*lines);
        
        e := create_entity_by_type_name(class, id);
        if !e continue;
        
        members: Table(string, string);       
        for line: lines {
            name := parse_token(*line);
            parse_token(*line);
            value := parse_token(*line);
            
            table_add(*members, name, value);
        }
        
        deserialize_entity(e, version, *members);
    }
}

serialize :: (builder: *String_Builder, name: string, value: *int) { 
    append(builder, tprint("% = %\n", name, <<value));
}
serialize :: (builder: *String_Builder, name: string, value: *float) {
    append(builder, tprint("% = %\n", name, <<value));
}
serialize :: (builder: *String_Builder, name: string, value: *bool) {
    append(builder, tprint("% = %\n", name, <<value));
}
serialize :: (builder: *String_Builder, name: string, value: *Vec2) { 
    append(builder, tprint("% = %,%\n", name, value.x, value.y));
}
serialize :: (builder: *String_Builder, name: string, value: *Vec4) {
    append(builder, tprint("% = %,%,%,%\n", name, value.x, value.y, value.z, value.w));
}
serialize :: (builder: *String_Builder, name: string, value: *Colour) {
    vec := <<value;
    append(builder, tprint("% = %,%,%,%\n", name, vec.x, vec.y, vec.z, vec.w));
}
serialize :: (builder: *String_Builder, name: string, value: **Texture) {
    if !<<value append(builder, tprint("% = none\n", name));
    else append(builder, tprint("% = %\n", name, (<<value).path));
}
serialize :: (builder: *String_Builder, name: string, array: *[..] $T) {
    append(builder, tprint("%.count = %\n", name, array.count));
    for * <<array {
        serialize(builder, tprint("%[%]", name, it_index), it);
    }
}
serialize :: (builder: *String_Builder, name: string, array: *[$N] $T) {
    for * <<array {
        serialize(builder, tprint("%[%]", name, it_index), it);
    }
}
serialize :: (builder: *String_Builder, name: string, value: *$T) #modify {
    s := cast(*Type_Info) T;
    return s.type == .ENUM;
}
{
    append(builder, tprint("% = %\n", name, cast(int) (<<value)));
}

serialize_helper :: (info: *Type_Info, member_prefix := "value.") -> string {
    builder: String_Builder;
    
    s := cast(*Type_Info_Struct) info;
    for s.members {
        if find_note(it.notes, "no_serialize") continue;
        if equal(it.name, "VERSION") continue;
        
        if it.type.type == .STRUCT && not_easy_struct(it.type) {
            prefix := tprint("%0%.", member_prefix, it.name);
            append(*builder, serialize_helper(it.type, prefix));
        } else {
            append(*builder, tprint("serialize(builder, tprint(\"%%.%0%\", name), *%0%);\n", member_prefix, it.name, member_prefix, it.name));
        }
    }
    
    out := builder_to_string(*builder);
    return out;
}

serialize :: (builder: *String_Builder, name: string, value: *$T) #modify {
    s := cast(*Type_Info) T;
    return s.type == .STRUCT;
}
{
    info := cast(*Type_Info_Struct) T;
    #insert #run serialize_helper(type_info(T));
}

deserialize :: (values: *Table(string, string), version: int, name: string, value: *int) { 
    v := table_find_pointer(values, name);
    if v then <<value = parse_int(v);
    else log("couldn't deserialize field % (not found)", name);
}
deserialize :: (values: *Table(string, string), version: int, name: string, value: *float) {
    v := table_find_pointer(values, name);
    if v then <<value = parse_float(v);
    else log("couldn't deserialize field % (not found)", name);
}
deserialize :: (values: *Table(string, string), version: int, name: string, value: *bool) {
    v := table_find_pointer(values, name);
    if v then <<value = parse_bool(v);
    else log("couldn't deserialize field % (not found)", name);
}
deserialize :: (values: *Table(string, string), version: int, name: string, value: *Vec2) { 
    v := table_find_pointer(values, name);
    if v then <<value = parse_vec2(<<v);
    else log("couldn't deserialize field % (not found)", name);
}
deserialize :: (values: *Table(string, string), version: int, name: string, value: *Vec4) {
    v := table_find_pointer(values, name);
    if v then <<value = parse_vec4(<<v);
    else log("couldn't deserialize field % (not found)", name);
}
deserialize :: (values: *Table(string, string), version: int, name: string, value: *Colour) {
    v := table_find_pointer(values, name);
    if v then <<value = parse_colour(<<v);
    else log("couldn't deserialize field % (not found)", name);
}
deserialize :: (values: *Table(string, string), version: int, name: string, value: **Texture) {
    v := table_find_pointer(values, name);
    if v then <<value = texture_for_path(<<v);
    else log("couldn't deserialize field % (not found)", name);
}
deserialize :: (values: *Table(string, string), version: int, name: string, array: *[..] $T) {
    v := table_find_pointer(values, tprint("%.count", name));
    if v {
        count := parse_int(v);
        array_reserve(array, count);
        array.count = count;
        for 0..count-1 {
            deserialize(values, version, tprint("%[%]", name, it), *array.data[it]);
        }
    } else log("couldn't deserialize field %.count (not found)", name);
}

deserialize :: (values: *Table(string, string), version: int, name: string, array: *[$N] $T) {
    for 0..N-1 {
        deserialize(values, version, tprint("%[%]", name, it), *array.data[it]);
    }
}

deserialize_helper :: (info: *Type_Info, member_prefix := "value.") -> string {
    builder: String_Builder;
    
    s := cast(*Type_Info_Struct) info;
    for s.members {
        if find_note(it.notes, "no_serialize") continue;
        if equal(it.name, "VERSION") continue;

        version_min := 1;
        version_max := 9999;
        for note: it.notes {
            if note[0] == #char "v" {
                success := scan2(note, "v%-%", *version_min, *version_max);
                if !success {
                    scan2(note, "v%", *version_min);
                }
            }
        }
        
        append(*builder, tprint("if version >= % && version <= % {\n", version_min, version_max));
        if it.type.type == .STRUCT && not_easy_struct(it.type) {
            prefix := tprint("%0%.", member_prefix, it.name);
            append(*builder, deserialize_helper(it.type, prefix));
        } else {
            append(*builder, tprint("deserialize(values, version, tprint(\"%%.%0%\", name), *%0%);\n", member_prefix, it.name, member_prefix, it.name));
        }
        append(*builder, tprint("}\n"));
    }
    
    out := builder_to_string(*builder);
    return out;
}

deserialize :: (values: *Table(string, string), version: int, name: string, value: *$T) #modify {
    s := cast(*Type_Info) T;
    return s.type == .ENUM;
}
{
    v := table_find_pointer(values, name);
    if v then <<value = cast(T) parse_int(v);
    else log("couldn't deserialize field % (not found)", name);
}

deserialize :: (values: *Table(string, string), version: int, name: string, value: *$T) #modify {
    s := cast(*Type_Info) T;
    return s.type == .STRUCT;
}
{
    info := cast(*Type_Info_Struct) T;
    #insert #run deserialize_helper(type_info(T));
}

ENTITY_BUCKET_SIZE :: 256;

#import "Basic";
#import "Bucket_Array";
#import "Math";
#import "File_Utilities";
#import "Text_File_Handler";
#import "Hash_Table";