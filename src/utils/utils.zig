const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const Vec2 = raylib.Vector2; 

pub const iVec2 = struct {
    x: i32,
    y: i32, 
}; 


pub fn cast(comptime T: type, ptr: *anyopaque) *T {
    return @as(*T, @alignCast(@ptrCast(ptr)));  
}

pub fn unwrap(comptime T: type, ptr: *anyopaque) T {
    return @as(T, @ptrCast(@alignCast(ptr))); 
}

pub fn Vec2ToiVec2(input: Vec2) iVec2 {
    return iVec2{
        .x = @intFromFloat(input.x),
        .y = @intFromFloat(input.y)
    }; 
}
