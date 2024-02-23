// Workspace: Final workspace

DEBUG_BUILD :: 1;

RELEASE_BUILD :: 0;

_texture_box: *Texture;
_texture_door_down: *Texture;
_texture_door_left: *Texture;
_texture_door_right: *Texture;
_texture_door_up: *Texture;
_texture_floor: *Texture;
_texture_hall: *Texture;
_texture_layer0: *Texture;
_texture_layer1: *Texture;
_texture_layer2: *Texture;
_texture_layer3: *Texture;
_texture_layer4: *Texture;
_texture_player: *Texture;
_texture_room: *Texture;
_texture_skeleton: *Texture;
_texture_terrain_dirt: *Texture;
_texture_terrain_grass: *Texture;
_texture_terrain_stone: *Texture;
_texture_terrain_water: *Texture;
_texture_x_axis: *Texture;
_texture_y_axis: *Texture;
_all_textures: [..] *Texture;
load_all_textures :: () {
_texture_box = load_texture("textures/box.png");
array_add(*_all_textures, _texture_box);
_texture_door_down = load_texture("textures/door_down.png");
array_add(*_all_textures, _texture_door_down);
_texture_door_left = load_texture("textures/door_left.png");
array_add(*_all_textures, _texture_door_left);
_texture_door_right = load_texture("textures/door_right.png");
array_add(*_all_textures, _texture_door_right);
_texture_door_up = load_texture("textures/door_up.png");
array_add(*_all_textures, _texture_door_up);
_texture_floor = load_texture("textures/floor.png");
array_add(*_all_textures, _texture_floor);
_texture_hall = load_texture("textures/hall.png");
array_add(*_all_textures, _texture_hall);
_texture_layer0 = load_texture("textures/layer0.png");
array_add(*_all_textures, _texture_layer0);
_texture_layer1 = load_texture("textures/layer1.png");
array_add(*_all_textures, _texture_layer1);
_texture_layer2 = load_texture("textures/layer2.png");
array_add(*_all_textures, _texture_layer2);
_texture_layer3 = load_texture("textures/layer3.png");
array_add(*_all_textures, _texture_layer3);
_texture_layer4 = load_texture("textures/layer4.png");
array_add(*_all_textures, _texture_layer4);
_texture_player = load_texture("textures/player.png");
array_add(*_all_textures, _texture_player);
_texture_room = load_texture("textures/room.png");
array_add(*_all_textures, _texture_room);
_texture_skeleton = load_texture("textures/skeleton.png");
array_add(*_all_textures, _texture_skeleton);
_texture_terrain_dirt = load_texture("textures/terrain_dirt.png");
array_add(*_all_textures, _texture_terrain_dirt);
_texture_terrain_grass = load_texture("textures/terrain_grass.png");
array_add(*_all_textures, _texture_terrain_grass);
_texture_terrain_stone = load_texture("textures/terrain_stone.png");
array_add(*_all_textures, _texture_terrain_stone);
_texture_terrain_water = load_texture("textures/terrain_water.png");
array_add(*_all_textures, _texture_terrain_water);
_texture_x_axis = load_texture("textures/x_axis.png");
array_add(*_all_textures, _texture_x_axis);
_texture_y_axis = load_texture("textures/y_axis.png");
array_add(*_all_textures, _texture_y_axis);
}
texture_for_path :: (path: string) -> *Texture {
if equal(path, "textures/box.png") return _texture_box;
if equal(path, "textures/door_down.png") return _texture_door_down;
if equal(path, "textures/door_left.png") return _texture_door_left;
if equal(path, "textures/door_right.png") return _texture_door_right;
if equal(path, "textures/door_up.png") return _texture_door_up;
if equal(path, "textures/floor.png") return _texture_floor;
if equal(path, "textures/hall.png") return _texture_hall;
if equal(path, "textures/layer0.png") return _texture_layer0;
if equal(path, "textures/layer1.png") return _texture_layer1;
if equal(path, "textures/layer2.png") return _texture_layer2;
if equal(path, "textures/layer3.png") return _texture_layer3;
if equal(path, "textures/layer4.png") return _texture_layer4;
if equal(path, "textures/player.png") return _texture_player;
if equal(path, "textures/room.png") return _texture_room;
if equal(path, "textures/skeleton.png") return _texture_skeleton;
if equal(path, "textures/terrain_dirt.png") return _texture_terrain_dirt;
if equal(path, "textures/terrain_grass.png") return _texture_terrain_grass;
if equal(path, "textures/terrain_stone.png") return _texture_terrain_stone;
if equal(path, "textures/terrain_water.png") return _texture_terrain_water;
if equal(path, "textures/x_axis.png") return _texture_x_axis;
if equal(path, "textures/y_axis.png") return _texture_y_axis;
assert(false); return null;
}


#import "Bucket_Array";
#import "File";
_Player: Entity_Class = 0;
_Prop: Entity_Class = 1;
_Blocker: Entity_Class = 2;
_Enemy: Entity_Class = 3;
_Parallax_Background: Entity_Class = 4;
entity_type_names := string.["Player", "Prop", "Blocker", "Enemy", "Parallax_Background", ];

create_entity_by_type_name :: (name: string) -> *Entity {
    if equal(name, "Player") return create_entity(Player);
    if equal(name, "Prop") return create_entity(Prop);
    if equal(name, "Blocker") return create_entity(Blocker);
    if equal(name, "Enemy") return create_entity(Enemy);
    if equal(name, "Parallax_Background") return create_entity(Parallax_Background);
    assert(false);
    return null;
}

create_entity_from_save :: (class: Entity_Class, id: int) -> *Entity {
e: *Entity;
if class == _Player e = create_entity(Player, id);
if class == _Prop e = create_entity(Prop, id);
if class == _Blocker e = create_entity(Blocker, id);
if class == _Enemy e = create_entity(Enemy, id);
if class == _Parallax_Background e = create_entity(Parallax_Background, id);
if !e { assert(false); return null; }
return e;
}

entity_class_for_type :: ($T: Type) -> Entity_Class {
    #if T == Player return _Player;
    #if T == Prop return _Prop;
    #if T == Blocker return _Blocker;
    #if T == Enemy return _Enemy;
    #if T == Parallax_Background return _Parallax_Background;
    assert(false);
    return -1;
}

DERIVED_ENTITY_LISTS :: #string HERE
_Player: Bucket_Array(Player, ENTITY_BUCKET_SIZE);
_Prop: Bucket_Array(Prop, ENTITY_BUCKET_SIZE);
_Blocker: Bucket_Array(Blocker, ENTITY_BUCKET_SIZE);
_Enemy: Bucket_Array(Enemy, ENTITY_BUCKET_SIZE);
_Parallax_Background: Bucket_Array(Parallax_Background, ENTITY_BUCKET_SIZE);
HERE

array_for_entity :: ($T: Type) -> *Bucket_Array(T, ENTITY_BUCKET_SIZE) {
    entity_list := *context.entity_list;
    #if T == Player return *entity_list._Player;
    #if T == Prop return *entity_list._Prop;
    #if T == Blocker return *entity_list._Blocker;
    #if T == Enemy return *entity_list._Enemy;
    #if T == Parallax_Background return *entity_list._Parallax_Background;
    assert(false);
    return null;
}
remove_entity :: (entity: *Entity) {
    entity_list := *context.entity_list;
    array_unordered_remove_by_value(*entity_list.active_entities, entity);
    if entity.class == _Player bucket_array_remove(*entity_list._Player, entity.locator);
    if entity.class == _Prop bucket_array_remove(*entity_list._Prop, entity.locator);
    if entity.class == _Blocker bucket_array_remove(*entity_list._Blocker, entity.locator);
    if entity.class == _Enemy bucket_array_remove(*entity_list._Enemy, entity.locator);
    if entity.class == _Parallax_Background bucket_array_remove(*entity_list._Parallax_Background, entity.locator);
}
remove_all_entities :: () {
    entity_list := *context.entity_list;
entity_list.active_entities.count = 0;
for entity_list._Player remove it;
for entity_list._Prop remove it;
for entity_list._Blocker remove it;
for entity_list._Enemy remove it;
for entity_list._Parallax_Background remove it;
}
delete_entity :: (entity: *Entity) {
    entity_list := *context.entity_list;
    if entity.class == _Player bucket_array_remove(*entity_list._Player, entity.locator);
    if entity.class == _Prop bucket_array_remove(*entity_list._Prop, entity.locator);
    if entity.class == _Blocker bucket_array_remove(*entity_list._Blocker, entity.locator);
    if entity.class == _Enemy bucket_array_remove(*entity_list._Enemy, entity.locator);
    if entity.class == _Parallax_Background bucket_array_remove(*entity_list._Parallax_Background, entity.locator);
}

get_entity_from_locator :: (ref: Entity_Ref) -> *Entity {
    entity_list := *context.entity_list;
    if ref.class == _Player return bucket_array_get(*entity_list._Player, ref.locator);
    if ref.class == _Prop return bucket_array_get(*entity_list._Prop, ref.locator);
    if ref.class == _Blocker return bucket_array_get(*entity_list._Blocker, ref.locator);
    if ref.class == _Enemy return bucket_array_get(*entity_list._Enemy, ref.locator);
    if ref.class == _Parallax_Background return bucket_array_get(*entity_list._Parallax_Background, ref.locator);
    assert(false);
    return null;
}

save_entity :: (level_name: string, entity: *Entity) -> string {
builder: String_Builder;
if entity.class == _Player {
e := entity_cast(entity, Player);
append(*builder, tprint("%\n", Player.VERSION));
append(*builder, tprint("e.base.position = %,%\n", e.base.position.x, e.base.position.y));
append(*builder, tprint("e.base.size = %,%\n", e.base.size.x, e.base.size.y));
append(*builder, tprint("e.base.colour = %,%,%,%\n", e.base.colour.x, e.base.colour.y, e.base.colour.z, e.base.colour.w));
append(*builder, tprint("e.base.texture = %\n", e.base.texture.path));
}
if entity.class == _Prop {
e := entity_cast(entity, Prop);
append(*builder, tprint("%\n", Prop.VERSION));
append(*builder, tprint("e.base.position = %,%\n", e.base.position.x, e.base.position.y));
append(*builder, tprint("e.base.size = %,%\n", e.base.size.x, e.base.size.y));
append(*builder, tprint("e.base.colour = %,%,%,%\n", e.base.colour.x, e.base.colour.y, e.base.colour.z, e.base.colour.w));
append(*builder, tprint("e.base.texture = %\n", e.base.texture.path));
}
if entity.class == _Blocker {
e := entity_cast(entity, Blocker);
append(*builder, tprint("%\n", Blocker.VERSION));
append(*builder, tprint("e.base.position = %,%\n", e.base.position.x, e.base.position.y));
append(*builder, tprint("e.base.size = %,%\n", e.base.size.x, e.base.size.y));
append(*builder, tprint("e.base.colour = %,%,%,%\n", e.base.colour.x, e.base.colour.y, e.base.colour.z, e.base.colour.w));
append(*builder, tprint("e.base.texture = %\n", e.base.texture.path));
}
if entity.class == _Enemy {
e := entity_cast(entity, Enemy);
append(*builder, tprint("%\n", Enemy.VERSION));
append(*builder, tprint("e.base.position = %,%\n", e.base.position.x, e.base.position.y));
append(*builder, tprint("e.base.size = %,%\n", e.base.size.x, e.base.size.y));
append(*builder, tprint("e.base.colour = %,%,%,%\n", e.base.colour.x, e.base.colour.y, e.base.colour.z, e.base.colour.w));
append(*builder, tprint("e.base.texture = %\n", e.base.texture.path));
append(*builder, tprint("e.my_int1 = %\n", e.my_int1));
append(*builder, tprint("e.my_float1 = %\n", e.my_float1));
append(*builder, tprint("e.my_struct.my_int2 = %\n", e.my_struct.my_int2));
append(*builder, tprint("e.my_struct.my_float2 = %\n", e.my_struct.my_float2));
append(*builder, tprint("e.my_colour = %,%,%,%\n", e.my_colour.x, e.my_colour.y, e.my_colour.z, e.my_colour.w));
}
if entity.class == _Parallax_Background {
e := entity_cast(entity, Parallax_Background);
append(*builder, tprint("%\n", Parallax_Background.VERSION));
append(*builder, tprint("e.base.position = %,%\n", e.base.position.x, e.base.position.y));
append(*builder, tprint("e.base.size = %,%\n", e.base.size.x, e.base.size.y));
append(*builder, tprint("e.base.colour = %,%,%,%\n", e.base.colour.x, e.base.colour.y, e.base.colour.z, e.base.colour.w));
append(*builder, tprint("e.base.texture = %\n", e.base.texture.path));
}
return builder_to_string(*builder);
}

load_entity :: (entity: *Entity, version: int, members: *Table(string, string)) {
if entity.class == _Player {
e := entity_cast(entity, Player);
	{
		value := table_find_pointer(members, "e.base.position");
		if value e.base.position = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.size");
		if value e.base.size = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.colour");
		if value e.base.colour = parse_colour(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.texture");
		if value e.base.texture = texture_for_path(<<value);
	}
}
if entity.class == _Prop {
e := entity_cast(entity, Prop);
	{
		value := table_find_pointer(members, "e.base.position");
		if value e.base.position = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.size");
		if value e.base.size = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.colour");
		if value e.base.colour = parse_colour(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.texture");
		if value e.base.texture = texture_for_path(<<value);
	}
}
if entity.class == _Blocker {
e := entity_cast(entity, Blocker);
	{
		value := table_find_pointer(members, "e.base.position");
		if value e.base.position = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.size");
		if value e.base.size = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.colour");
		if value e.base.colour = parse_colour(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.texture");
		if value e.base.texture = texture_for_path(<<value);
	}
}
if entity.class == _Enemy {
e := entity_cast(entity, Enemy);
	{
		value := table_find_pointer(members, "e.base.position");
		if value e.base.position = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.size");
		if value e.base.size = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.colour");
		if value e.base.colour = parse_colour(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.texture");
		if value e.base.texture = texture_for_path(<<value);
	}
	{
		value := table_find_pointer(members, "e.my_int1");
		if value e.my_int1 = parse_int(value);
	}
	{
		value := table_find_pointer(members, "e.my_float1");
		if value e.my_float1 = parse_float(value);
	}
	{
		value := table_find_pointer(members, "e.my_struct.my_int2");
		if value e.my_struct.my_int2 = parse_int(value);
	}
	{
		value := table_find_pointer(members, "e.my_struct.my_float2");
		if value e.my_struct.my_float2 = parse_float(value);
	}
	{
		value := table_find_pointer(members, "e.my_colour");
		if value e.my_colour = parse_colour(<<value);
	}
}
if entity.class == _Parallax_Background {
e := entity_cast(entity, Parallax_Background);
	{
		value := table_find_pointer(members, "e.base.position");
		if value e.base.position = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.size");
		if value e.base.size = parse_vec2(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.colour");
		if value e.base.colour = parse_colour(<<value);
	}
	{
		value := table_find_pointer(members, "e.base.texture");
		if value e.base.texture = texture_for_path(<<value);
	}
}
}

do_entity_imgui :: (entity: *Entity) {
ImGui.PushID(tprint("%", entity.id));
if entity.class == _Player {
e := cast(*Player) entity;
do_custom_imgui(tprint("% (%)", e.id, entity_type_names[e.class]), e);
}
if entity.class == _Prop {
e := cast(*Prop) entity;
do_custom_imgui(tprint("% (%)", e.id, entity_type_names[e.class]), e);
}
if entity.class == _Blocker {
e := cast(*Blocker) entity;
do_custom_imgui(tprint("% (%)", e.id, entity_type_names[e.class]), e);
}
if entity.class == _Enemy {
e := cast(*Enemy) entity;
do_custom_imgui(tprint("% (%)", e.id, entity_type_names[e.class]), e);
}
if entity.class == _Parallax_Background {
e := cast(*Parallax_Background) entity;
do_custom_imgui(tprint("% (%)", e.id, entity_type_names[e.class]), e);
}
ImGui.PopID();
}

//
// #insert text. Generated from C:/stuff/code/final/entity.jai:5.
//
_Player: Bucket_Array(Player, ENTITY_BUCKET_SIZE);
_Prop: Bucket_Array(Prop, ENTITY_BUCKET_SIZE);
_Blocker: Bucket_Array(Blocker, ENTITY_BUCKET_SIZE);
_Enemy: Bucket_Array(Enemy, ENTITY_BUCKET_SIZE);
_Parallax_Background: Bucket_Array(Parallax_Background, ENTITY_BUCKET_SIZE);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("base", *value.base);
changes |= do_custom_imgui("my_int1", *value.my_int1);
changes |= do_custom_imgui("my_float1", *value.my_float1);
changes |= do_custom_imgui("my_struct", *value.my_struct);
changes |= do_custom_imgui("my_bool", *value.my_bool);
changes |= do_custom_imgui("my_colour", *value.my_colour);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("base", *value.base);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("base", *value.base);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("position", *value.position);
changes |= do_custom_imgui("size", *value.size);
changes |= do_custom_imgui("colour", *value.colour);
changes |= do_custom_imgui("texture", *value.texture);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("my_int2", *value.my_int2);
changes |= do_custom_imgui("my_float2", *value.my_float2);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("base", *value.base);
changes |= do_custom_imgui("ints", *value.ints);
changes |= do_custom_imgui("layers", *value.layers);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("base", *value.base);

//
// #insert text. Generated from C:/stuff/code/final/editor.jai:342.
//
changes |= do_custom_imgui("position", *value.position);
changes |= do_custom_imgui("texture", *value.texture);
changes |= do_custom_imgui("move_rate", *value.move_rate);
