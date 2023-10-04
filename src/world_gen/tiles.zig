const std = @import("std"); 
const raylib = @cImport({ @cInclude("raylib.h");
});
const world = @import("./world_gen.zig"); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 

//seed (0) rn 
var r  = std.rand.DefaultPrng.init(0); 

const GRASS_TILE_SIZE: u8 = 16; 
const WATER_TILE_SIZE: u8 = 9; 
const GROUND_TILE_SIZE: u8 = 9; 

pub var tile_list: std.ArrayList(Tile) = undefined; 
pub var tile_map_placement_data: std.AutoHashMap(TilePlacement, u8) = undefined; 
pub var tile_texture_map: Texture2D = undefined; 
var tile_set: std.AutoHashMap(u8, Vec2) = undefined;  

pub fn initTiles(alloc: std.mem.Allocator) !void {
    _ = try createTileList(alloc); 
    _ = try createTileHashMap(alloc); 
    _ = try createTilePlacementHashMap(alloc); 
    _ = try loadTextureMap(); 
    try setTileMap(); 
}

pub fn update() void {
    //update tiles 
    drawTiles(); 
} 


pub fn deinitTiles() void {
    tile_list.deinit(); 
    tile_set.deinit(); 
    tile_map_placement_data.deinit(); 
    raylib.UnloadTexture(tile_texture_map); 
}

pub const TilePlacement = enum {
    TOP_LEFT, //0
    TOP, //1
    TOP_RIGHT, //2
    LEFT, //3
    MIDDLE, //4
    RIGHT, //5
    BOTTOM_LEFT, //6
    BOTTOM, //7
    BOTTOM_RIGHT, //8
}; 

pub const TileType = enum { 
    GRASS,
    PLANT, //flower, tall grass, etc
    DIRT,
    WATER,
    SAND,
    STONE,
    INTERACTABLE,
};

//for deserializing
pub const TileList = struct {
    tiles: []Tile,
}; 

pub const Tile = struct {

    tile_data: TileData,
    tile_id: u8,
    has_interactable: bool = false, //foliage, chest spawn, portal, altar, etc

    pub fn init(tile_data: TileData, tile_id: u8) Tile {
        var tile = Tile{
            .tile_data = tile_data,
            .tile_id = tile_id,
        };   

        return tile; 
    } 

    ////for serializing the Tile struct
    //pub fn serialize(
    //    self: *Tile, 
    //    options: std.json.StringifyOptions, 
    //    out_stream: anytype, //should be our file.writer() 
    //    ) !void {
    //    
    //    try std.json.stringify(
    //        Tile{
    //            .tile_data = self.tile_data, 
    //            .tile_type = self.tile_data
    //        }, 
    //        options, 
    //        out_stream
    //    );  
    //}
     
    pub fn loadTexture(path: [*c]const u8) Texture2D {
        const texture: Texture2D = raylib.LoadTexture(path); 
        return texture; 
    }

    pub fn getPosition(self: *Tile) Vec2 {
        return self.tile_data.pos; 
    }
}; 

pub const TileData = struct {
    count: i16,
    pos: Vec2, 

    pub fn init(n_count: i16, position: Vec2) TileData {
        var td = TileData{
            .count = n_count,
            .pos = position,
        }; 

        return td; 
    } 
};

fn createTileList(alloc: std.mem.Allocator) !*std.ArrayList(Tile) {
    tile_list = std.ArrayList(Tile).init(alloc); 
    return &tile_list; 
}

//maps the location in the tilemap file to the coordinates needed to draw
fn createTileHashMap(alloc: std.mem.Allocator) !*std.AutoHashMap(u8, Vec2) {
    tile_set = std.AutoHashMap(u8, Vec2).init(alloc);  
    return &tile_set; 
}

//for the placement of tiles around grass tiles
fn createTilePlacementHashMap(alloc: std.mem.Allocator) !*std.AutoHashMap(TilePlacement, u8) {
    tile_map_placement_data = std.AutoHashMap(TilePlacement, u8).init(alloc);  
    return &tile_map_placement_data; 
}


fn loadTextureMap() !void {
    tile_texture_map = raylib.LoadTexture("src/assets/tiles/grass.png");  
}

pub fn setTileMap() !void {
    for (0..GRASS_TILE_SIZE) |i| {
        const casted_i: f32 = @floatFromInt(i); 
        var texture_postion: Vec2 = Vec2{
           .x =  casted_i * 16,
           .y = 0,
        }; 

        //grass textures
        //0 - 15
        try tile_set.putNoClobber(@intCast(i), texture_postion); 
    } 
    
    for (0..WATER_TILE_SIZE) |i| {
        const casted_i: f32 = @floatFromInt(i); 
        var texture_postion: Vec2 = Vec2{
           .x =  casted_i * 16,
           .y = 16,
        }; 

        //water textures
        //16 - 24
        try tile_set.putNoClobber(@intCast(i + 16), texture_postion); 
        try tile_map_placement_data.putNoClobber(@enumFromInt(i), @intCast(i + 16)); 
        //var temp: TilePlacement = @enumFromInt(i); 
        //std.debug.print("enum is: {any}, i is: {}\n", .{temp, @as(usize, @intCast(i + 16))}); 
    }
}

pub fn drawTiles() void {
    for (tile_list.items) |tile| {
        const rec_pos: Vec2 = tile_set.get(tile.tile_id).?; 
        const x = tile.tile_data.pos.x;
        const y = tile.tile_data.pos.y;

        //if (x == 5 and y == 3) {
        //    std.debug.print("tile id: {}\n", .{tile.tile_id}); 
        //    std.debug.print("rec pos: {}\n", .{rec_pos});
        //}

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
            tile_texture_map, 
            tilemap_pos, 
            world_pos, 
            Vec2{.x = 0, .y = 0}, 
            0, //rotation
            raylib.RAYWHITE
        ); 

        //IF DEBUGGING IS NEEDED
        if (world.DEBUG_MODE_NEIGHBORS) {
            var font = raylib.GetFontDefault(); 
            var buf: [1024]u8 = undefined;
            const s = std.fmt.bufPrintZ(
                &buf, 
                "{d}", 
                .{tile.tile_data.count}
            ) catch @panic("error");
            raylib.DrawTextPro(
                font,
                s,
                Vec2{
                    .x = world_pos.x + 8,
                    .y = world_pos.y + 8,
                },
                Vec2{
                    .x = 0,
                    .y = 0,
                },
                0,
                12,
                1,
                raylib.RED
            ); 
        } else if (world.DEBUG_MODE_TILE_POS) {
            var font = raylib.GetFontDefault(); 
            var buf: [1024]u8 = undefined;
            const s = std.fmt.bufPrintZ(
                &buf, 
                "{d}, {d}", 
                .{tile.tile_data.pos.x, tile.tile_data.pos.y}
            ) catch @panic("error");
            raylib.DrawTextPro(
                font,
                s,
                Vec2{
                    .x = world_pos.x + 8,
                    .y = world_pos.y + 8,
                },
                Vec2{
                    .x = 0,
                    .y = 0,
                },
                0,
                10,
                1,
                raylib.WHITE
            ); 
        }
    }
}


