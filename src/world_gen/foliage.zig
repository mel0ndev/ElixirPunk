const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
const sprites = @import("../entities/sprites.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 

const TREE_BIAS = 60; 

pub const FoliageType = enum {
    TREE,
    ROCK,
    BUSH, }; 

pub const Foliage = struct {
    sprite: sprites.Sprite,
    collider: Rect,
    ftype: FoliageType,
    
    pub fn createFoliage(
        texture: Texture2D, 
        rect: Rect, 
        collider: Rect,
        origin: Vec2, 
        scale: f32,
        ftype: FoliageType
        ) Foliage {

        const f = Foliage{
            .sprite = sprites.Sprite{
                .texture = texture,
                .rect = rect,
                .origin = origin,
                .scale = scale,
            },
            .collider = collider,
            .ftype = ftype
        }; 

        return f; 
    }
};

pub var foliage_set: std.AutoHashMap(FoliageType, Texture2D) = undefined; 
pub var foliage_list: std.ArrayList(Foliage) = undefined; 


pub fn initFoliage(alloc: std.mem.Allocator) !void {
    _ = try createFoliageHashmap(alloc); 
    _ = try createFoliageList(alloc); 
    try setFoliageMap(); 
}

pub fn updateFoliage() void {
    drawFoliage(); 
}

pub fn deinitFoliage() void {
    foliage_set.deinit(); 
    foliage_list.deinit(); 
}

//init hashmap of foliage sprites to tilemap
fn createFoliageHashmap(alloc: std.mem.Allocator) !std.AutoHashMap(FoliageType, Texture2D) {
    foliage_set = std.AutoHashMap(FoliageType, Texture2D).init(alloc);  
    return foliage_set; 
} 

fn createFoliageList(alloc: std.mem.Allocator) !std.ArrayList(Foliage) {
    foliage_list = std.ArrayList(Foliage).init(alloc); 
    return foliage_list; 
}

fn setFoliageMap() !void {
    const BUSH_TEXTURE: Texture2D = raylib.LoadTexture("src/world/assets/interactives/bush.png"); 
    const TREE_TEXTURE: Texture2D = raylib.LoadTexture("src/world/assets/interactives/tree.png"); 
    try foliage_set.putNoClobber(FoliageType.BUSH, BUSH_TEXTURE); 
    try foliage_set.putNoClobber(FoliageType.TREE, TREE_TEXTURE); 
}

pub fn generateFoliageData(x: usize, y: usize, chunk_x: isize, chunk_y: isize) !void {
    //get random number
    //var random_num: u8 = r.random().intRangeLessThan(u8, 0, 100);

    ////determine if we should put down a tree or a bush (tree bias)
    //if (random_num < 60) {
    //    const texture = foliage_set.get(FoliageType.TREE); 

    //    const tree = Foliage.createFoliage(
    //        texture,
    //        .{
    //            .x = @as(u32, @intCast(chunk_x + 1)) * x,
    //            .y = 3 + 1 * 54 
    //         },
    //        //collider,
    //        //origin,
    //        //scale,
    //        //type
    //    );
    //}    
    //generate the data for the tile, based on the chunk
    //store it in the foliage list
    _ = x; _ = y; _ = chunk_x; _ = chunk_y; 
}

fn drawFoliage() void {
    for (foliage_list.items) |f| {
        raylib.DrawTextureEx(
            f.sprite.texture,
            Vec2{.x = f.sprite.rect.x, .y = f.sprite.rect.y},
            0, //rotation
            f.sprite.scale,
            raylib.WHITE
        );
    }
}

fn addToSpriteList() !void {
    for (foliage_list.items) |f| {
        try sprites.entities_list.append(f.sprite);  
        try sprites.collider_list.append(f.collider); 
    }
}




