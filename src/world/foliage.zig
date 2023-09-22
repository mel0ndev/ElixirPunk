const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
const entities = @import("../entities/entities.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 

//this is probably not needed, idr why I used an enum if I'm just going to set it directly?
pub const FoliageType = enum {
    TREE,
    ROCK,
    BUSH,
}; 

pub const Foliage = struct {
    sprite: entities.Sprite,
    collider: Rect,
    ftype: FoliageType,
    
    pub fn createFoliage(
        texture: Texture2D, 
        rect: Rect, 
        collider: Rect,
        origin: Vec2, 
        ftype: FoliageType
        ) Foliage {

        var f = Foliage{
            .sprite = entities.Sprite{
                .texture = texture,
                .rect = rect,
                .origin = origin,
            },
            .collider = collider,
            .ftype = ftype
        }; 

        return f; 
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
            var texture = foliage_set.get(FoliageType.BUSH).?; 
            var texture_width: f32 = @floatFromInt(@divTrunc(texture.width, 2)); 
            var texture_height: f32 = @floatFromInt(texture.height); 
            //tex, sprite rec, collider, origin, type
            const foliage = Foliage.createFoliage(
                texture,
                Rect{.x = @floatFromInt(x * 32), 
                     .y = @floatFromInt(y * 32),
                     .width = @floatFromInt(texture.width),
                     .height = @floatFromInt(texture.height)
                 }, 
                Rect{.x = @as(f32, @floatFromInt(x * 32)) + texture_width - 5.0, 
                     .y = @as(f32, @floatFromInt(y * 32)) + texture_height - 12.0,
                     .width = 10,
                     .height = 10,
                 },
                 Vec2{.x = @as(f32, @floatFromInt(x * 32)) + texture_width,
                      .y = @as(f32, @floatFromInt(y * 32)),
                 },
                FoliageType.BUSH
            );  

            try foliage_list.append(foliage); 

        } else {
            var texture = foliage_set.get(FoliageType.TREE).?; 
            var texture_width: f32 = @floatFromInt(@divTrunc(texture.width, 2)); 
            var texture_height: f32 = @floatFromInt(texture.height); 
            const foliage = Foliage.createFoliage(
                texture,
                Rect{.x = @floatFromInt(x * 32), 
                     .y = @floatFromInt(y * 32),
                     .width = @floatFromInt(texture.width),
                     .height = @floatFromInt(texture.height)
                 },
                Rect{.x = @as(f32, @floatFromInt(x * 32)) + texture_width - 8, 
                     .y = @as(f32, @floatFromInt(y * 32)) + texture_height - 36.0,
                     .width = 16,
                     .height = 36,
                 },
                 Vec2{.x = @as(f32, @floatFromInt(x * 32)) + texture_width,
                      .y = @as(f32, @floatFromInt(y * 32)) + texture_height - 24.0,
                 },
                FoliageType.TREE
            );  

            try foliage_list.append(foliage); 
            
        }
    } 
}

pub fn addToSpriteList() !void {
    for (foliage_list.items) |f| {
        try entities.entities_list.append(f.sprite);  
        try entities.collider_list.append(f.collider); 
    }
}




