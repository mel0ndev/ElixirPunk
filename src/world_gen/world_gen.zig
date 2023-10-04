const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
const player = @import("../entities/player.zig"); 
//const foliage = @import("./foliage.zig"); 
//const interactables = @import("../entities/interactables.zig"); 
//TODO: seed can be generated at world generation
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 

//DEBUG MENU OPTIONS
pub var DEBUG_MODE_NEIGHBORS: bool = false; 
pub var DEBUG_MODE_TILE_POS: bool = false; 

//chunks are therefore 64x64 tiles
const CHUNK_SIZE: u32 = 64; 
const CHUNK_LOAD_DISTANCE: u32 = 16;  //tiles away 
var chunk: [CHUNK_SIZE][CHUNK_SIZE]u8 = undefined; 

//do we need this??
var chunk_list: std.ArrayList(Chunk) = undefined; 

const WATER: u8 = 0; 
const SOLID: u8 = 1; 
const GRASS_CHANCE: u8 = 60; 

pub fn initMap(alloc: std.mem.Allocator) !void {
    //create file basic file
    _ = try createChunkList(alloc); 
    //TODO:
    //check if file has already been created, if it is, load it, if not, create it
    var file = try createChunkFile(alloc, 0, 0); 
    defer file.close(); 
    //generate map data
    try generateChunkData(null); 
    //gen hashmap data
    try tiles.initTiles(alloc); 
    //try foliage.setFoliageMap(); 
    //try interactables.initInteractables(); 
    //  - convert to tilemap
    try convertToTiles(); 

    //save converted data to file
    try std.json.stringify(
        tiles.TileList{.tiles = tiles.tile_list.items}, 
        .{.whitespace = .indent_1}, 
        file.writer()
    ); 
}

pub fn update(alloc: std.mem.Allocator) !void {
    tiles.update();
    const player_position = player.getPlayerToTilePosition(); 
    const current_chunk = player.getPlayerToChunkPosition(); 
    try createNewChunk(alloc, player_position, current_chunk); 
}

pub fn deinitMap() void {
    tiles.deinitTiles(); 
    //chunk_list.deinit(); 
}

const Chunk = struct {
    position: Vec2, 
    tile_list: std.ArrayList(tiles.Tile),

    pub fn init(
        alloc: std.mem.Allocator,
        position: Vec2,
        tile_list: std.ArrayList(tiles.Tile)
    ) !Chunk {
        var c = Chunk{
            .position = position,
            .tile_list = tile_list.init(alloc),
        };  

        return c; 
    }

    pub fn deinit(self: *Chunk) void {
        self.tile_list.deinit();  
    }
}; 


fn createChunkList(alloc: std.mem.Allocator) !*std.ArrayList(Chunk) {
    chunk_list = std.ArrayList(Chunk).init(alloc); 
    return &chunk_list;  
}


fn createChunkFile(alloc: std.mem.Allocator, chunk_x: i32, chunk_y: i32) !std.fs.File {
    const new_chunk_file_name = try std.fmt.allocPrint(
        alloc, 
        "src/map/chunk_x{d}_y{d}.json", 
        .{chunk_x, chunk_y}
    ); 
    defer alloc.free(new_chunk_file_name); 

    var file = try std.fs.cwd().createFile(
        new_chunk_file_name,
        .{ .read = true } //TODO add: .exclusive = true if we don't want to overwrite 
    ); 

    return file; 
}

//this is player position in TILES not f32
fn createNewChunk(
        alloc: std.mem.Allocator, 
        player_position: Vec2,
        current_chunk: Vec2,
    ) !void {
    //get the current player postion, find out if they are n number of tiles
    //away from the chunk border
    //if they are n > chunk_load_distance, we check if chunk data exists for the chunk
    //if it does not, we generate the chunk data
    //we use the border tiles to generate the borders, and then go from there
    //the generation will match the borders, but the rest will be randomly generated
    //using the algo we already have
    //
    //we need a way to get the correct border tiles based on the direction
    //to do that, we can get the current position of the player and check their x and y values
    //if x is close to border, we load the x chunk
    //if y is close to border, we also load the y chunk
    //
    //
    //how do we get the chunk the player is in?
    //get the player position, check if it is bounds of the chunk?
    const max_chunk_x: i32 = 
        @as(i32, CHUNK_SIZE) * @as(i32, @intFromFloat(current_chunk.x + 1)); 
    const max_chunk_y: i32 = 
        @as(i32, CHUNK_SIZE) * @as(i32, @intFromFloat(current_chunk.y + 1)); 
    const min_chunk_x: i32 = @as(i32, @intCast(max_chunk_x - CHUNK_SIZE));  
    const min_chunk_y: i32 = @as(i32, @intCast(max_chunk_y - CHUNK_SIZE)); 

    
    //positive x
    //std.debug.print("max x is {}\n", .{max_chunk_x}); 
    //std.debug.print("min x is {}\n", .{min_chunk_x}); 
    std.debug.print("max y is {}\n", .{max_chunk_y}); 
    std.debug.print("min y is {}\n", .{min_chunk_y}); 
    if (@as(i32, @intFromFloat(player_position.x)) > max_chunk_x - CHUNK_LOAD_DISTANCE) {
        //check if current chunk data exists
        //if it does, we load it to next_chunk_list
        //if it does not, we generate it
        std.debug.print("should load next chunk +x direciton\n", .{}); 
        var new_file = try createChunkFile(
            alloc, 
            @as(i32, @intFromFloat(current_chunk.x + 1)),
            @as(i32, @intFromFloat(current_chunk.y))
        ); 
        
        defer new_file.close(); 
    }
        
    //negative x direction
    if (@as(i32, @intFromFloat(player_position.x)) < min_chunk_x + CHUNK_LOAD_DISTANCE) {
        std.debug.print("should load next chunk -x direciton\n", .{}); 
    }
    
    //positive y direction
    if (@as(i32, @intFromFloat(player_position.y)) > max_chunk_y - CHUNK_LOAD_DISTANCE) {
        std.debug.print("should load next chunk +y direciton\n", .{}); 
    }
    
    //negative y direction
    if (@as(i32, @intFromFloat(player_position.y)) < min_chunk_y + CHUNK_LOAD_DISTANCE) {
        std.debug.print("should load next chunk -y direciton\n", .{}); 
    }
} 


fn generateChunkData(adjacent_chunk: ?std.ArrayList(tiles.Tile)) !void {
    _ = adjacent_chunk; 
    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            //terrain algo goes here
            var random_num: u8 = r.random().intRangeLessThan(u8, 0, 100);
            if (random_num > GRASS_CHANCE) {
                chunk[x][y] = SOLID;
            } else {
                chunk[x][y] = WATER;     
            }
        }
    }
    
    var n: usize = 0; 
    while (n < 6) : (n += 1) {
        iterateChunkGen(); 
    }

}

fn iterateChunkGen() void {
    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            var neighbor_data: i16 = getNeighborCount(@intCast(x), @intCast(y)); 
            if (neighbor_data > 3) {
                chunk[x][y] = SOLID; 
            } else {
                chunk[x][y] = WATER; 
            }
        }
    }
}

fn convertToTiles() !void {
    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            if (chunk[x][y] == WATER) {

                const neighbor_count = getNeighborCount(@intCast(x), @intCast(y)); 
                const placement = getCellToTile(
                    @intCast(x), 
                    @intCast(y) 
                ); 
                const tile_id = placementToTileId(placement);
                const tile_data = tiles.TileData.init(
                    neighbor_count,
                    Vec2{.x = @floatFromInt(x), .y = @floatFromInt(y)}
                );  
                const tile = tiles.Tile.init(tile_data, tile_id); 
                try tiles.tile_list.append(tile); 

            } else if (chunk[x][y] == SOLID) {

                var random_num: u8 = r.random().intRangeLessThan(u8, 0, 50);

                if (@mod(random_num, 20) == 0) {

                    random_num = r.random().intRangeLessThan(u8, 1, 16);
                    const tile_data = tiles.TileData.init(
                        getNeighborCount(@intCast(x), @intCast(y)),
                        Vec2{.x = @floatFromInt(x), .y = @floatFromInt(y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, random_num); 
                    try tiles.tile_list.append(tile); 

                } else {

                    const tile_data = tiles.TileData.init(
                        getNeighborCount(@intCast(x), @intCast(y)),
                        Vec2{.x = @floatFromInt(x), .y = @floatFromInt(y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, 0); 
                    try tiles.tile_list.append(tile); 
                }
            }
        }
    }
}

fn placementToTileId(tile_data: tiles.TilePlacement) u8 {
    //get the neighbor count of the tile
    return tiles.tile_map_placement_data.get(tile_data).?; 
}

//get the local neighbors in a slice, iterate through them, assigning the index + 1 as the counter 
//the total sum returned is our indication of how the tile needs to be placed
//NOTE: this will only work for now, if we wanted to include, say, sand later, this function will have to be adapted
fn getCellToTile(tile_x: i16, tile_y: i16) tiles.TilePlacement {
    const neighbors = getLocalNeighborsAsArray(tile_x, tile_y); 
    var placement_counter: u32 = 0; 
    //convert neighbor data into tile data 
    for (neighbors, 0..) |pos, i| {
        //if a neighbor is a grass tile
        const casted_i: u32 = @intCast(i); 
        if (chunk[@intFromFloat(pos.x)][@intFromFloat(pos.y)] == 1) {
            if (i == 1 or i == 3 or i == 4 or i == 6) { 
                const add = getPlacementNumber(casted_i); 
                placement_counter += add;  
            }
        }
    }

    const tile_placement = assignPlacement(placement_counter); 
    return tile_placement; 
}

//fn getCellToTileDebug(tile_x: i16, tile_y: i16) u32 {
//    const neighbors = getLocalNeighborsAsArray(tile_x, tile_y); 
//    var placement_counter: u32 = 0; 
//    //convert neighbor data into tile data 
//    for (neighbors, 0..) |pos, i| {
//        //if a neighbor is a grass tile
//        std.debug.print("x: {}   y: {}     i: {}\n", .{pos.x, pos.y, i}); 
//        const casted_i: u32 = @intCast(i); 
//        if (chunk[@intFromFloat(pos.x)][@intFromFloat(pos.y)] == 1) {
//            if (i == 1 or i == 3 or i == 4 or i == 6) { 
//                std.debug.print("running on i = {}\n", .{casted_i}); 
//                const add = getPlacementNumber(casted_i); 
//                placement_counter += add;  
//            }
//        }
//    }
//
//    std.debug.print("final count is: {}\n", .{placement_counter}); 
//    const tile_placement = assignPlacement(placement_counter); 
//    std.debug.print("placement is: {}", .{tile_placement});
//    return placement_counter; 
//}

fn getPlacementNumber(n: u32) u32 {
    const num: u32 = switch (n) {
        1 => 1,
        3 => 2,
        4 => 4, 
        6 => 8,
        else => 0
    };
    
    return num; 
}

fn getNeighborCount(tile_x: i16, tile_y: i16) i16 {
    var count: i16 = 0;
    var neighbor_x: i16 = undefined; 
    var neighbor_y: i16 = undefined; 
    
    neighbor_x = tile_x - 1; 
    while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
        neighbor_y = tile_y - 1;
        while(neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
            if (neighbor_x >= 0 and neighbor_x < CHUNK_SIZE
                and neighbor_y >= 0 and neighbor_y < CHUNK_SIZE) {
                if (neighbor_x != tile_x or neighbor_y != tile_y) {
                    if (chunk[@intCast(neighbor_x)][@intCast(neighbor_y)] == 1) {
                        count += 1;
                    }
                }
            }
        }
    }
    return count; 
}


fn getLocalNeighborsAsArray(tile_x: i16, tile_y: i16) [8]Vec2 {
    var return_tiles: [8]Vec2 = undefined; 
    var iterator: u8 = 0;  

    var neighbor_x: i16 = tile_x - 1;  
    while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
        var neighbor_y: i16 = tile_y - 1; 
        while (neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
            if (neighbor_x != tile_x or neighbor_y != tile_y) {
                if (neighbor_x >= 0 and neighbor_x < CHUNK_SIZE
                and neighbor_y >= 0 and neighbor_y < CHUNK_SIZE) {
                    const data: Vec2 = .{
                        .x = @floatFromInt(neighbor_x),
                        .y = @floatFromInt(neighbor_y)
                    };

                    return_tiles[iterator] = data;
                }

                iterator += 1; 
            }
        }
    }
    
    return return_tiles; 
}

fn assignPlacement(placement_counter: u32) tiles.TilePlacement {
    const placement = switch (placement_counter) {
        3 => tiles.TilePlacement.TOP_LEFT,
        10 => tiles.TilePlacement.TOP_RIGHT,
        5  => tiles.TilePlacement.BOTTOM_LEFT,
        12 => tiles.TilePlacement.BOTTOM_RIGHT,
        1 => tiles.TilePlacement.LEFT,
        2 => tiles.TilePlacement.TOP,
        8 => tiles.TilePlacement.RIGHT,
        4 => tiles.TilePlacement.BOTTOM,
        else => tiles.TilePlacement.MIDDLE
    };

    return placement; 
}

