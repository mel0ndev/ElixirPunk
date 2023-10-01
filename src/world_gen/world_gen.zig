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

var temp_map: [GRID_X][GRID_Y]u8 = undefined; 


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
    //save converted data to file
}

pub fn deinitMap() void {
    tiles.deinitTiles(); 
}

pub fn drawMap() !void {
    for (map, 0..) |row, x| {
       for (0..row.len) |y| {
            const num = map[x][y]; 
            tiles.drawTiles(
                @floatFromInt(x), 
                @floatFromInt(y), 
                num, 
                tiles.tile_texture_map
            ); 
        } 
    }
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
            var random_num: u8 = r.random().intRangeLessThan(u8, 0, 10);
            if (@mod(random_num, 4) == 0) {
                map[x][y] = 1;
            } else {
                map[x][y] = 0;     
            }
            //try file.writer().print("{}", .{map[x][y]}); 
        }
        //try file.writer().print("\n", .{}); 
    }

    for (0..20) |x| {
        _ = x; 
        iterateMapGen(); 
    }

}

fn iterateMapGen() void {
    for (0..GRID_X) |x| {
        for (0..GRID_Y) |y| {
            var neighbor_data: i16 = getNeighborCount(@intCast(x), @intCast(y)); 
            if (neighbor_data > 3) {
                map[x][y] = 1; 
            } else {
                map[x][y] = 0; 
            }
        }
    }
}

//TODO: convert map data into something that stores more data
fn convertToTiles() !void {
    for (0..GRID_X) |x| {
        for (0..GRID_Y) |y| {
            if (map[x][y] == 1) {
                var placement = getCellToTile(@intCast(x), @intCast(y)); 
                const tile_id = placementToTileId(placement);  
                temp_map[x][y] = tile_id; 
            } else if (map[x][y] == 0) {
                var random_num: u8 = r.random().intRangeLessThan(u8, 0, 50);
                if (@mod(random_num, 20) == 0) {
                    random_num = r.random().intRangeLessThan(u8, 0, 6);
                    //try foliage.generateFoliageData(x, y); 
                    temp_map[x][y] = random_num; 
                }
            }
        }
    }

    map = temp_map; 
}

fn placementToTileId(tile_data: tiles.TilePlacement) u8 {
    //get the neighbor count of the tile
    return tiles.tile_map_placement_data.get(tile_data).?; 
}

//function needs to iterate through the final map layout and convert all the tiles to the proper orientation, given the cell x and y
//TODO: fix how this is stored
//current issue is that the map is being updated, and 0s are not being counted as 0s
fn getCellToTile(tile_x: i16, tile_y: i16) tiles.TilePlacement {
    const neighbors = getNeighbors(tile_x, tile_y); 
    var placement_counter: u32 = 1; 
    //convert neighbor data into tile data 
    for (neighbors, 0..) |pos, i| {
        //if a neighbor is a grass tile
        const casted_i: u32 = @intCast(i); 
        if (map[@intFromFloat(pos.x)][@intFromFloat(pos.y)] == 0) {
            const multiplier = getMulitplier(casted_i); 
            placement_counter *= multiplier;  
        }

    }
    const tile_placement = assignPlacement(placement_counter); 
    return tile_placement; 
}

fn getMulitplier(n: u32) u32 {
    const multiplier: u32 = switch (n) {
        0 => 9,
        1 => 9,
        2 => 2,
        3 => 5,
        4 => 3,
        5 => 7,
        6 => 8,
        7 => 2,
        else => 1
    };
    
    return multiplier; 
        
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
                    count += map[@intCast(neighbor_x)][@intCast(neighbor_y)];
                }
            }
        }
    }
    return count; 
}


fn getNeighbors(tile_x: i16, tile_y: i16) [8]Vec2 {
    var return_tiles: [8]Vec2= undefined; 
    var iterator: u8 = 0;  

    var neighbor_x: i16 = tile_x - 1;  
    while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
        var neighbor_y: i16 = tile_y - 1; 
        while (neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
            if (neighbor_x >= 0 and neighbor_x < GRID_X
            and neighbor_y >= 0 and neighbor_y < GRID_Y) {
                if (neighbor_x != tile_x or neighbor_y != tile_y) {
                    const data: Vec2 = .{
                        .x = @floatFromInt(neighbor_x),
                        .y = @floatFromInt(neighbor_y)
                    };

                    return_tiles[iterator] = data;

                    iterator += 1; 
                }
            }
        }
    }
    
    return return_tiles; 
}

fn assignPlacement(placement_counter: u32) tiles.TilePlacement {
    const placement = switch (placement_counter) {
        405, 810, 2835 => tiles.TilePlacement.TOP_LEFT,
        280, 560, 2520 => tiles.TilePlacement.TOP_RIGHT,
        54, 108, 486, 972, 27  => tiles.TilePlacement.BOTTOM_LEFT,
        48, 96, 336 => tiles.TilePlacement.BOTTOM_RIGHT,
        18, 81, 162 => tiles.TilePlacement.LEFT,
        35, 45, 315 => tiles.TilePlacement.TOP,
        16, 56, 112 => tiles.TilePlacement.RIGHT,
        6, 12 => tiles.TilePlacement.BOTTOM,
        else => tiles.TilePlacement.MIDDLE
    };

    return placement; 
}

