
Vec2 :: struct {
    x: float;
    y: float;
    
    #place x;
    component: [2] float = ---; @no_imgui
}

Vec3 :: struct {
    x: float;
    y: float;
    z: float;
    
    #place x;
    component: [3] float = ---; @no_imgui
}

Vec4 :: struct {
    x: float;
    y: float;
    z: float;
    w: float;
    
    #place x;
    component: [4] float = ---; @no_imgui
}

Colour :: #type,isa Vec4;

v2 :: (x: float, y: float) -> Vec2 { return .{ x, y }; }
v2f :: (v: float) -> Vec2 { return .{ v, v }; }

v3 :: (x: float, y: float, z: float) -> Vec3 { return .{ x, y, z }; }
v3f :: (v: float) -> Vec3 { return .{ v, v, v }; }

v4 :: (x: float, y: float, z: float, w: float) -> Vec4 { return .{ x, y, z, w }; }
v4f :: (v: float) -> Vec4 { return .{ v, v, v, v }; }

almost_equals :: (a: float, b: float, tolerance := 0.00001) -> bool {
    if abs(b-a) > tolerance return false;
    return true;
}

almost_equals :: (a: Vec2, b: Vec2, tolerance := 0.00001) -> bool {
    if abs(b.x-a.x) > tolerance return false;
    if abs(b.y-a.y) > tolerance return false;
    return true;
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