const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
const player = @import("../entities/player.zig"); 
const utils = @import("../utils/utils.zig"); 
const foliage = @import("./foliage.zig"); 
//const interactables = @import("../entities/interactables.zig"); 
//TODO: seed can be generated at world generation
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 
const iVec2 = utils.iVec2; 
 
//DEBUG MENU OPTIONS
pub var DEBUG_MODE_NEIGHBORS: bool = false; 
pub var DEBUG_MODE_TILE_POS: bool = false; 

//pub var chunk_list: std.ArrayList(*Chunk) = undefined; 
//pub var chunk_map: std.AutoHashMap(iVec2, *Chunk) = undefined; 
//pub var walkable_tiles: std.ArrayList(tiles.Tile) = undefined; 

const MAP_SIZE: u32 = 1280; 

//FLAGS

const WATER: u8 = 0; 
const SOLID: u8 = 1; 
const GRASS_CHANCE: u8 = 40; 

pub fn initMap(alloc: std.mem.Allocator) !void {

    //generate map data
    try generateMapData(); 
    //gen hashmap data
    try tiles.initTiles(alloc); 
    try foliage.initFoliage(alloc); 
    //try interactables.initInteractables(); 
    //  - convert to tilemap

    //save converted data to file
    //try std.json.stringify(
    //    tiles.TileList{.tilesFromSlice = new_chunk.tile_list.items}, 
    //    .{}, 
    //    file.writer()
    //); 
		
}



pub fn update(alloc: std.mem.Allocator) !void {
    //tiles.update();
    //foliage.updateFoliage(); 
    _ = alloc; 
    const player_position = player.getPlayerToTilePosition(); 
    _ = player_position; 
    //const current_chunk = player.getPlayerToChunkPosition(); 
    //TODO: load all in memory tiles into walkable tiles array
}

pub fn deinitMap(alloc: std.mem.Allocator) void {
    tiles.deinitTiles(); 
    foliage.deinitFoliage(); 
    _ = alloc; 

    //walkable_tiles.deinit(); 
}

fn generateMapData() !void {
    //TODO 
}


