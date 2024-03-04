
log :: (format: string, args: ..Any) {
    builder: String_Builder;
    print_to_builder(*builder, format, ..args);
    out := builder_to_string(*builder);
    print("%\n", out);
} @PrintLike

copy_string_n :: (dest: *string, source: string, n: int) {
    assert(dest.count > n);
    for 0..n-1 {
        (<<dest)[it] = source[it];
    }
}

zero :: (Value: *$T) {
    memset(Value, 0, size_of(T));
}

bucket_array_get :: (using array: *Bucket_Array, locator: Bucket_Locator) -> *array.type {
    bucket_index := locator.bucket_index;
    slot_index := locator.slot_index;
    bucket := all_buckets[bucket_index];
    assert(bucket.occupied[slot_index] == true);
    return *bucket.data[slot_index];
}

advance :: (array: * [..] $T, count := 1) {
    array.data += count;
    array.count -= count;
}

tarray :: ($T: Type) -> [..] T {
    array: [..] T;
    array.allocator = temp;
    return array;
}

tarray :: (array: [..] $T) -> [] T {
    out: [] T;
    
    size := size_of(T) * array.count;
    
    out.count = array.count;
    out.data = alloc(size);
    memcpy(out.data, array.data, size);
    
    return out;
}

random_get_in_range :: (min: int, max: int) -> int {
    return min + cast (int) (random_get_zero_to_one() * (max - min));
}

random_choice :: (array: [] $T) -> T {
    assert(array.count != 0);
    return array[random_get_in_range(0, array.count-1)];
}

random_get_bool :: () -> bool { return random_get_zero_to_one() > 0.5; }

fatal_error :: (format: string, args: ..Any) {
    builder: String_Builder;
    init_string_builder(*builder);
    print_to_builder(*builder, format, ..args);
    message := builder_to_string(*builder);
    SDL_ShowSimpleMessageBox(0x00000010, "Fatal error!", message.data, null);
    exit(0);
}

parse_vec2 :: (s: string) -> Vec2 {
    x, y: float;
    scan2(s, "%,%", *x, *y);
    return .{x, y};
}

parse_vec4 :: (s: string) -> Vec4 {
    x, y, z, w: float;
    scan2(s, "%,%,%,%", *x, *y, *z, *w);
    return .{x, y, z, w};
}

parse_colour :: (s: string) -> Colour {
    x, y, z, w: float;
    scan2(s, "%,%,%,%", *x, *y, *z, *w);
    return .{x, y, z, w};
}

find_note :: (notes: [] string, note: string) -> bool {
    for notes if equal(it, note) return true;
    return false;
}

not_easy_struct :: (info: *Type_Info) -> bool {
    if info.type != .STRUCT return false;
    s_type_info := cast(*Type_Info_Struct) info;
    if s_type_info.name == "Vec2" return false;
    if s_type_info.name == "Vec4" return false;
    return true;
}

#import "Basic";
#import "String";
#import "Random";