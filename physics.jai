
update_entity_physics :: () {
    for entity_list.active_entities {
        if !(it.flags & .Physics) continue;
        
        it.velocity = approach(it.velocity, it.goal_velocity, delta_time * it.approach_speed);
        it.position += it.velocity * delta_time;
    }
}