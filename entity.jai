
Entity_List :: struct {
    next_id: int;
    active_entities: [..] *Entity;
#insert DERIVED_ENTITY_LISTS;
}

#add_context entity_list: Entity_List;

Entity_Class :: #type,distinct s32;

Entity_Flags :: enum_flags u32 {
}

Entity :: struct {
    id: int;                 @no_imgui @no_serialize
    locator: Bucket_Locator; @no_imgui @no_serialize
    class: Entity_Class;     @no_imgui @no_serialize
    flags: Entity_Flags;     @no_imgui
    
    position: Vec2;
    size := Vec2.{ -1, -1 };
    colour := Colour.{ 1, 1, 1, 1 };
    texture: *Texture;
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

create_entity :: ($T: Type, id: int = -1) -> *T {
    entity_list := *context.entity_list; 
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

render_all_entities :: () {
    entity_list := *context.entity_list;
    for entity_list.active_entities {
        position := it.position;
        size := get_entity_size(it);
        texture := it.texture;
        colour := it.colour;
        
        if texture draw_texture(texture, position, colour);
        else draw_quad(position, size, colour);
    }
}

save_level :: (level_name: string) {
    entity_list := *context.entity_list;
    make_directory_if_it_does_not_exist(tprint("levels/%", level_name));
    
    path := level_name;
    if equal(level_name, "") path = "_temp";
    files := file_list(tprint("levels/%", path));
    for files file_delete(it);
    
    for entity_list.active_entities {
        file_name := tprint("levels/%/%_%.entity", path, it.id, it.class);
        string_to_write := save_entity(file_name, it);
        write_entire_file(file_name, string_to_write);
    }
}

load_level :: (level_name: string) {
    remove_all_entities();
    
    path := level_name;
    if equal(level_name, "") path = "_temp";
    files := file_list(tprint("levels/%", path));
    for files {
        id, class: int;
        success0 := scan2(it, tprint("levels/%/%%_%%.entity", path), *id, *class);
        if !success0 continue;
        
        e := create_entity_from_save(cast(Entity_Class) class, id);
        if !e continue;
        
        success1, lines := file_to_array(it);
        if !success1 continue;
 
        version := parse_int(*lines[0]);
        array_advance(*lines);
        
        members: Table(string, string);       
        for line: lines {
            name := parse_token(*line);
            parse_token(*line);
            value := parse_token(*line);
            
            table_add(*members, name, value);
        }
        
        load_entity(e, version, *members);
    }
}

find_entities_by_class :: (class: Entity_Class) -> [..] *Entity {
    out: [..] *Entity;
    
    entity_list := *context.entity_list;
    for entity_list.active_entities {
        if it.class == class array_add(*out, it);
    }
    
    return out;
}

ENTITY_BUCKET_SIZE :: 256;

#import "Basic";
#import "Bucket_Array";
#import "Math";
#import "File_Utilities";
#import "Text_File_Handler";
#import "Hash_Table";