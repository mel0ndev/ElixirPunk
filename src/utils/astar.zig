const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const tiles = @import("../world_gen/tiles.zig");
const enemies = @import("../entities/enemies/basic_enemy.zig");
const world = @import("../world_gen/world_gen.zig");
const math = @import("../utils/math.zig"); 
const utils = @import("../utils/utils.zig"); 
const Vec2 = raylib.Vector2;
const Rect = raylib.Rectangle;

//do i need this?
pub const Node = struct {
    tile: *tiles.Tile,
    parent: ?*Node,
    visited: bool = false,
    f: i32 = 0,
    g: i32 = 0,
    h: i32 = 0,

    pub fn init(tile_x: f32, tile_y: f32) Node {
        const tile = tiles.getTileFromTileList(tile_x, tile_y);
        return Node{ .tile = tile, .parent = undefined };
    }
};

pub fn pathfind(enemy: *enemies.BasicEnemy, starting_pos: Vec2, ending_pos: Vec2) !void {
    var open_set = &enemy.open_set; 
    var closed_set = &enemy.closed_set; 
    const starting_node = Node.init(starting_pos.x / 32, starting_pos.y / 32); 
    const ending_node = Node.init(ending_pos.x / 32, ending_pos.y / 32); 

    if (open_set.items.len > 0) {
        var winner: usize = 0;
        for (0.., open_set.items) |i, node| {
            if (node.f < open_set.items[winner].f or node.f == open_set.items[winner].f and open_set.items[winner].h < node.h) {
                winner = i; //remember this is not a node yet, just an index 
            }
        }
        
        //convert index to node
        var currentNode: Node = open_set.items[winner]; 
        if (open_set.items[winner].tile.tile_data.pos.x == ending_pos.x and 
            open_set.items[winner].tile.tile_data.pos.y == ending_pos.y) {
            std.debug.print("FOUND", .{}); 
            try retracePath(enemy, starting_node, ending_node); 
            return; 
        }

        _ = open_set.orderedRemove(winner); 
        try closed_set.append(currentNode);  

        const neighbors = world.getLocalNeighborsAsArray(
            @as(i32, @intFromFloat(currentNode.tile.tile_data.pos.x)),
            @as(i32, @intFromFloat(currentNode.tile.tile_data.pos.y))
        ); 
        for (neighbors) |neighbor| {
            var newNeighborNode = Node.init(neighbor.x, neighbor.y); 
            const tile_metadata = tiles.getTileFromTileList(neighbor.x, neighbor.y); 
            const exists = utils.containsVec(closed_set.items, newNeighborNode); 
            if (exists == false and tile_metadata.tile_id > 16) {
                const costToNeighbor = currentNode.g + getDistance(currentNode.tile.tile_data.pos, neighbor); 
                if (costToNeighbor < newNeighborNode.g or utils.containsVec(open_set.items, newNeighborNode) == false) {
                    newNeighborNode.g = costToNeighbor; 
                    newNeighborNode.h = getDistance(neighbor, ending_pos); 
                    newNeighborNode.f = newNeighborNode.g + newNeighborNode.h; 
                    newNeighborNode.parent = &currentNode; 

                    if (utils.containsVec(open_set.items, newNeighborNode) == false) {
                        try open_set.append(newNeighborNode); 
                        std.debug.print("LENGTH: {}\n", .{open_set.items.len}); 
                    }
                }
            }
        }
    }
}

fn retracePath(enemy: *enemies.BasicEnemy, starting_node: Node, ending_node: Node) !void {
    var current_node = ending_node; 

    while (current_node.tile.tile_data.pos.x != starting_node.tile.tile_data.pos.x and
        current_node.tile.tile_data.pos.y != starting_node.tile.tile_data.pos.y) {
        try enemy.path.append(current_node); 
        current_node = current_node.parent.?.*;   
    }
}

fn getDistance(pos_a: Vec2, pos_b: Vec2) i32 {
    const ax = @as(i32, @intFromFloat(pos_a.x)); 
    const bx = @as(i32, @intFromFloat(pos_b.x)); 
    const ay = @as(i32, @intFromFloat(pos_a.y)); 
    const by = @as(i32, @intFromFloat(pos_b.y)); 


    const dist_x = math.abs(ax - bx); 
    const dist_y = math.abs(ay - by); 

    if (dist_x > dist_y) {
        return 14 * dist_y + 10 * (dist_x - dist_y); 
    }

    return 14 * dist_x + 10 * (dist_y - dist_x);  
}
