
update_entity_physics :: () {
    ImGui.Begin("Physics State");
    
    for a: entity_list.active_entities {
        if !(a.flags & .Physics) continue;
        
        new_velocity := approach(a.velocity, a.goal_velocity, delta_time * a.approach_speed);
        new_position := a.position + new_velocity * delta_time;
        
        if !(a.flags & .Blocking) {
            a.velocity = new_velocity;
            a.position = new_position;
            ImGui.Text(tprint("%:% (Lacks .Blocking)", a.id, entity_type_names[a.class]));
        } else {
            hit_entity: *Entity;
            for b: entity_list.active_entities {
                if a.id == b.id continue;
                if !(b.flags & .Blocking) continue;
                
                if entity_aabb_check(new_position, a, b) {
                    a.velocity = .{0, 0};
                    hit_entity = b;
                    break;
                }
            }
            
            if !hit_entity {
                a.velocity = new_velocity;
                a.position = new_position;
                ImGui.Text(tprint("%:% (Hit nothing)", a.id, entity_type_names[a.class]));
            }
            else {
                ImGui.Text(tprint("%:% (Hit %:%)", a.id, entity_type_names[a.class], hit_entity.id, entity_type_names[hit_entity.class]));
            }
        }
    }
    
    ImGui.End();
}

entity_aabb_check :: (new_pos: Vec2, a: *Entity, b: *Entity) -> bool {
    a_pos := new_pos;
    a_size := get_entity_size(a);
    b_pos := b.position;
    b_size := get_entity_size(b);
    
    if a_pos.x+a_size.x*.5 < b_pos.x-b_size.x*.5 return false;
    if a_pos.x-a_size.x*.5 > b_pos.x+b_size.x*.5 return false;
    if a_pos.y+a_size.y*.5 < b_pos.y-b_size.y*.5 return false;
    if a_pos.y-a_size.y*.5 > b_pos.y+b_size.y*.5 return false;
    
    return true;
}