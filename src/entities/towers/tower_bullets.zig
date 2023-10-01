const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const math = @import("../../utils/math.zig"); 
const enemies = @import("../enemies.zig"); 
const towers = @import("./towers.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;
const Camera2D = raylib.Camera2D; 

var tower_bullet_list: std.ArrayList(TowerBullet) = undefined; 

pub fn initTowerBullets(alloc: std.mem.Allocator) !void {
    _ = try createTowerBulletList(); 
}

pub fn update(delta_time: f32) void {
    checkEnemyCollisionWithBullet(&towers.enemy_list); 
    drawBullets(); 
    moveBullets(delta_time); 
    cleanUpBullets(); 
}

pub fn deinitTowerBullets() void {
    tower_bullet_list.deinit(); 
}

pub const TowerBullet = struct {
    
    rect: Rect,
    direction: Vec2, 
    speed: f32,
    parent: *Tower,
    alive: bool = true,

    pub fn init(
        rect: Rect, 
        parent: *towers.Tower, 
        direction: Vec2, 
        speed: f32
        ) TowerBullet {
        var tb = TowerBullet{
            .rect = rect, 
            .direction = direction,
            .parent = parent,
            .speed = speed,
        };

        return tb; 
    }
};


fn createTowerBulletList(alloc: std.mem.Allocator) !std.ArrayList(TowerBullet) {
    tower_bullet_list = std.ArrayList(TowerBullet).init(alloc); 
    return tower_bullet_list; 
}

fn shootBulletFromTower(tower: *Tower, enemy_pos: Vec2) !void {
        const tower_pos: Vec2 = .{.x = tower.sprite.rect.x, .y = tower.sprite.rect.y}; 
        var dx = enemy_pos.x - tower_pos.x; 
        var dy = enemy_pos.y - tower_pos.y; 
        const length: f32 = @sqrt(dx * dx + dy * dy);    
        dx /= length; 
        dy /= length; 

        var tower_bullet = TowerBullet.init(
            Rect{
                .x = tower_pos.x,
                .y = tower_pos.y, 
                .width = 10,
                .height = 10,
            },
            tower,
            .{.x = dx, .y = dy},
            2.0
        ); 

        try tower_bullet_list.append(tower_bullet); 
}

fn cleanUpBullets() void {
    for (tower_bullet_list.items, 0..) |*tower_bullet, i| {
        if (tower_bullet.alive == false or tower_bullet.parent.target.x == 40000) {
            _ = tower_bullet_list.swapRemove(i); 
            break; 
        }
    }
}

fn checkEnemyCollisionWithBullet(enemy_list: *std.MultiArrayList(enemies.BasicEnemy)) void {
    for (tower_bullet_list.items) |*tower_bullet| {
        for (enemy_list.items(.rect), enemy_list.items(.alive)) |enemy, *alive| {
            var is_colliding: bool = 
                raylib.CheckCollisionRecs(tower_bullet.rect, enemy); 
            if (is_colliding == true) {
                alive.* = false; 
                tower_bullet.alive = false; 
            }
        } 
    }
}

fn moveBullets(delta_time: f32) void {
    for (tower_bullet_list.items) |*tower_bullet| {
        const current_pos: Vec2 = 
            .{.x = tower_bullet.rect.x, .y = tower_bullet.rect.y}; 
        const track_vector = math.track(current_pos, tower_bullet.parent.target); 
        tower_bullet.speed += std.math.atan2(f32, tower_bullet.speed, 10.0); 
        tower_bullet.rect.x += (track_vector.x * tower_bullet.speed) * delta_time; 
        tower_bullet.rect.y += (track_vector.y * tower_bullet.speed) * delta_time; 
    }
}

fn drawBullets() void {
    for (tower_bullet_list.items) |tower_bullet| {
        raylib.DrawRectangleRec(tower_bullet.rect, raylib.PURPLE); 
    }
}
