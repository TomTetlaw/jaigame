
update_entity_physics :: () {
    entity_list := *context.entity_list;
    for entity_list.active_entities {
        if !(it.flags & .Physics) continue;
        
        it.velocity = approach(it.velocity, it.goal_velocity, delta_time * it.approach_speed);
        it.position += it.velocity * delta_time;
    }
}