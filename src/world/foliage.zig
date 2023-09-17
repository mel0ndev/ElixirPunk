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

    pub fn drawFoliage(self: *const Foliage) void {
        var texture = foliage_set.get(self.ftype).?; 
        if (self.ftype == FoliageType.BUSH) {
            raylib.DrawTextureEx(
                texture,
                self.position,
                0, //rotation
                2.0,
                raylib.WHITE
            ); 
        } else if (self.ftype == FoliageType.TREE) {
            raylib.DrawTextureEx(
                texture,
                self.position,
                0, //rotation
                1.0,
                raylib.WHITE
            ); 
        } 
    }

};

pub var foliage_set: std.AutoHashMap(FoliageType, Texture2D) = undefined; 
pub var foliage_list: std.ArrayList(Foliage) = undefined; 

//init hashmap of foliage sprites to tilemap
pub fn createFoliageHashmap(alloc: std.mem.Allocator) !std.AutoHashMap(FoliageType, Texture2D) {
    foliage_set = std.AutoHashMap(FoliageType, Texture2D).init(alloc);  
    return foliage_set; 
} 

pub fn createFoliageList(alloc: std.mem.Allocator) void {
    foliage_list = std.ArrayList(Foliage).init(alloc); 
}

pub fn setFoliageMap() !void {
    const BUSH_TEXTURE: Texture2D = raylib.LoadTexture("src/world/assets/interactives/bush.png"); 
    const TREE_TEXTURE: Texture2D = raylib.LoadTexture("src/world/assets/interactives/tree.png"); 
    try foliage_set.putNoClobber(FoliageType.BUSH, BUSH_TEXTURE); 
    try foliage_set.putNoClobber(FoliageType.TREE, TREE_TEXTURE); 
}

pub fn generateFoliageData(x: usize, y: usize) !void {
    const random_num = r.random().intRangeLessThan(u8, 0, 100); 
    if (@mod(random_num, 2) == 0) {
        //tree or bush
        if (@mod(random_num, 4) == 0) {
            //bush only
            const foliage = Foliage.createFoliage(
                Vec2{.x = @floatFromInt(x * 32), .y = @floatFromInt(y * 32)},
                FoliageType.BUSH
            );  
            try foliage_list.append(foliage); 
        } else {
            const foliage = Foliage.createFoliage(
                Vec2{.x = @floatFromInt(x * 32), .y = @floatFromInt(y * 32)},
                FoliageType.TREE
            );  
            try foliage_list.append(foliage); 
            
        }
    } 
}

pub fn drawFoliage() void {
    for (foliage_list.items) |f| {
        Foliage.drawFoliage(&f); 
    }
}



