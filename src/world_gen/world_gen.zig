const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
const player = @import("../entities/player.zig"); 
const utils = @import("../utils/utils.zig"); 
const deque = @import("../utils/deque.zig"); 
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
var vectorHashmap: std.AutoHashMap(iVec2, bool) = undefined; 
var tile_deque: deque.Deque(iVec2) = undefined; 

pub const MAP_SIZE: u32 = 128; 
var map: [MAP_SIZE][MAP_SIZE]u8 = undefined; 

const WATER: u8 = 0; 
const SOLID: u8 = 1; 
var CHANCE: f32 = 100; 
var DECAY_FACTOR: f32 = 0.9995; 

pub fn initMap(alloc: std.mem.Allocator) !void {
    //init memory
    try createVectorHashMap(alloc); 
    tile_deque = try deque.Deque(iVec2).init(alloc); 

    //gen hashmap data
    try tiles.initTiles(alloc); 
    try foliage.initFoliage(alloc); 
    //try interactables.initInteractables(); 
    
    //generate map data
    try generateMapData(); 
    //  - convert to tilemap

    //save converted data to file
    //try std.json.stringify(
    //    tiles.TileList{.tilesFromSlice = new_chunk.tile_list.items}, 
    //    .{}, 
    //    file.writer()
    //); 
    //x + y * MAP_SIZE; 
    std.debug.print("{any}", .{tiles.tile_list.items[10 + 10 * MAP_SIZE]}); 
		
}

fn createVectorHashMap(alloc: std.mem.Allocator) !void {
    vectorHashmap = std.AutoHashMap(iVec2, bool).init(alloc); 
    for (0..MAP_SIZE) |x| {
        for (0..MAP_SIZE) |y| {
            const vector: iVec2 = .{.x = @intCast(x), .y = @intCast(y)}; 
            try vectorHashmap.putNoClobber(vector, false); 
        }
    }
}



pub fn update(alloc: std.mem.Allocator) !void {
    tiles.update();
    //foliage.updateFoliage(); 
    _ = alloc; 
}

pub fn deinitMap(alloc: std.mem.Allocator) void {
    tiles.deinitTiles(); 
    foliage.deinitFoliage(); 
    tile_deque.deinit(); 
    vectorHashmap.deinit(); 
    _ = alloc; 

    //walkable_tiles.deinit(); 
}

//use the lazy flood fill algorithm
fn generateMapData() !void {
    for (0..10) |i| {
        _ = i; 
        const random_num_x: u16 = r.random().intRangeLessThan(u16, 16, MAP_SIZE - 16);
        const random_num_y: u16 = r.random().intRangeLessThan(u16, 16, MAP_SIZE - 16);
        const starting_point: iVec2 = .{.x = @intCast(random_num_x), .y = @intCast(random_num_y)}; 
        try tile_deque.pushBack(starting_point); 
         
        try lazyFloodFill(); 
    }
    
    for (0..10) |i| {
        _ = i; 
        mapCleanup(); 
    }
    

    for (map, 0..) |row, x| {
        for (0..row.len) |y| {
            if (map[x][y] == WATER) {
                const neighbor_count = getNeighborCount(@intCast(x), @intCast(y)); 
                const placement = getCellToTile(@intCast(x), @intCast(y)); 
                const tile_id = placementToTileId(placement);
                const tile_data = tiles.TileData.init(
                    neighbor_count,
                    Vec2{
                        .x = @as(f32, @floatFromInt(x)),
                        .y = @as(f32, @floatFromInt(y))
                    }
                );
                const tile = tiles.Tile.init(tile_data, tile_id);
                try tiles.tile_list.append(tile);
            } else {
                var random_num = r.random().intRangeLessThan(u8, 0, 100);
                if (@mod(random_num, 8) != 0) {
                    const tile_data = tiles.TileData.init(
                        getNeighborCount(
                            @intCast(x), 
                            @intCast(y), 
                        ),
                        Vec2{.x = @floatFromInt(x), .y = @floatFromInt(y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, 0); 
                    try tiles.tile_list.append(tile); 
                } else {
                    random_num = r.random().intRangeLessThan(u8, 1, 16);
                    const tile_data = tiles.TileData.init(
                        getNeighborCount(
                            @intCast(x), 
                            @intCast(y), 
                        ),
                        Vec2{.x = @floatFromInt(x), .y = @floatFromInt(y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, random_num); 
                    try tiles.tile_list.append(tile); 
                }
            }
        }
    }
}

fn mapCleanup() void {
    for (map, 0..) |row, x| {
        for (0..row.len) |y| {
            const neighbor_count = getNeighborCount(@intCast(x), @intCast(y)); 
            if (neighbor_count > 4) {
                map[x][y] = SOLID; 
            }

            if (x < 16 or y < 16 or x > MAP_SIZE - 16 or y > MAP_SIZE - 16) {
                map[x][y] = WATER; 
            }
        }
    }
}

fn lazyFloodFill() !void {
    while (tile_deque.len() > 0) {
        const coordinate = tile_deque.popFront(); 
        map[@intCast(coordinate.?.x)][@intCast(coordinate.?.y)] = SOLID; 
        const check_neighbors: bool = fillOrNot(); 
        if (check_neighbors == true) {
            try getNeighborsForFloodFill(coordinate.?.x, coordinate.?.y); 
        } else {
            map[@intCast(coordinate.?.x)][@intCast(coordinate.?.y)] = WATER; 
        } 

        CHANCE *= DECAY_FACTOR; 
    }

    CHANCE = 100; 
}


fn fillOrNot() bool {
    var filled = false; 
    const random_num: u8 = r.random().intRangeLessThan(u8, 0, 100); 
    if (@as(f32, @floatFromInt(random_num)) <= CHANCE) filled = true; 
    return filled; 
}

fn getNeighborsForFloodFill(tile_x: i32, tile_y: i32) !void {
    const left: iVec2 = .{.x = tile_x - 1, .y = tile_y};  
    const right: iVec2 = .{.x = tile_x + 1, .y = tile_y}; 
    const up: iVec2 = .{.x = tile_x, .y = tile_y - 1}; 
    const down: iVec2 = .{.x = tile_x, .y = tile_y + 1}; 
    
    const left_exists: bool = vectorHashmap.contains(left); 
    const right_exists: bool = vectorHashmap.contains(right); 
    const up_exists: bool = vectorHashmap.contains(up); 
    const down_exists: bool = vectorHashmap.contains(down); 
    
    if (left.x >= 0 and left_exists == true) {
        const left_visted: bool = vectorHashmap.get(left).?; 
        if (left_visted == false) {
            try tile_deque.pushBack(left); 
            try vectorHashmap.put(left, true);
        }
    }

    if (right.x <= MAP_SIZE and right_exists == true) {
        const right_visted: bool = vectorHashmap.get(right).?; 
        if (right_visted == false) {
            try tile_deque.pushBack(right); 
            try vectorHashmap.put(right, true); 
        }
    }

    if (up.y >= 0 and up_exists == true) {
        const up_visited: bool = vectorHashmap.get(up).?; 
        if (up_visited == false) {
            try tile_deque.pushBack(up); 
            try vectorHashmap.put(up, true); 
        }
    }

    if (down.y <= MAP_SIZE and down_exists == true) {
        const down_visited: bool = vectorHashmap.get(down).?; 
        if (down_visited == false) {
            try tile_deque.pushBack(down); 
            try vectorHashmap.put(down, true); 
        }
    }
}

fn getNeighborCount(tile_x: i16, tile_y: i16) i16 {
    var count: i16 = 0;
    var neighbor_x: i16 = undefined;
    var neighbor_y: i16 = undefined;

    neighbor_x = tile_x - 1;
    while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
        neighbor_y = tile_y - 1;
        while(neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
            if (neighbor_x >= 0 and neighbor_x < MAP_SIZE
                and neighbor_y >= 0 and neighbor_y < MAP_SIZE) {
                if (neighbor_x != tile_x or neighbor_y != tile_y) {
                    count += map[@intCast(neighbor_x)][@intCast(neighbor_y)];
                }
            }
        }
    }
    return count;
}

fn getCellToTile(tile_x: i32, tile_y: i32) tiles.TilePlacement {
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
    if (tile_x == 52 and tile_y == 17) {
        std.debug.print("X: {}, Y: {}, COUNTER: {} PLACEMENT: {any} \n", .{tile_x, tile_y, placement_counter, tile_placement}); 
    }
    return tile_placement;
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
        else => tiles.TilePlacement.MIDDLE,
    };

    return placement;
}

fn placementToTileId(tile_data: tiles.TilePlacement) u8 {
    //get the neighbor count of the tile
    return tiles.tile_map_placement_data.get(tile_data).?;
}

fn getLocalNeighborsAsArray(tile_x: i32, tile_y: i32) [8]Vec2 {
    var return_tiles: [8]Vec2 = undefined;
    var iterator: u8 = 0;

    var neighbor_x: i32 = tile_x - 1;
    while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
        var neighbor_y: i32 = tile_y - 1;
        while (neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
            if (neighbor_x != tile_x or neighbor_y != tile_y) {
                if (neighbor_x >= 0 and neighbor_x < MAP_SIZE
                and neighbor_y >= 0 and neighbor_y < MAP_SIZE) {
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

