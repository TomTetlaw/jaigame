
log :: (format: string, args: ..Any) {
    builder: String_Builder;
    print_to_builder(*builder, format, ..args);
    out := builder_to_string(*builder);
    print("%\n", out);
} @PrintLike

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

key_to_string :: inline (code: SDL_Keycode) -> string {
    return enum_names(SDL_Keycode)[code];
}

#import "Basic";
#import "String";
#import "Random";