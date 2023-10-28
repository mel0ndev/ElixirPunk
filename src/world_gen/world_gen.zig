const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("./tiles.zig"); 
const player = @import("../entities/player.zig"); 
const utils = @import("../utils/utils.zig"); 
//const foliage = @import("./foliage.zig"); 
//const interactables = @import("../entities/interactables.zig"); 
//TODO: seed can be generated at world generation
var r  = std.rand.DefaultPrng.init(0); 
const Texture2D = raylib.Texture2D; 
const Vec2 = raylib.Vector2; 
const iVec2 = utils.iVec2; 
 
//DEBUG MENU OPTIONS
pub var DEBUG_MODE_NEIGHBORS: bool = false; 
pub var DEBUG_MODE_TILE_POS: bool = false; 

//chunks are therefore 64x64 tiles
const CHUNK_SIZE: u32 = 64; 
const CHUNK_LOAD_DISTANCE: u32 = 16;  //tiles away from chunk border
var chunk: [CHUNK_SIZE][CHUNK_SIZE]u8 = undefined; 

//puts all the loaded chunks on the heap
var chunk_list: std.ArrayList(*Chunk) = undefined; 
var chunk_map: std.AutoHashMap(iVec2, *Chunk) = undefined; 

const WATER: u8 = 0; 
const SOLID: u8 = 1; 
const GRASS_CHANCE: u8 = 40; 

const MaxTiles = struct {
	max_x: i32,
	min_x: i32,
	max_y: i32,
	min_y: i32,
}; 

pub const Chunk = struct {
    position: iVec2, 
    tile_list: std.ArrayList(tiles.Tile),
    max_tiles: MaxTiles,

    pub fn init(
        alloc: std.mem.Allocator,
        position: iVec2,
	max_tiles: MaxTiles,
    ) !*Chunk {
        var c = try alloc.create(Chunk); 
         c.* = Chunk{
            .position = position,
            .tile_list = std.ArrayList(tiles.Tile).init(alloc),
	    .max_tiles = max_tiles,
        };  

        return c; 
    }
    
    //zig doesn't like this? idk, when I try to use it, it says that it doesn't exist 
    //keeping it here for now in case I find a way to actually use it
    pub fn deinit(alloc: std.mem.Allocator, self: *Chunk) void {
        _ = alloc; 
        self.tile_list.deinit();  
    }
}; 

const ChunkSide = enum {
    POS_X, 
    NEG_X, 
    POS_Y,
    NEG_Y,
}; 

pub fn initMap(alloc: std.mem.Allocator) !void {
    //create file basic file
    _ = try createChunkList(alloc);
    _ = try createChunkMap(alloc); 
    //TODO:
    //check if file has already been created, if it is, load it, if not, create it
    var file = createChunkFile(alloc, 0, 0) catch |err| 
        switch (err) {
            error.PathAlreadyExists => {
                try tiles.initTiles(alloc);
                try loadSavedChunk(alloc, .{.x = 0, .y = 0}); 
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
    //
    var new_chunk = try convertToTiles(alloc, 0, 0, iVec2{.x = 0, .y = 0}, null, null); 
    try chunk_list.append(new_chunk); 
    try chunk_map.putNoClobber(new_chunk.position, new_chunk); 

    //save converted data to file
    try std.json.stringify(
        tiles.TileList{.tilesFromSlice = new_chunk.tile_list.items}, 
        .{}, 
        file.writer()
    ); 
		
}



pub fn update(alloc: std.mem.Allocator) !void {
    //tiles.update();
    drawChunks(); 
    const player_position = player.getPlayerToTilePosition(); 
    const current_chunk = player.getPlayerToChunkPosition(); 
    try createNewChunk(alloc, player_position, current_chunk); 
}

pub fn deinitMap(alloc: std.mem.Allocator) void {
    tiles.deinitTiles(); 

    for (chunk_list.items) |c| {
        c.tile_list.deinit(); 
        alloc.destroy(c); 
    }

    chunk_list.deinit(); 
    chunk_map.deinit(); 
}

fn drawChunks() void {
    for (chunk_list.items) |c| {
        tiles.drawTiles(&c.*); 
    }
}

fn createChunkList(alloc: std.mem.Allocator) !*std.ArrayList(*Chunk) {
    chunk_list = std.ArrayList(*Chunk).init(alloc); 
    return &chunk_list;  
}

fn createChunkMap(alloc: std.mem.Allocator) !*std.AutoHashMap(iVec2, *Chunk) {
	chunk_map = std.AutoHashMap(iVec2, *Chunk).init(alloc); 
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

fn loadSavedChunk(alloc: std.mem.Allocator, chunk_pos: iVec2) !void {
    const chunk_x = chunk_pos.x; 
    const chunk_y = chunk_pos.y; 

    const chunk_file_name = try std.fmt.allocPrint(
        alloc, 
        "src/map/chunk_x{d}_y{d}.json", 
        .{chunk_x, chunk_y}
    ); 
    defer alloc.free(chunk_file_name); 

    const file = try std.fs.cwd().openFile(
        chunk_file_name,
        .{}
    );
    defer file.close(); 
       
    const data = try deserializeJSONMapFile(
        alloc,
        file,
    );
    defer alloc.free(data); 

    const chunk_maxes = getMaxAndMinForChunk(chunk_pos); 
    var new_chunk = try Chunk.init(alloc, chunk_pos, chunk_maxes);  
    try new_chunk.tile_list.appendSlice(data); 

    try chunk_list.append(new_chunk); 
    try chunk_map.put(chunk_pos, new_chunk); 
}

//this is player position in TILES not f32
fn createNewChunk(
        alloc: std.mem.Allocator, 
        player_position: Vec2,
        current_chunk: iVec2,
    ) !void {

    const chunk_maxes = getMaxAndMinForChunk(current_chunk); 
    
    if (@as(i32, @intFromFloat(player_position.x)) > chunk_maxes.max_x - CHUNK_LOAD_DISTANCE) {
        //check if current chunk data exists
        //if it does, we load it to next_chunk_list
        //if it does not, we generate it
        var new_file = createChunkFile(
            alloc, 
            current_chunk.x + 1,
            current_chunk.y
        ) catch |e| 
            switch (e) {
                error.PathAlreadyExists => {
                    const _chunk = chunk_map.get(.{.x = current_chunk.x + 1, .y = current_chunk.y}); 
                    if (_chunk) |c| {
                        _ = c;
                        return;     
                    } else {
                        try loadSavedChunk(alloc, .{.x = current_chunk.x + 1, .y = current_chunk.y}); 
                        return; 
                    }
                }, 
                else => { 
                    return e; 
                },
            };
        defer new_file.close(); 
        
	//the side tiles here are for the players current position, which on generation, is the chunk the player is currently in
        var old_chunk = getChunk(current_chunk); 
	const adjacent_chunk_tiles = getSideTiles(old_chunk, ChunkSide.POS_X, chunk_maxes.max_x - 1); 
        try generateChunkData(adjacent_chunk_tiles, ChunkSide.POS_X);     

        const new_chunk_position = iVec2{.x = current_chunk.x + 1, .y = current_chunk.y};
	var new_chunk = try convertToTiles(alloc, @intCast(new_chunk_position.x * 64), 0, new_chunk_position, adjacent_chunk_tiles, ChunkSide.POS_X); 

        try chunk_list.append(new_chunk); 
        try chunk_map.putNoClobber(new_chunk_position, new_chunk); 

	//save converted data to file
        //on slower PCs this is horribly slow. move somewhere else when shit is working better 
    	try std.json.stringify(
    	    tiles.TileList{.tilesFromSlice = new_chunk.tile_list.items}, 
    	    .{}, 
    	    new_file.writer()
    	); 

        //this may be easier to do if new tile lists are separated into chunks instead of tiles
        const new_tile_border = getSideTiles(new_chunk, ChunkSide.NEG_X, new_chunk.max_tiles.min_x);  
        try recountAndRedrawChunkEdges(alloc, old_chunk, adjacent_chunk_tiles, new_tile_border); 
    }
        
    //negative x direction
    if (@as(i32, @intFromFloat(player_position.x)) < chunk_maxes.min_x + CHUNK_LOAD_DISTANCE) {
    }
    
    //positive y direction
    if (@as(i32, @intFromFloat(player_position.y)) > chunk_maxes.max_y - CHUNK_LOAD_DISTANCE) {
    }
    
    //negative y direction
    if (@as(i32, @intFromFloat(player_position.y)) < chunk_maxes.min_y + CHUNK_LOAD_DISTANCE) {
    }
} 

//gets the tiles of the side we're generating a new chunk for 
fn getSideTiles(adjacent_chunk: *Chunk, chunk_side: ChunkSide, max_or_min: i32) [64]tiles.Tile {
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

fn getMaxAndMinForChunk(chunk_pos: iVec2) MaxTiles {
    const max_chunk_x: i32 = @as(i32, CHUNK_SIZE) * chunk_pos.x + CHUNK_SIZE;  
    const max_chunk_y: i32 = @as(i32, CHUNK_SIZE) * chunk_pos.y + CHUNK_SIZE; 
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
    		    switch(chunk_side.?) {
                        ChunkSide.POS_X => {
		        if (x == 0) {
			    if (chunk_tiles[y].tile_id < 16) {
			        chunk[x][y] = SOLID; 
			    } else {
			        chunk[x][y] = WATER; 
			    }
			} 

			if (x != 0) {
                            if (@mod(random_num, 10) == 0) {
                                chunk[x][y] = WATER; 
                            } else {
			        chunk[x][y] = if (random_num < GRASS_CHANCE) SOLID else WATER; 	
                            }
		        }
                    },
                    else => return,
		} //end switch
	    } else { //on initialize chunk 0, 0
                if (@mod(random_num, 15) == 0) {
                    chunk[x][y] = WATER; 
                } else {
                    chunk[x][y] = if (random_num < GRASS_CHANCE) SOLID else WATER;  
                }
            } 
        }
    }

    var n: usize = 0; 
    while (n < 5) : (n += 1) {
        iterateChunkGen(adjacent_chunk_tiles, chunk_side); 
    }

    chunkCleanup(adjacent_chunk_tiles, chunk_side); 
}

fn chunkCleanup(maybe_adjacent_chunk_tiles: ?[64]tiles.Tile, chunk_side: ?ChunkSide) void {
    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
                const neighbor_count = getNeighborCount(
		    @intCast(x),
		    @intCast(y),
		    maybe_adjacent_chunk_tiles,
		    chunk_side,
                    false
		); 
            if (chunk[x][y] == WATER and neighbor_count == 6) {
                chunk[x][y] = SOLID; 
            }
        }
    }
}

//TODO: check neighbors on chunk borders
fn iterateChunkGen(maybe_adjacent_chunk_tiles: ?[64]tiles.Tile, chunk_side: ?ChunkSide) void {
    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            var neighbor_data: i32 = getNeighborCount(
	        @intCast(x), 
	        @intCast(y),
	        maybe_adjacent_chunk_tiles,
	        chunk_side,
                false,
            ); 

	    if (maybe_adjacent_chunk_tiles) |chunk_tiles| {
	        //if we do, check the side
    		    switch(chunk_side.?) {
                        ChunkSide.POS_X => {
		        if (x == 0) {
			    if (chunk_tiles[y].tile_id < 16) {
			        chunk[x][y] = SOLID; 
			    } else {
			        chunk[x][y] = WATER; 
			    }
			} 

			if (x != 0) {
                            if (neighbor_data > 3) {
                                chunk[x][y] = SOLID; 
                            } else {
                                chunk[x][y] = WATER; 
                            }
		        }
                    },
                    ChunkSide.NEG_X => {
		        if (x == 63) {
			    if (chunk_tiles[y].tile_id < 16) {
			        chunk[x][y] = SOLID; 
			    } else {
			        chunk[x][y] = WATER; 
			    }
			} 

			if (x != 63) {
                            if (neighbor_data > 3) {
                                chunk[x][y] = SOLID; 
                            } else {
                                chunk[x][y] = WATER; 
                            }
		        }
                
                    },
                    else => return,
		} //end switch
	    } else { //on initialize chunk 0, 0
                if (neighbor_data > 3) {
                    chunk[x][y] = SOLID; 
                } else {
                    chunk[x][y] = WATER; 
                }
            } 
        }
    }
}

fn convertToTiles(
	alloc: std.mem.Allocator,
	chunk_x: usize,
	chunk_y: usize,
        chunk_pos: iVec2,
	maybe_adjacent_chunk_tiles: ?[64]tiles.Tile,
	chunk_side: ?ChunkSide
    ) !*Chunk {

    const max_tiles = getMaxAndMinForChunk(chunk_pos); 
    var new_chunk = try Chunk.init(alloc, chunk_pos, max_tiles); 

    for (0..CHUNK_SIZE) |x| {
        for (0..CHUNK_SIZE) |y| {
            if (chunk[x][y] == WATER) {
                const neighbor_count = getNeighborCount(
		    @intCast(x),
		    @intCast(y),
		    maybe_adjacent_chunk_tiles,
		    chunk_side,
                    false
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
                try new_chunk.tile_list.append(tile); 

            } else if (chunk[x][y] == SOLID) {
                var random_num: u8 = r.random().intRangeLessThan(u8, 0, 50);

                if (@mod(random_num, 20) == 0) {

                    random_num = r.random().intRangeLessThan(u8, 1, 16);
                    const tile_data = tiles.TileData.init(
                        getNeighborCount(
                            @intCast(x), 
                            @intCast(y), 
                            maybe_adjacent_chunk_tiles, 
                            chunk_side,
                            false
                        ),
                        Vec2{.x = @floatFromInt(x + chunk_x), .y = @floatFromInt(y + chunk_y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, random_num); 
                    try new_chunk.tile_list.append(tile); 

                } else {

                    const tile_data = tiles.TileData.init(
                        getNeighborCount(
                            @intCast(x), 
                            @intCast(y), 
                            maybe_adjacent_chunk_tiles,
                            chunk_side,
                            false
                        ),
                        Vec2{.x = @floatFromInt(x + chunk_x), .y = @floatFromInt(y + chunk_y)}
                    );  
                    const tile = tiles.Tile.init(tile_data, 0); 
                    try new_chunk.tile_list.append(tile); 
                }
            }
        }
    }
		
    return new_chunk; 
}

fn placementToTileId(tile_data: tiles.TilePlacement) u8 {
    //get the neighbor count of the tile
    return tiles.tile_map_placement_data.get(tile_data).?; 
}

//get the local neighbors in a slice, iterate through them, assigning the index + 1 as the counter 
//the total sum returned is our indication of how the tile needs to be placed
//NOTE: this will only work for now, if we wanted to include, say, sand later, this function will have to be adapted
fn getCellToTile(tile_x: i32, tile_y: i32) tiles.TilePlacement {
    const neighbors = getLocalNeighborsAsArray(tile_x, tile_y); 
    var placement_counter: u32 = 0; 
    //convert neighbor data into tile data 
    for (neighbors, 0..) |pos, i| {
        //if a neighbor is a grass tile
        const casted_i: u32 = @intCast(i); 
        if (chunk[@intFromFloat(pos.x)][@intFromFloat(pos.y)] == 1) {
            //TODO: depending on where the 1s and 0s are, we can get the side?
            if (i == 1 or i == 3 or i == 4 or i == 6) { 
                const add = getPlacementNumber(casted_i); 
                placement_counter += add;  
            } 
        }
    }

    const tile_placement = assignPlacement(placement_counter); 
    return tile_placement; 
}

//fn getCellToTileDebug(tile_x: i32, tile_y: i32) u32 {
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
	tile_x: i32, 
	tile_y: i32,
	maybe_adjacent_chunk_tiles: ?[64]tiles.Tile,
	chunk_side: ?ChunkSide,
        recount: bool
	) i32 {
		
    var count: i32 = 0;
    var neighbor_x: i32 = undefined; 
    var neighbor_y: i32 = undefined; 


    //this is absolutely fucked but it works and I'm not changing it
    if (chunk_side) |side_not_null| {
        var side_tiles = maybe_adjacent_chunk_tiles.?; 
        switch (side_not_null) {
            //this is working, but the other edge now needs to update as well, and the tiles need to be redrawn
            ChunkSide.POS_X => {

            neighbor_x = tile_x - 1; 
            while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
                neighbor_y = tile_y - 1;
                while(neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
                    if (neighbor_x < 0 and neighbor_y < CHUNK_SIZE and neighbor_y >= 0) {
            	    const tile_id = side_tiles[@intCast(neighbor_y)].tile_id; 
            	    if (tile_id < 16) count += 1; 
                } else if (neighbor_x >= 0 and neighbor_x < CHUNK_SIZE
                and neighbor_y >= 0 and neighbor_y < CHUNK_SIZE) {
                    if (neighbor_x != tile_x or neighbor_y != tile_y) {
                        if (recount == false) {
                            if (chunk[@intCast(neighbor_x)][@intCast(neighbor_y)] == 1) {
                                count += 1;
                            }
                        } else {
                            var current_chunk = getChunk(player.getPlayerToChunkPosition()); 
                            const t = getTileFromChunk(current_chunk, neighbor_x, neighbor_y); 
                            if (t.tile_id < 16) count += 1; 
                        }
                    }
                }
            }
        }
            return count; 

        }, 
        ChunkSide.NEG_X => {

            neighbor_x = tile_x - 1; 
            while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
                neighbor_y = tile_y - 1;
                while(neighbor_y <= tile_y + 1) : (neighbor_y += 1) {
                    if (neighbor_x >= CHUNK_SIZE and neighbor_y < CHUNK_SIZE and neighbor_y >= 0) {
            	    const tile_id = side_tiles[@intCast(neighbor_y)].tile_id; 
            	    if (tile_id < 16) {
            	        count += 1; 
            	    }
                } else if (neighbor_x >= 0 and neighbor_x < CHUNK_SIZE
                and neighbor_y >= 0 and neighbor_y < CHUNK_SIZE) {
                    if (neighbor_x != tile_x or neighbor_y != tile_y) {
                        if (recount == false) {
                            if (chunk[@intCast(neighbor_x)][@intCast(neighbor_y)] == 1) {
                                count += 1;
                            }
                        } else {
                            var current_chunk = getChunk(player.getPlayerToChunkPosition()); 
                            const t = getTileFromChunk(current_chunk, neighbor_x, neighbor_y); 
                            if (t.tile_id < 16) count += 1; 
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
    } else {
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

    return count;
}

//crash if chunk is not found (this shouldn't happen)
fn getChunk(chunk_pos: iVec2) *Chunk {
    return chunk_map.get(chunk_pos).?;  
}

//at the end of new chunk generation, we need to redraw the old chunk to match the new one 
//we get the sides for the old chunk, which we already have,
//and we compare it to the new chunk we've just generated
//then we get a new neighbor count for the old chunk, and then redraw the tiles based on the new count
fn recountAndRedrawChunkEdges(
        alloc: std.mem.Allocator,
        old_chunk: *Chunk,
        old_chunk_border: [64]tiles.Tile,
        new_chunk_border: [64]tiles.Tile
    ) !void {
    //check side, for now we hardcode NEG_X
    for (old_chunk_border) |old_chunk_tile| {
        const new_count: i32 = getNeighborCount(
            @as(i32, @intFromFloat(old_chunk_tile.tile_data.pos.x)),
            @as(i32, @intFromFloat(old_chunk_tile.tile_data.pos.y)),
            new_chunk_border,
            ChunkSide.NEG_X,
            true
        ); 
        
        for (old_chunk.tile_list.items) |*tile| {
            if (tile.tile_data.pos.x == old_chunk_tile.tile_data.pos.x and
                tile.tile_data.pos.y == old_chunk_tile.tile_data.pos.y) {
                tile.*.tile_data.count = new_count;  
            }
        }
    }

    //now we have to clear the file, and then rewrite the new data into it
    const chunk_x: i32 = old_chunk.position.x; 
    const chunk_y: i32 = old_chunk.position.y; 
    const chunk_file_name = try std.fmt.allocPrint(
        alloc, 
        "src/map/chunk_x{d}_y{d}.json", 
        .{chunk_x, chunk_y}
    ); 
    defer alloc.free(chunk_file_name); 
         
    const file = try std.fs.cwd().openFile(
        chunk_file_name,
        .{.mode = .write_only}
    );
    defer file.close();

    try std.json.stringify(
    	tiles.TileList{.tilesFromSlice = old_chunk.tile_list.items}, 
    	.{}, 
    	file.writer()
    ); 
}


fn getLocalNeighborsAsArray(tile_x: i32, tile_y: i32) [8]Vec2 {
    var return_tiles: [8]Vec2 = undefined; 
    var iterator: u8 = 0;  

    var neighbor_x: i32 = tile_x - 1;  
    while (neighbor_x <= tile_x + 1) : (neighbor_x += 1) {
        var neighbor_y: i32 = tile_y - 1; 
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
    const data = try file.readToEndAlloc(alloc, 700000); 
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

fn getTileFromChunk(chunk_to_search: *Chunk, x: i32, y: i32) tiles.Tile {
    const casted_x: f32 = @floatFromInt(x); 
    const casted_y: f32 = @floatFromInt(y); 
    var return_tile: tiles.Tile = undefined; 
    for (chunk_to_search.tile_list.items) |tile_in_chunk| {
        if (casted_x == tile_in_chunk.tile_data.pos.x and 
            casted_y == tile_in_chunk.tile_data.pos.y) {
            return_tile = tile_in_chunk; 
            break; 
        }
    }

    return return_tile; 
}



