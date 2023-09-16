const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 

pub const FoliageType = enum {
    TREE,
    ROCK,
    BUSH,
}; 

pub const Foliage = struct {
    position: Vec2,
    ftype: FoliageType,
    
    pub fn createFoliage(pos: Vec2, ftype: FoliageType) Foliage {
        var f = Foliage{
            .position = pos,
            .ftype = ftype
        }; 

        return f; 
    }

};

pub fn generateFoliageData(x: usize, y: usize) void {
    const random_num = r.random().intRangeLessThan(u8, 0, 100); 
    if (@mod(random_num, 4) == 0) {
        std.debug.print("foliage should be placed at {}, {}\n", .{x, y}); 
    } else {
        std.debug.print("no foliage placed\n", .{}); 
    }
}


