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

//puts all the loaded chunks on the heap
var chunk_list: std.ArrayList(Chunk) = undefined; 
var chunk_map: std.AutoHashMap(Vec2, Chunk) = undefined; 

const WATER: u8 = 0; 
const SOLID: u8 = 1; 
const GRASS_CHANCE: u8 = 60; 

pub fn initMap(alloc: std.mem.Allocator) !void {
    //create file basic file
    _ = try createChunkList(alloc); 
		_ = try createChunkMap(alloc); 
    //TODO:
    //check if file has already been created, if it is, load it, if not, create it
    var file = createChunkFile(alloc, 0, 0) catch |err| 
        switch (err) {
            error.PathAlreadyExists => {
                const file = try std.fs.cwd().openFile(
                    "src/map/chunk_x0_y0.json",
                    .{}
                );
                defer file.close(); 
                const data = try deserializeJSONMapFile(
                    alloc,
                    file,
                );
                defer alloc.free(data); 

                try tiles.initTiles(alloc); 
                try tiles.tile_list.appendSlice(data); 
                return; 
            },
            else => return err,
        };
    defer file.close(); 
    //generate map data
    try generateChunkData(null, null); 
    //gen hashmap data
    try tiles.initTiles(alloc); 
    //try foliage.setFoliageMap(); 
    //try interactables.initInteractables(); 
    //  - convert to tilemap
    const new_chunk = try convertToTiles(alloc, 0, 0, null, null); 
		try chunk_list.append(new_chunk); 

    //save converted data to file
    try std.json.stringify(
        tiles.TileList{.tilesFromSlice = tiles.tile_list.items}, 
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
    chunk_list.deinit(); 
		chunk_map.deinit(); 
}

const MaxTiles = struct {
	max_x: i32,
	min_x: i32,
	max_y: i32,
	min_y: i32,
}; 

const Chunk = struct {
    position: Vec2, 
    tile_list: std.ArrayList(tiles.Tile),
		max_tiles: MaxTiles,

    pub fn init(
        alloc: std.mem.Allocator,
        position: Vec2,
				max_tiles: MaxTiles,
    ) !Chunk {
        var c = Chunk{
            .position = position,
            .tile_list = std.ArrayList(tiles.Tile).init(alloc),
						.max_tiles = max_tiles,
        };  

        return c; 
    }

    pub fn deinit(self: *Chunk) void {
        self.tile_list.deinit();  
    }
}; 

const ChunkSide = enum {
    POS_X, 
    NEG_X, 
    POS_Y,
    NEG_Y,
}; 


fn createChunkList(alloc: std.mem.Allocator) !*std.ArrayList(Chunk) {
    chunk_list = std.ArrayList(Chunk).init(alloc); 
    return &chunk_list;  
}

fn createChunkMap(alloc: std.mem.Allocator) !*std.AutoHashMap(Vec2, Chunk) {
	chunk_map = std.AutoHashMap(Vec2, Chunk).init(alloc); 
	return &chunk_map; 
}


fn createChunkFile(alloc: std.mem.Allocator, chunk_x: i32, chunk_y: i32) !std.fs.File {
    const new_chunk_file_name = try std.fmt.allocPrint(
        alloc, 
        "src/map/chunk_x{d}_y{d}.json", 
        .{chunk_x, chunk_y}
    ); 
    defer alloc.free(new_chunk_file_name); 

    var fileOrError = std.fs.cwd().createFile(
        new_chunk_file_name,
        .{ .read = true, .exclusive = true } 
    ); 

    return fileOrError; 
}

//this is player position in TILES not f32
fn createNewChunk(
        alloc: std.mem.Allocator, 
        player_position: Vec2,
        current_chunk: Vec2,
    ) !void {

		const chunk_maxes = getMaxAndMinForChunk(current_chunk); 
    
    if (@as(i32, @intFromFloat(player_position.x)) > chunk_maxes.max_x - CHUNK_LOAD_DISTANCE) {
        //check if current chunk data exists
        //if it does, we load it to next_chunk_list
        //if it does not, we generate it
        //std.debug.print("should load next chunk +x direciton\n", .{}); 
        var new_file = createChunkFile(
            alloc, 
            @as(i32, @intFromFloat(current_chunk.x + 1)),
            @as(i32, @intFromFloat(current_chunk.y))
        ) catch |e| 
            switch (e) {
                error.PathAlreadyExists => {
                    return; 
                }, 
                else => { 
                    return e; 
                },
            };
        defer new_file.close(); 
        
			//the side tiles here are for the players current position, which on generation, is the chunk the player is currently in
			const player_chunk_position: Vec2 = player.getPlayerToChunkPosition(); 
			const adjacent_chunk_tiles = getSideTiles(player_chunk_position, ChunkSide.POS_X, chunk_maxes.max_x - 1); 
      try generateChunkData(adjacent_chunk_tiles, ChunkSide.POS_X);     
			try convertToTiles(alloc, (1 * 64), 0, adjacent_chunk_tiles, ChunkSide.POS_X); 

			//save converted data to file
    	try std.json.stringify(
    	    tiles.TileList{.tilesFromSlice = tiles.tile_list.items}, 
    	    .{.whitespace = .indent_1}, 
    	    new_file.writer()
    	); 
			
			//this may be easier to do if new tile lists are separated into chunks instead of tiles
			//TODO: break out max_chunk calculation into a new function
			const next_chunk = Vec2{.x = player_chunk_position.x + 1.0, .y = player_chunk_position.y}; 
			const new_tile_border = getSideTiles(next_chunk, ChunkSide.NEG_X, chunk_maxes.max_x);  
			_ = new_tile_border; 
			//try recountAndRedrawChunkEdges(adjacent_chunk_tiles, 
    }
        
    //negative x direction
    if (@as(i32, @intFromFloat(player_position.x)) < chunk_maxes.min_x + CHUNK_LOAD_DISTANCE) {
        //std.debug.print("should load next chunk -x direciton\n", .{}); 
    }
    
    //positive y direction
    if (@as(i32, @intFromFloat(player_position.y)) > chunk_maxes.max_y - CHUNK_LOAD_DISTANCE) {
        //std.debug.print("should load next chunk +y direciton\n", .{}); 
    }
    
    //negative y direction
    if (@as(i32, @intFromFloat(player_position.y)) < chunk_maxes.min_y + CHUNK_LOAD_DISTANCE) {
        //std.debug.print("should load next chunk -y direciton\n", .{}); 
    }
} 

//gets the tiles of the side we're generating a new chunk for 
fn getSideTiles(adjacent_chunk: Chunk, chunk_side: ChunkSide, max_or_min: i32) [64]tiles.Tile {
    var side_tiles: [64]tiles.Tile = undefined; 
    switch(chunk_side) {
        ChunkSide.POS_X, ChunkSide.NEG_X => {
            var i: usize = 0; 
            for (adjacent_chunk.tile_list.items) |t| {
								//check all positions: x == 63
                if (@as(i32, @intFromFloat(t.tile_data.pos.x)) == max_or_min) {
                    side_tiles[i] = t; 
                    i += 1; 
                }
            }
        }, 
        ChunkSide.POS_Y, ChunkSide.NEG_Y => {
            var i: usize = 0; 
            for (adjacent_chunk.tile_list.items) |t| {
                if (@as(i32, @intFromFloat(t.tile_data.pos.y)) == max_or_min) {
                    side_tiles[i] = t; 
                    i += 1; 
                }
            }
        },
    } 

    return side_tiles; 
}

fn getMaxAndMinForChunk(current_chunk: Vec2) MaxTiles {
    const max_chunk_x: i32 = 
        @as(i32, CHUNK_SIZE) * @as(i32, @intFromFloat(current_chunk.x + 1)); 
    const max_chunk_y: i32 = 
        @as(i32, CHUNK_SIZE) * @as(i32, @intFromFloat(current_chunk.y + 1)); 
    const min_chunk_x: i32 = @as(i32, @intCast(max_chunk_x - CHUNK_SIZE));  
    const min_chunk_y: i32 = @as(i32, @intCast(max_chunk_y - CHUNK_SIZE)); 

		return MaxTiles{
			.max_x = max_chunk_x,
			.min_x = min_chunk_x,
			.max_y = max_chunk_y,
			.min_y = min_chunk_y,
		}; 
}


fn generateChunkData(adjacent_chunk_tiles: ?[64]tiles.Tile, chunk_side: ?ChunkSide) !void {
		
		//TODO: add other directions
		for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            var random_num: u8 = r.random().intRangeLessThan(u8, 0, 100);
						//first check if we have adjacent tiles or not
						if (adjacent_chunk_tiles) |chunk_tiles| {
							//if we do, check the side
							if (chunk_side.? == ChunkSide.POS_X) {
								if (x == 0) {
									std.debug.print("{}\n", .{chunk_tiles[y].tile_id}); 
										if (chunk_tiles[y].tile_id < 16) {
											chunk[x][y] = SOLID; 
										} else {
										chunk[x][y] = WATER; 
										}
								} 
								if (x != 0) {
									chunk[x][y] = if (random_num < GRASS_CHANCE) SOLID else WATER; 	
								}

							}

						}
				}
    }

    var n: usize = 0; 
    while (n < 6) : (n += 1) {
        iterateChunkGen(adjacent_chunk_tiles, chunk_side); 
    }


}

//TODO: check neighbors on chunk borders
fn iterateChunkGen(maybe_adjacent_chunk_tiles: ?[64]tiles.Tile, chunk_side: ?ChunkSide) void {
    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            var neighbor_data: i16 = getNeighborCount(
								@intCast(x), 
								@intCast(y),
								maybe_adjacent_chunk_tiles,
								chunk_side
							); 
            if (neighbor_data > 3) {
                chunk[x][y] = SOLID; 
            } else {
                chunk[x][y] = WATER; 
            }
        }
    }
}

fn convertToTiles(
	alloc: std.mem.Allocator,
	chunk_x: usize,
	chunk_y: usize,
	maybe_adjacent_chunk_tiles: ?[64]tiles.Tile,
	chunk_side: ?ChunkSide
	) !Chunk {
    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            if (chunk[x][y] == WATER) {
                const neighbor_count = getNeighborCount(
										@intCast(x),
										@intCast(y),
										maybe_adjacent_chunk_tiles,
										chunk_side
									); 
                const placement = getCellToTile(
                    @intCast(x), 
                    @intCast(y) 
                ); 
                const tile_id = placementToTileId(placement);
                const tile_data = tiles.TileData.init(
                    neighbor_count,
                    Vec2{.x = @floatFromInt(x + chunk_x), .y = @floatFromInt(y + chunk_y)}
                );  
                const tile = tiles.Tile.init(tile_data, tile_id); 
                try tiles.tile_list.append(tile); 

            } else if (chunk[x][y] == SOLID) {

                var random_num: u8 = r.random().intRangeLessThan(u8, 0, 50);

                if (@mod(random_num, 20) == 0) {

                    random_num = r.random().intRangeLessThan(u8, 1, 16);
                    const tile_data = tiles.TileData.init(
                        getNeighborCount(@intCast(x), @intCast(y), maybe_adjacent_chunk_tiles, chunk_side),
                        Vec2{.x = @floatFromInt(x + chunk_x), .y = @floatFromInt(y + chunk_y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, random_num); 
                    try tiles.tile_list.append(tile); 

                } else {

                    const tile_data = tiles.TileData.init(
                        getNeighborCount(@intCast(x), @intCast(y), maybe_adjacent_chunk_tiles, chunk_side),
                        Vec2{.x = @floatFromInt(x + chunk_x), .y = @floatFromInt(y + chunk_y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, 0); 
                    try tiles.tile_list.append(tile); 
                }
            }
        }
    }
		
		//FIXME: this will cause a leak eventually, we have to free the old list and then create a new one
		//TODO: get the chunk maxes for here
		const new_chunk = Chunk.init(alloc, player.getPlayerToChunkPosition(), ); 
		return new_chunk; 
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

fn getNeighborCount(
	tile_x: i16, 
	tile_y: i16,
	maybe_adjacent_chunk_tiles: ?[64]tiles.Tile,
	chunk_side: ?ChunkSide
	) i16 {
		
    var count: i16 = 0;
    var neighbor_x: i16 = undefined; 
    var neighbor_y: i16 = undefined; 

		var side_tiles = maybe_adjacent_chunk_tiles orelse maybe_adjacent_chunk_tiles.?; 
		var side = chunk_side orelse chunk_side.?; 
		switch (side) {
			//this is working, but the other edge now needs to update as well, and the tiles need to be redrawn
			ChunkSide.POS_X => {
				neighbor_x = tile_x - 1; 
    		while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
    		    neighbor_y = tile_y - 1;
    		    while(neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
							if (neighbor_x < 0 and neighbor_y < CHUNK_SIZE and neighbor_y >= 0) {
								const tile_id = side_tiles[@intCast(neighbor_y)].tile_id; 
								if (tile_id < 16) {
									count += 1; 
								}
							} else if (neighbor_x >= 0 and neighbor_x < CHUNK_SIZE
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
			}, 
			else => {
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
				}
		} 

		return count;
}

//at the end of new chunk generation, we need to redraw the old chunk to match the new one 
//we get the sides for the old chunk, which we already have,
//and then we need to get the sides for the new chunk we've just generated
fn recountAndRedrawChunkEdges(old_chunk_border: [64]tiles.Tile, new_chunk_border: [64]tiles.Tile) !void {
	_ = old_chunk_border; 	
	_ = new_chunk_border; 
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

fn deserializeJSONMapFile(alloc: std.mem.Allocator, file: std.fs.File) ![]tiles.Tile {
    const data = try file.readToEndAlloc(alloc, 623858); 
    defer alloc.free(data); 

    const json = try std.json.parseFromSlice(
        tiles.TileList,
        alloc, 
        data,
        .{}
    );
    defer json.deinit(); 
        
    var json_copy = try alloc.dupe(tiles.Tile, json.value.tilesFromSlice); 
    return json_copy; 
}

