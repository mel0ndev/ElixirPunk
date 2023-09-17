const std = @import("std"); 
const raylib = @cImport({ @cInclude("raylib.h");
});
const world = @import("./world.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 

pub const TileType = enum { 
    GRASS,
    DIRT,
    WATER,
    SAND,
    STONE,
};


pub const TilePlacement = enum {
    TOP_LEFT,
    TOP,
    TOP_RIGHT,
    LEFT,
    MIDDLE,
    RIGHT,
    BOTTOM_LEFT,
    BOTTOM,
    BOTTOM_RIGHT,
}; 

pub const TileData = struct {
    count: i16,
    pos: Vec2, 
    placement: TilePlacement,

    pub fn init(n_count: i16, position: Vec2, place: TilePlacement) TileData {
        const td = TileData{
            .count = n_count,
            .pos = position,
            .placement = place
        }; 

        return td; 
    } 
};

pub const Tile = struct {

    tile_type: TileType,
    tile_data: TileData,
     
    pub fn loadTexture(path: [*c]const u8) Texture2D {
        const texture: Texture2D = raylib.LoadTexture(path); 
        return texture; 
    }

    pub fn getPosition(self: *Tile) Vec2 {
        return self.tile_data.pos; 
    }
}; 


const GRASS_TILE_SIZE: u8 = 16; 
const WATER_TILE_SIZE: u8 = 9; 
const GROUND_TILE_SIZE: u8 = 9; 
pub var tile_set: std.AutoHashMap(u8, Vec2) = undefined;  
pub var tile_map_placement_data: std.AutoHashMap(TilePlacement, u8) = undefined; 
pub var tile_list: [world.GRID_X][world.GRID_Y]Tile = undefined; 

//maps the location in the tilemap file to the coordinates needed to draw
pub fn createTileHashMap(alloc: std.mem.Allocator) !std.AutoHashMap(u8, Vec2) {
    tile_set = std.AutoHashMap(u8, Vec2).init(alloc);  
    return tile_set; 
}

//for the placement of tiles around grass tiles
pub fn createTilePlacementHashMap(alloc: std.mem.Allocator) !std.AutoHashMap(TilePlacement, u8) {
    tile_map_placement_data = std.AutoHashMap(TilePlacement, u8).init(alloc);  
    return tile_map_placement_data; 
}

//can technically return an error
pub fn setTileMap() !void {
    for (0..GRASS_TILE_SIZE) |i| {
        const casted_i: f32 = @floatFromInt(i); 
        var texture_postion: Vec2 = Vec2{
           .x =  casted_i * 16,
           .y = 0,
        }; 

        //grass textures
        try tile_set.putNoClobber(@intCast(i), texture_postion); 
    } 
    
    for (0..WATER_TILE_SIZE) |i| {
        const casted_i: f32 = @floatFromInt(i); 
        var texture_postion: Vec2 = Vec2{
           .x =  casted_i * 16,
           .y = 16,
        }; 

        //water textures
        try tile_set.putNoClobber(@intCast(i + 17), texture_postion); 
        try tile_map_placement_data.putNoClobber(@enumFromInt(i), @intCast(i + 17)); 
    }
}

//TODO: have this read from the map file and get position directly from there
pub fn drawTiles(x: f32, y: f32, num: u8, texture: Texture2D) void {
    const rec_pos: Vec2 = tile_set.get(num).?; 
    const world_pos = raylib.Rectangle{
        .x = x * 32,
        .y = y * 32,
        .width = 32,
        .height = 32,
    };
    const tilemap_pos = raylib.Rectangle{
        .x = rec_pos.x,
        .y = rec_pos.y,
        .width = 16,
        .height = 16,
    };

    raylib.DrawTexturePro(
        texture, 
        tilemap_pos, 
        world_pos, 
        Vec2{.x = 0, .y = 0}, 
        0, //rotation
        raylib.RAYWHITE
    ); 

    //IF DEBUGGING IS NEEDED
    //var font = raylib.GetFontDefault(); 
    //var buf: [1024]u8 = undefined;
    //const s = std.fmt.bufPrintZ(&buf, "{d}", .{x}) catch @panic("error");
    //raylib.DrawTextPro(
    //    font,
    //    s,
    //    Vec2{
    //        .x = world_pos.x,
    //        .y = world_pos.y,
    //    },
    //    Vec2{
    //        .x = 0,
    //        .y = 0,
    //    },
    //    0,
    //    12,
    //    1,
    //    raylib.RED
    //); 
}

