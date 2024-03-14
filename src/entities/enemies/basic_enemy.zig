const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const math = @import("../../utils/math.zig"); 
const player = @import("../player.zig"); 
const tiles = @import("../../world_gen/tiles.zig"); 
const world = @import("../../world_gen/world_gen.zig"); 
const astar = @import("../../utils/astar.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const ArrayList = std.ArrayList; 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 

pub var enemy_list: std.ArrayList(BasicEnemy) = undefined; 
pub var spawn_timer: f32 = 5.0; 
var should_spawn: bool = false; 

pub const BasicEnemy = struct {
    rect: Rect,
    speed: f32 = 2.0,
    alive: bool,
    open_set: std.ArrayList(astar.Node),
    closed_set: std.ArrayList(astar.Node), 
    path: std.ArrayList(astar.Node),

    pub fn init(alloc: std.mem.Allocator) !BasicEnemy {
    
        const rand_x: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, world.MAP_SIZE * 32)); 
        const rand_y: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, world.MAP_SIZE * 32)); 
        var enemy = BasicEnemy {
            .rect = Rect {
                .x = rand_x, 
                .y = rand_y, 
                .width = 16,
                .height = 16
            }, 
            .alive = true,
            .open_set = undefined,
            .closed_set = undefined,
            .path = undefined,
        };

        enemy.open_set = std.ArrayList(astar.Node).init(alloc); 
        enemy.closed_set = std.ArrayList(astar.Node).init(alloc); 
        enemy.path = std.ArrayList(astar.Node).init(alloc); 
        const starting_node = astar.Node.init(rand_x / 32, rand_y / 32); 

        try enemy.open_set.append(starting_node); 

        return enemy; 
    }


    pub fn checkEnemyCollision(player_ref: *player.Player) void {
        const player_rect = player.Player.getPlayerRect(player_ref); 
        _ = player_rect; 
        //const enemy_rect = getEnemyRect(); 

        //const overlap: bool = raylib.CheckCollisionRecs(enemy_rect, player_rect);
        //if (overlap == true) {
        //    //TODO: add game over screen
        //    player_ref.alive = false; 
        //}

    }


    pub fn moveEnemy(portal_pos: Vec2) void {
        for (enemy_list.items(.rect), enemy_list.items(.alive)) |*rect, *alive| {
            if (alive.* == true) {
                const current_pos = Vec2{
                    .x = rect.*.x,
                    .y = rect.*.y
                }; 
                const move_vec = math.track(current_pos, portal_pos); 
                rect.*.x += move_vec.x * 2.0;
                rect.*.y += move_vec.y * 2.0; 
            } else {
                rect.*.x = -100000.0; 
                rect.*.y = -10000.0;
            }
        }
    }
    
    pub fn getEnemyRect(self: *BasicEnemy) Rect {
        return self.rect; 
    }
}; 


pub fn enemySpawnTimer() void {
    if (spawn_timer <= 0) {
        for (enemy_list.items(.rect), enemy_list.items(.alive)) |*rect, *alive| {
            if (alive.* == false) {
                const rand_x: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, 1080)); 
                const rand_y: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, 720)); 
                alive.* = true; 
                rect.*.x = rand_x; 
                rect.*.y = rand_y;  
            }  
        }
        spawn_timer = 5.0; 
    }        
}

pub fn addEnemies(alloc: std.mem.Allocator, n: u8) !*std.ArrayList(BasicEnemy) {
    enemy_list = std.ArrayList(BasicEnemy).init(alloc); 
    for (0..n) |_| {
        const e = try BasicEnemy.init(alloc); 
        try enemy_list.append(e); 
    }

    return &enemy_list;
}

pub fn deinitEnemies() void {
    for (enemy_list.items) |*enemy| {
        enemy.open_set.deinit(); 
        enemy.closed_set.deinit(); 
        enemy.path.deinit(); 
    }

    enemy_list.deinit(); 
}

pub fn drawEnemy() void {
    for (enemy_list.items) |*enemy| {
        if (enemy.alive == true) {
            raylib.DrawRectangleRec(enemy.rect, raylib.BLUE); 
        }
    }
}

pub fn pathfindToPortal() !void {
    for (enemy_list.items) |*enemy| {
        try astar.pathfind(
            enemy,
            .{.x = enemy.rect.x, .y = enemy.rect.y}, 
            .{.x = 50, .y = 50}, 
        ); 
    }
}
