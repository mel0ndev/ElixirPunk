const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const math = @import("../math.zig"); 
const player = @import("player.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const ArrayList = std.ArrayList; 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 

pub var enemy_list: std.MultiArrayList(BasicEnemy) = .{}; 
pub var spawn_timer: f32 = 5.0; 
var should_spawn: bool = false; 

pub const BasicEnemy = struct {
    rect: Rect,
    speed: f32 = 2.0,
    alive: bool,

    pub fn init() BasicEnemy {
    
        var rand_x: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, 1080)); 
        var rand_y: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, 736)); 
        var enemy = BasicEnemy {
            .rect = Rect {
                .x = rand_x, 
                .y = rand_y, 
                .width = 16,
                .height = 16
            }, 
            .alive = true,
        };

        return enemy; 
    }

    pub fn addEnemies(alloc: std.mem.Allocator, n: u8) !std.MultiArrayList(BasicEnemy) {
        
        for (0..n) |_| {
            const e = init(); 
            try enemy_list.append(alloc, e); 
        }

        return enemy_list;

    }

    pub fn drawEnemy() void {
        for (enemy_list.items(.rect), enemy_list.items(.alive)) |*rect, *alive| {
            if (alive.* == true) {
                raylib.DrawRectangleRec(rect.*, raylib.BLUE); 
            }
        }
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
                var current_pos = Vec2{
                    .x = rect.*.x,
                    .y = rect.*.y
                }; 
                var move_vec = math.moveTowards(current_pos, portal_pos); 
                rect.*.x = move_vec.x;
                rect.*.y = move_vec.y; 
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
                var rand_x: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, 1080)); 
                var rand_y: f32 = @floatFromInt(r.random().intRangeLessThan(u32, 0, 720)); 
                alive.* = true; 
                rect.*.x = rand_x; 
                rect.*.y = rand_y;  
            }  
        }
        spawn_timer = 5.0; 
    }        
}
