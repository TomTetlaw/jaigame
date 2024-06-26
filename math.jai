
Vec2i :: struct {
    x, y: int;
}

operator + :: (a: Vec2i, b: Vec2i) -> Vec2i {
    return .{a.x+b.x, a.y+b.y};
}

operator == :: (a: Vec2i, b: Vec2i) -> bool {
    return a.x==b.x && a.y==b.y;
}

Vec2 :: struct {
    x: float;
    y: float;
    
#place x;
    component: [2] float = ---; @no_imgui @no_serialize
}

Vec3 :: struct {
    x: float;
    y: float;
    z: float;
    
#place x;
    component: [3] float = ---; @no_imgui @no_serialize
}

Vec4 :: struct {
    x: float;
    y: float;
    z: float;
    w: float;
    
#place x;
    component: [4] float = ---; @no_imgui @no_serialize
}

Colour :: #type,isa Vec4;
Mat4 :: #type,isa Matrix4;

v2 :: (x: float, y: float) -> Vec2 { return .{ x, y }; }
v2f :: (v: float) -> Vec2 { return .{ v, v }; }

v3 :: (x: float, y: float, z: float) -> Vec3 { return .{ x, y, z }; }
v3f :: (v: float) -> Vec3 { return .{ v, v, v }; }

v4 :: (x: float, y: float, z: float, w: float) -> Vec4 { return .{ x, y, z, w }; }
v4f :: (v: float) -> Vec4 { return .{ v, v, v, v }; }

truncate :: (value: float) -> int {
    return cast(int) (value - frac(value));
}

almost_equals :: (a: float, b: float, tolerance := 0.00001) -> bool {
    if abs(b-a) > tolerance return false;
    return true;
}

almost_equals :: (a: Vec2, b: Vec2, tolerance := 0.00001) -> bool {
    if abs(b.x-a.x) > tolerance return false;
    if abs(b.y-a.y) > tolerance return false;
    return true;
}

clamp01 :: (a: $T) -> T {
    if a < 0 return 0;
    if a > 1 return 1;
    return a;
}

abs :: (v: Vec2) -> Vec2 {
    return .{ abs(v.x), abs(v.y) };
}

lerp :: (a: Vec2, b: Vec2, t: float) -> Vec2 {
    return .{ lerp(a.x, b.x, t), lerp(a.y, b.y, t) };
}

lerp :: (a: Vec4, b: Vec4, t: float) -> Vec4 {
    return .{ lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t), lerp(a.w, b.w, t) };
}

approach :: (current: float, goal: float, dt: float) -> float {
    delta := goal - current;
    if delta < -dt return current - dt;
    if delta > dt return current + dt;
    return goal;
}

approach :: (current: Vec2, goal: Vec2, dt: float) -> Vec2 {
    out: Vec2;
    out.x = approach(current.x, goal.x, dt);
    out.y = approach(current.y, goal.y, dt);
    return out;
}

length :: (v: Vec2) -> float {
    return sqrt(v.x*v.x + v.y*v.y);
}

distance :: (a: Vec2, b: Vec2) -> float {
    return length(a-b);
}

operator == :: (a: Vec2, b: Vec2) -> bool {
    return almost_equals(a, b);
}

operator + :: (a: Vec2, b: Vec2) -> Vec2 { return .{ a.x+b.x, a.y+b.y }; } 
operator - :: (a: Vec2, b: Vec2) -> Vec2 { return .{ a.x-b.x, a.y-b.y }; } 
operator * :: (a: Vec2, b: Vec2) -> Vec2 { return .{ a.x*b.x, a.y*b.y }; } 
operator * :: (a: Vec2, b: float) -> Vec2 { return .{ a.x*b, a.y*b }; } 

operator <= :: (a: Vec2, b: Vec2) -> bool {
    if a.x <= b.x || a.y <= b.y return true;
    return false;
} 

operator >= :: (a: Vec2, b: Vec2) -> bool {
    if a.x >= b.x || a.y >= b.y return true;
    return false;
} 

operator < :: (a: Vec2, b: Vec2) -> bool {
    if a.x < b.x || a.y < b.y return true;
    return false;
} 

operator > :: (a: Vec2, b: Vec2) -> bool {
    if a.x > b.x || a.y > b.y return true;
    return false;
} 

#scope_file

#import "Basic";
#import "Math";