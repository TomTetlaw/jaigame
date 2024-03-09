
editor_open: bool;
editor_unsaved_changes: bool;
current_level_name: string;

editor_init :: () {
    x_axis.texture = load_texture("textures/x_axis.png");
    y_axis.texture = load_texture("textures/y_axis.png");
    x_axis.size = Vec2.{ xx x_axis.texture.width, xx x_axis.texture.height };
    y_axis.size = Vec2.{ xx y_axis.texture.width, xx y_axis.texture.height };
}

render_editor :: () {
    if !editor_open return;

    for entity_list.active_entities {
        position := it.position;
        size := get_entity_size(it);
        
        if array_find(selected_entities, it) {
            colour0 := v4(1, 0, 0, 1);
            colour1 := v4(0, 0, 1, 1);
            t := sin(cast(float32) real_time * 5) * 0.5 + 0.5;
            border_colour := lerp(colour0, colour1, t);
            draw_wireframe_quad(position, size, 2, border_colour); 
        } else {
            draw_wireframe_quad(position, size, 2); 
        }
    }
    
    if dragging && !moving_entities {
        draw_wireframe_quad(
            lerp(mouse_position, drag_origin, 0.5),
            mouse_position - drag_origin, 
            1,
            .{ 0, 1, 0, 1}
        );
    }
    
    if selected_entities.count > 0 {
        entity := selected_entities[0];
        x_axis_colour := Vec4.{ 1, 0, 0, 1 };
        y_axis_colour := Vec4.{ 0, 1, 0, 1 };
        if point_inside_rect(mouse_position, x_axis.position, x_axis.size)
             x_axis_colour = .{ 1, 1, 0, 1 };
        if point_inside_rect(mouse_position, y_axis.position, y_axis.size)
            y_axis_colour = .{ 1, 1, 0, 1 };
        draw_texture(*x_axis.texture, x_axis.position, x_axis_colour); 
        draw_texture(*y_axis.texture, y_axis.position, y_axis_colour);
    }
}

editor_load_level :: () {
    load_level(level_name);
    current_level_name = level_name;
}

editor_save_level :: () {
    save_level(level_name);
    current_level_name = level_name;
    editor_unsaved_changes = false;
}

editor_do_imgui :: () {
    ImGui.Begin("Spawn Entity");
    for entity_type_names {
        if ImGui.Button(it.data) {
            entity := create_entity_by_type_name(it);
            entity.position = v2(100, 100);
            editor_unsaved_changes = true;
        }
    }
    ImGui.End();
    
    if selected_entities.count > 0 {
        ImGui.Begin("Properties");
        do_entity_imgui(selected_entities[0]);
        ImGui.End();
    }
    
    if texture_picker_target {
        texture := do_texture_picker_imgui();
        if texture {
            <<texture_picker_target = texture;
            editor_unsaved_changes = true;
            texture_picker_target = null;
        }
    }
    
    ImGui.Begin("Level");
    ImGui.Text(tprint("Current level: %", current_level_name));
    buffer: [32] u8;
    memcpy(buffer.data, level_name.data, level_name.count);
    if ImGui.InputText("Name", buffer.data, 32) {
        level_name = copy_string(cast(string) buffer); // @leak
        level_name.count = c_style_strlen(buffer.data);
    }
    
    if ImGui.Button("Save") editor_save_level();
    if ImGui.Button("Load") {
        if editor_unsaved_changes {
            ImGui.OpenPopup("Unsaved changes");
        } else editor_load_level();
    }
    if ImGui.Button("Clear level") {
        remove_all_entities();
        selected_entities.count = 0;
    }
    
    if editor_unsaved_changes ImGui.Text("Unsaved changes!");
    
    if ImGui.BeginPopupModal("Unsaved changes") {
        ImGui.Text("Unsaved changes! Save before continuing?");
        if ImGui.Button("Yes") {
            save_level(current_level_name);
            editor_unsaved_changes = false;
            
            editor_load_level();
            ImGui.CloseCurrentPopup();
        }
        if ImGui.Button("No") {
            editor_load_level();
            ImGui.CloseCurrentPopup();
        }
        ImGui.EndPopup();
    }
    ImGui.End();
    
    ImGui.Begin("Entities");
    if ImGui.BeginTabBar("") {
        if ImGui.BeginTabItem("Search") {
            if ImGui.InputText("Class", search_text.data, 64) {
                class_string := cast(string) search_text;
                class_string.count = c_style_strlen(search_text.data);
                entities := search_by_class(class_string);
                array_copy(*search_entities, entities);
            }

            for search_entities {
                if ImGui.Button(tprint("% (%)", it.id, entity_type_names[it.class]).data) {
                    selected_entities.count = 0;
                    array_add(*selected_entities, it);
                }
            }
            
            ImGui.EndTabItem();
        }
        if ImGui.BeginTabItem("All Entities") {
            for entity_list.active_entities {
                if ImGui.Button(tprint("% (%)", it.id, entity_type_names[it.class]).data) {
                    selected_entities.count = 0;
                    array_add(*selected_entities, it);
                }
            }
            
            ImGui.EndTabItem();
        }
        
        ImGui.EndTabBar();
    }
    ImGui.End();
}

editor_update :: () {
    x, y: s32;
    SDL_GetMouseState(*x, *y);
    mouse_position = v2(xx x, xx (render_size.y-y)) + camera_position;
    mouse_position -= render_half_size;
    
    if selected_entities.count > 0 {
        entity := selected_entities[0];
        x_axis.position = entity.position + .{ xx x_axis.texture.width*.5, 0 };
        y_axis.position = entity.position + .{ 0, xx y_axis.texture.height*.5 };
    }
}

editor_handle_keyboard_event :: (event: *SDL_Event) {
    if event.type == SDL_KEYUP {
        if event.key.keysym.scancode == SDL_SCANCODE_DELETE {
            for selected_entities remove_entity(it);
            selected_entities.count = 0;
            editor_unsaved_changes = true;
        } else if event.key.keysym.scancode == SDL_SCANCODE_F11 {
            editor_save_level();
            start_game();
        } else if event.key.keysym.scancode == SDL_SCANCODE_F {
            if selected_entities.count == 1 {
                set_camera_position(selected_entities[0].position);
            }
        }
    }
}

editor_handle_mouse_event :: (event: *SDL_Event) {
    if event.type == SDL_MOUSEMOTION {
        if moving_entities {
            motion := Vec2.{ xx event.motion.xrel, xx -event.motion.yrel };
            if x_axis.hovered motion.y = 0;
            if y_axis.hovered motion.x = 0;
            
            editor_unsaved_changes = selected_entities.count > 0;
            for selected_entities it.position += motion;
        }
        
        if moving_camera {
            motion := Vec2.{ xx event.motion.xrel, xx -event.motion.yrel };
            set_camera_position(camera_position - motion);
        }
    }
    
    if event.type == SDL_MOUSEBUTTONDOWN {
        if event.button.button == SDL_BUTTON_LEFT {
            if selected_entities.count > 0 {
                entity := selected_entities[0];
                x_axis.position = entity.position + .{ xx x_axis.texture.width*.5, 0 };
                y_axis.position = entity.position + .{ 0, xx y_axis.texture.height*.5 };
                x_axis.hovered = point_inside_rect(mouse_position, x_axis.position, x_axis.size);
                y_axis.hovered = point_inside_rect(mouse_position, y_axis.position, y_axis.size); 
            }
            
            entity := find_entity_under_point(mouse_position);
            if entity && array_find(selected_entities, entity) moving_entities = true;
            else if x_axis.hovered || y_axis.hovered moving_entities = true;
            else dragging = true;
            
            drag_origin = mouse_position;
        } else if event.button.button == SDL_BUTTON_RIGHT {
            moving_camera = true;
        }
    }
    
    if event.type == SDL_MOUSEBUTTONUP {
        if event.button.button == SDL_BUTTON_LEFT {
            if dragging || !moving_entities {
                drag_size := abs(mouse_position - drag_origin);
                drag_pos := lerp(mouse_position, drag_origin, 0.5);
                entities := entities_inside_rect(drag_pos, drag_size);
                if drag_size <= .{1, 1} && entities.count {
                    selected_entities.count = 0;
                    array_add(*selected_entities, entities[0]);
                } else {
                    array_copy(*selected_entities, entities);
                }
            }
            
            x_axis.hovered = false;
            y_axis.hovered = false;
            moving_entities = false;
            dragging = false;
        } else if event.button.button == SDL_BUTTON_RIGHT {
            moving_camera = false;
        }
    }
}

texture_picker_sizes := Vec2.[
    .{ 32, 32 }, .{ 64, 64 }, .{ 128, 128 }, .{ 256, 256 }
];

texture_picker_size_index := 0;

texture_imgui :: (name: string, texture: **Texture) {
    path := ifx <<texture then (<<texture).path else "none";
    if ImGui.Button(tprint("% (%) (Click to set texture)", name, path).data) texture_picker_target = texture;
    
    if !<<texture return;
    if ImGui.IsItemHovered() {
        ImGui.BeginTooltip();
        
        draw_list := ImGui.GetWindowDrawList();
        draw_list.AddImage(draw_list, cast (ImGui.ImTextureID) (<<texture).object, 
            ImGui.GetMousePos(), ImGui.GetMousePos() + .{128, 128});
        
        ImGui.EndTooltip();
    }
}

do_texture_picker_imgui :: () -> *Texture {
    ImGui.Begin("Texture Picker");
    defer ImGui.End();
    
    size := texture_picker_sizes[texture_picker_size_index];
    
    if ImGui.Button("+") texture_picker_size_index += 1;
    ImGui.SameLine();
    if ImGui.Button("-") texture_picker_size_index -= 1;
    
    if texture_picker_size_index >= texture_picker_sizes.count texture_picker_size_index = 0;
    if texture_picker_size_index < 0 texture_picker_size_index = texture_picker_sizes.count - 1;
    
    for _all_textures {
        if it_index % 8 != 0 ImGui.SameLine();
        imgui_size: ImGui.ImVec2 = .{ xx size.x, xx size.y };

        if ImGui.ImageButton(it.path.data, cast(*void)it.object, imgui_size) return it;
        if ImGui.IsItemHovered() ImGui.SetTooltip(it.path);
    }
    
    return null;
}

do_custom_imgui :: (name: string, value: *int) -> bool { return ImGui.DragScalar(name.data, .S64, value); }
do_custom_imgui :: (name: string, value: *float) -> bool { return ImGui.DragFloat(name.data, value); }
do_custom_imgui :: (name: string, value: *bool) -> bool { return ImGui.Checkbox(name.data, value); }
do_custom_imgui :: (name: string, value: *Vec2) -> bool { return ImGui.DragFloat2(name.data, *value.component); }
do_custom_imgui :: (name: string, value: *Vec4) -> bool { return ImGui.DragFloat4(name.data, *value.component); }

do_custom_imgui :: (name: string, value: *string) -> bool {
    buffer: [1024] u8;
    memcpy(buffer.data, value.data, value.count);
    changes := ImGui.InputText(name.data, buffer.data, 1024);
    if changes {
        <<value = copy_string(cast(string) buffer);
        value.count = c_style_strlen(buffer.data);
    }
    return changes;
}

do_custom_imgui :: (name: string, value: *Colour) -> bool {
    colour_v4 := cast(Vec4) <<value;
    changes := ImGui.ColorEdit4(name.data, *colour_v4.component); 
    <<value = cast(Colour) colour_v4;
    return changes;
}

do_custom_imgui :: (name: string, value: **Texture) -> bool { texture_imgui(name, value); return false; }

do_custom_imgui :: (name: string, array: *[..] $T) -> bool {
    changes := false;
    
    if ImGui.CollapsingHeader(tprint("% (Array)", name, name).data) {
        ImGui.Indent();
        
        if ImGui.Button(tprint("Add item##%", name).data) {
            value: T;
            array_add(array, value);
        }
        
        for * <<array {
            changes |= do_custom_imgui(tprint("%[%]", name, it_index), it);
        }
        
        ImGui.Unindent();
    }
    
    return changes;
}

do_custom_imgui :: (name: string, value: *$T) -> bool #modify {
    s := cast(*Type_Info) T;
    if s.type != .ENUM return false;
    e := cast(*Type_Info_Enum) s;
    return e.enum_type_flags & .FLAGS == 0;
}
{
    names := enum_names(T);
    dest := cast(s32) <<value;
    
    items := tarray(*u8);
    for names array_add(*items, it.data);
    
    if ImGui.Combo(name.data, *dest, items.data, xx items.count) {
        <<value = cast(T) dest;
        return true;
    }
    
    return false;
}

do_custom_imgui :: (name: string, value: *$T) -> bool #modify {
    s := cast(*Type_Info) T;
    if s.type != .ENUM return false;
    e := cast(*Type_Info_Enum) s;
    return e.enum_type_flags & .FLAGS != 0;
}
{
    names := enum_names(T);
    dest := cast(s32) <<value;
    
    items := tarray(*u8);
    for names array_add(*items, it.data);

    changes := false;

    if ImGui.CollapsingHeader(name.data) {
        ImGui.Indent();
        
        f_value := 0;
        for names {
            b_value := (<<value & cast(T) (1 << it_index)) != 0;
            changes |= ImGui.Checkbox(names[it_index].data, *b_value);
            if b_value f_value |= (1 << it_index);
        }
        <<value = cast(T) f_value;
        
        ImGui.Unindent();
    }    
    
    return changes;
}

do_custom_imgui_helper :: (info: *Type_Info, member_prefix := "value.") -> string {
    builder: String_Builder;
    
    s := cast(*Type_Info_Struct) info;
    for s.members {
        if find_note(it.notes, "no_imgui") continue;
        
        // :HACK for entities
        if equal(it.name, "VERSION") continue;
        
        if it.type.type == .STRUCT && not_easy_struct(it.type) {
            prefix := tprint("%0%.", member_prefix, it.name);
            append(*builder, tprint("if ImGui.CollapsingHeader(\"%\") {", it.name));
            append(*builder, "ImGui.Indent();\n");
            append(*builder, do_custom_imgui_helper(it.type, prefix));
            append(*builder, "ImGui.Unindent();\n");
            append(*builder, "}");
        } else {
            append(*builder, tprint("changes |= do_custom_imgui(\"%\", *%0%);\n", it.name, member_prefix, it.name));
        }
    }
    
    out := builder_to_string(*builder);
    return out;
}

do_custom_imgui :: (name: string, value: *$T) -> bool #modify {
    s := cast(*Type_Info) T;
    return s.type == .STRUCT;
}
{
    changes := false;
    
    ImGui.PushID(name.data);
    
    info := cast(*Type_Info_Struct) T;
    if ImGui.CollapsingHeader(name.data) {
        ImGui.Indent();
        #insert #run do_custom_imgui_helper(type_info(T));
        ImGui.Unindent();
    }
    
    ImGui.PopID();
    
    return changes;
}

#scope_file

mouse_position: Vec2;

dragging: bool;
drag_origin: Vec2;
selected_entities: [..] *Entity;

moving_camera: bool;

moving_entities: bool;

texture_picker_target: **Texture;

level_name: string;

search_text: [64] u8;
search_entities: [..] *Entity;

search_by_class :: (class: string) -> [..] *Entity {
    out := tarray(*Entity);
    for entity_list.active_entities {
        if contains_nocase(entity_type_names[it.class], class) array_add(*out, it);
    }
    return out;
}

Axis :: struct {
    texture: Texture;
    position: Vec2;
    size: Vec2;
    hovered: bool;
}

x_axis, y_axis: Axis;

find_entity_under_point :: (point: Vec2) -> *Entity {
    sorted_entities := tarray(entity_list.active_entities);
    quick_sort(sorted_entities, (a, b) => a.depth - b.depth);
    
    for sorted_entities {
        if point_inside_rect(point, it.position, get_entity_size(it)) return it;
    }
    return null;
}

point_inside_rect :: (point: Vec2, pos: Vec2, size: Vec2) -> bool {
    if point.x < pos.x - size.x*0.5 return false;
    if point.x > pos.x + size.x*0.5 return false;
    if point.y < pos.y - size.y*0.5 return false;
    if point.y > pos.y + size.y*0.5 return false;
    return true;
}

rect_inside_rect :: (a_pos: Vec2, a_size: Vec2, b_pos: Vec2, b_size: Vec2) -> bool {
    if a_pos.x+a_size.x*.5 < b_pos.x-b_size.x*.5 return false;
    if a_pos.x-a_size.x*.5 > b_pos.x+b_size.x*.5 return false;
    if a_pos.y+a_size.y*.5 < b_pos.y-b_size.y*.5 return false;
    if a_pos.y-a_size.y*.5 > b_pos.y+b_size.y*.5 return false;
    return true;
}

entities_inside_rect :: (pos: Vec2, size: Vec2) -> [] *Entity {
    array := tarray(*Entity);
    for entity_list.active_entities {
        if rect_inside_rect(it.position, get_entity_size(it), pos, size) array_add(*array, it);
    }
    return array;
}

#import "Math";