const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const Vec2 = raylib.Vector2; 
const Node = @import("./astar.zig").Node; 

pub const iVec2 = struct {
    x: i32,
    y: i32, 
}; 

pub fn containsVec(haystack: []const Node, needle: Node) bool {
    const convertedNeedleA = @as(i32, @intFromFloat(needle.tile.tile_data.pos.x)); 
    const convertedNeedleB = @as(i32, @intFromFloat(needle.tile.tile_data.pos.y)); 

    for (haystack) |hay| {
        const convertedHaystackA = @as(i32, @intFromFloat(hay.tile.tile_data.pos.x)); 
        const convertedHaystackB = @as(i32, @intFromFloat(hay.tile.tile_data.pos.y)); 
        if (convertedNeedleA == convertedHaystackA and convertedNeedleB == convertedHaystackB) {
            return true;
        }
    }
    return false;
}

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
