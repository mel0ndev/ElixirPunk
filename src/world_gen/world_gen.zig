const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
//const foliage = @import("./foliage.zig"); 
//const interactables = @import("../entities/interactables.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 

//chunks are therefore 64x64 tiles
pub const GRID_X: u32 = 64;
pub const GRID_Y: u32 = 64;
var map: [GRID_X][GRID_Y]u8 = undefined; 
pub var DEBUG_MODE: bool = false; 

const WATER: u8 = 0; 
const SOLID: u8 = 1; 
const GRASS_CHANCE: u8 = 60; 

    
pub fn initMap(alloc: std.mem.Allocator) !void {
    //create file basic file
    //
    var file = try createMapFile(); 
    defer file.close(); 
    //generate map data
    try generateMapData(file); 
    //gen hashmap data
    try tiles.initTiles(alloc); 
    //try foliage.setFoliageMap(); 
    //try interactables.initInteractables(); 
    //  - convert to tilemap
    try convertToTiles(); 

    const num: u32 = getCellToTileDebug(2, 63); 
    std.debug.print("i is: {}\n", .{num}); 
    //save converted data to file
    try std.json.stringify(
        tiles.TileList{.tiles = tiles.tile_list.items}, 
        .{.whitespace = .indent_1}, 
        file.writer()
    ); 
}

pub fn update() void {
    if (raylib.IsKeyPressed(raylib.KEY_I)) {
        if (DEBUG_MODE == true) {
            DEBUG_MODE = false; 
        } else {
            DEBUG_MODE = true; 
        }
    }

    tiles.update(); 
}

pub fn deinitMap() void {
    tiles.deinitTiles(); 
}

//TODO: refactor and optimize -- single loop that does everything
fn createMapFile() !std.fs.File {
    const file = try std.fs.cwd().createFile(
        "src/map/map.json",
        .{ .read = true }
    );
    return file; 
}


fn generateMapData(file: std.fs.File) !void {
    _ = file; 
    for (0..GRID_X) |x| {
        for (0..GRID_Y) |y| {
            //terrain algo goes here
            var random_num: u8 = r.random().intRangeLessThan(u8, 0, 100);
            if (random_num > GRASS_CHANCE) {
                map[x][y] = SOLID;
            } else {
                map[x][y] = WATER;     
            }
        }
    }
    
    var n: usize = 0; 
    while (n < 6) : (n += 1) {
        iterateMapGen(); 
    }

}

fn iterateMapGen() void {
    for (0..GRID_X) |x| {
        for (0..GRID_Y) |y| {
            var neighbor_data: i16 = getNeighborCount(@intCast(x), @intCast(y)); 
            if (neighbor_data > 3) {
                map[x][y] = SOLID; 
            } else {
                map[x][y] = WATER; 
            }
        }
    }
}

fn convertToTiles() !void {
    for (0..GRID_X) |x| {
        for (0..GRID_Y) |y| {
            if (map[x][y] == WATER) {

                const neighbor_count = getNeighborCount(@intCast(x), @intCast(y)); 
                const placement = getCellToTile(
                    @intCast(x), 
                    @intCast(y) 
                ); 
                const tile_id = placementToTileId(placement);
                if (x == 5 and y == 3) {
                    std.debug.print("tile_id {}\n", .{tile_id}); 
                    std.debug.print("placement {}\n", .{placement}); 
                }
                const tile_data = tiles.TileData.init(
                    neighbor_count,
                    Vec2{.x = @floatFromInt(x), .y = @floatFromInt(y)}
                );  
                const tile = tiles.Tile.init(tile_data, tile_id); 
                try tiles.tile_list.append(tile); 

            } else if (map[x][y] == SOLID) {

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
        if (map[@intFromFloat(pos.x)][@intFromFloat(pos.y)] == 1) {
            if (i == 1 or i == 3 or i == 4 or i == 6) { 
                const add = getPlacementNumber(casted_i); 
                placement_counter += add;  
            }
        }
    }

    const tile_placement = assignPlacement(placement_counter); 
    return tile_placement; 
}

fn getCellToTileDebug(tile_x: i16, tile_y: i16) u32 {
    const neighbors = getLocalNeighborsAsArray(tile_x, tile_y); 
    var placement_counter: u32 = 0; 
    //convert neighbor data into tile data 
    for (neighbors, 0..) |pos, i| {
        //if a neighbor is a grass tile
        std.debug.print("x: {}   y: {}     i: {}\n", .{pos.x, pos.y, i}); 
        const casted_i: u32 = @intCast(i); 
        if (map[@intFromFloat(pos.x)][@intFromFloat(pos.y)] == 1) {
            if (i == 1 or i == 3 or i == 4 or i == 6) { 
                std.debug.print("running on i = {}\n", .{casted_i}); 
                const add = getPlacementNumber(casted_i); 
                placement_counter += add;  
            }
        }
    }

    std.debug.print("final count is: {}\n", .{placement_counter}); 
    const tile_placement = assignPlacement(placement_counter); 
    std.debug.print("placement is: {}", .{tile_placement});
    return placement_counter; 
}

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
            if (neighbor_x >= 0 and neighbor_x < GRID_X
                and neighbor_y >= 0 and neighbor_y < GRID_Y) {
                if (neighbor_x != tile_x or neighbor_y != tile_y) {
                    if (map[@intCast(neighbor_x)][@intCast(neighbor_y)] == 1) {
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
                if (neighbor_x >= 0 and neighbor_x < GRID_X
                and neighbor_y >= 0 and neighbor_y < GRID_Y) {
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

