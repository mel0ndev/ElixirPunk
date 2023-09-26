const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const math = @import("../math.zig"); 
const player = @import("./player.zig"); 
const entities = @import("../entities/entities.zig"); 
const enemies = @import("./enemies.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;
const Camera2D = raylib.Camera2D; 

pub const TowerType = enum {
    BASIC,
    FIRE,
}; 

pub const TowerStats = struct {
    damage: f32,
    damage_over_time: f32,
    range: f32,
    cooldown: i64, //in milliseconds
}; 

pub const Tower = struct {
    sprite: entities.Sprite, 
    collider: Rect, 
    range_collider_center: Vec2,
    stats: TowerStats,
    last_shot: i64,
    is_shooting: bool = false, 
    target: Vec2,
    ttype: TowerType,

    fn createTower(
        texture: Texture2D, 
        rect: Rect, 
        collider: Rect,
        origin: Vec2, 
        range_collider_center: Vec2,
        scale: f32,
        ttype: TowerType
        ) Tower {

        //lookup ttype and get towerstats
        var stats = getTowerStats(ttype); 

        var t = Tower{
            .sprite = entities.Sprite{
                .texture = texture,
                .rect = rect,
                .origin = origin,
                .scale = scale,
            },
            .collider = collider,
            .range_collider_center = range_collider_center, 
            .stats = stats,
            .last_shot = undefined,
            .target = undefined,
            .ttype = ttype
        }; 

        return t; 
    } }; 

pub var tower_list: std.ArrayList(Tower) = undefined; 
pub var tower_shooting_list: std.ArrayList(*Tower) = undefined; 
pub var enemy_collision_list: std.ArrayList(bool) = undefined; 
pub var tower_map: std.AutoHashMap(TowerType, Texture2D) = undefined; 

pub fn createTowerList(alloc: std.mem.Allocator) !std.ArrayList(Tower) {
    tower_list = std.ArrayList(Tower).init(alloc); 
    return tower_list; 
} 

pub fn createTowersShootingList(alloc: std.mem.Allocator) !std.ArrayList(*Tower) {
    tower_shooting_list = std.ArrayList(*Tower).init(alloc); 
    return tower_shooting_list; 
}

pub fn createEnemyCollisionList(alloc: std.mem.Allocator) !std.ArrayList(bool) {
    enemy_collision_list = std.ArrayList(bool).init(alloc); 
    return enemy_collision_list; 
}

pub fn createTowerMap(alloc: std.mem.Allocator) !std.AutoHashMap(TowerType, Texture2D) {
    tower_map = std.AutoHashMap(TowerType, Texture2D).init(alloc); 
    return tower_map; 
}

pub fn setTowerMap() !void {
    var basic_tower_texture =
        raylib.LoadTexture("src/world/assets/interactives/tower.png");  
    try tower_map.putNoClobber(TowerType.BASIC, basic_tower_texture); 
}

pub fn generateTowerData(ttype: TowerType, camera: *Camera2D) !void {
    var tower: Tower = undefined; 
    switch (ttype) {
        TowerType.BASIC => {
            const texture = tower_map.get(ttype).?; 
            const texture_width: f32 = @floatFromInt(texture.width); 
            const texture_height: f32 = @floatFromInt(texture.height); 

            const mouse_x: f32 = @floatFromInt(raylib.GetMouseX()); 
            const mouse_y: f32 = @floatFromInt(raylib.GetMouseY()); 
            const mouse_to_world_space: Vec2 = 
                raylib.GetScreenToWorld2D(Vec2{.x = mouse_x, .y = mouse_y}, camera.*); 
            const world_mouse_x: f32 = mouse_to_world_space.x; 
            const world_mouse_y: f32 = mouse_to_world_space.y; 
            
            tower = Tower.createTower(
                texture,
                Rect{.x = world_mouse_x - texture_width,
                     .y = world_mouse_y - texture_height,
                     .width = texture_width,
                     .height = texture_height,
                 }, 
                Rect{.x = world_mouse_x + texture_width - 5.0, 
                     .y = world_mouse_y + texture_height - 12.0,
                     .width = 10,
                     .height = 10,
                },
                Vec2{.x = world_mouse_x,
                      .y = world_mouse_y,
                }, 
                //center of circle collider
                Vec2{.x = world_mouse_x,
                     .y = world_mouse_y + (texture_height / 4),
                },
                2.0,
                TowerType.BASIC
            ); 
        }, 
        else => return,
    }      

    try tower_list.append(tower); 
}

fn getTowerStats(ttype: TowerType) TowerStats {
    var stats: TowerStats = undefined; 
    switch (ttype) {
        TowerType.BASIC => stats = .{
            .damage = 10,
            .damage_over_time = 0,
            .range = 200, 
            .cooldown = 500,
        },
        TowerType.FIRE => stats = .{
            .damage = 15,
            .damage_over_time = 5, 
            .range = 50,
            .cooldown = 1000,
        },
    } 

    return stats; 
}

//function has too much logic? gets stuck when an enemy is range of one tower
pub fn towerShoot() !void {
    for (tower_shooting_list.items) |tower| {
        if (std.time.milliTimestamp() - tower.last_shot > tower.stats.cooldown) {
            std.debug.print("target x: {}   target y: {}\n", .{tower.target.x, tower.target.y}); 
            tower.*.last_shot = std.time.milliTimestamp();  
            try shootBulletFromTower(tower, tower.target); //one space in front
        } else {
            return; 
        }
    }
}

//checks if an enemy enters the towers range, and adds it to the list of shooting towers if it does
pub fn checkEnemyEnterTowerRange(
    enemy_list: *std.MultiArrayList(enemies.BasicEnemy
    )
    ) !void {
    for (tower_list.items) |*tower| {
        for (enemy_list.items(.rect), enemy_list.items(.alive)) |rect, alive| {
            if (alive == true) {
                var enemy_is_in_tower_range: bool = 
                    raylib.CheckCollisionCircleRec(
                        tower.range_collider_center,
                        tower.stats.range,
                        rect
                    );

                try enemy_collision_list.append(enemy_is_in_tower_range); 

                if (enemy_is_in_tower_range == true) {
                    tower.target = .{.x = rect.x, .y = rect.y}; 
                }
            }
            
        }
        //inside only tower loop now
        var enemySlice = try enemy_collision_list.toOwnedSlice(); 
        const res = std.mem.allEqual(bool, enemySlice, false); 
        //if none of the enemies are colliding
        if (res == true) {
            tower.is_shooting = false;  
            tower.target = .{.x = 40000, .y = 40000}; 
        } else {
            const exists = for (tower_shooting_list.items) |t| {
                if (t == tower) break true; 
            } else false;  
            if (exists == false) try tower_shooting_list.append(tower); 
            tower.is_shooting = true;  
        }

        enemy_collision_list.clearAndFree(); 
    }
}

//ok so, what is the problem here?
//we have a list of items, and one of them is being removed. 
//after removal, the length gets reduced by one
pub fn cleanUpTowerShootingList() void {
    for (tower_shooting_list.items, 0..) |tower, i| {
        if (tower.is_shooting == false) {
            _ = tower_shooting_list.swapRemove(i);  
            break; 
        } 
    }
}

pub const TowerBullet = struct {
    
    rect: Rect,
    velocity: Vec2, 
    speed: f32,
    parent: *Tower,
    alive: bool = true,

    pub fn init(rect: Rect, parent: *Tower, velocity: Vec2, speed: f32) TowerBullet {
        var tb = TowerBullet{
            .rect = rect, 
            .velocity = velocity,
            .parent = parent,
            .speed = speed,
        };

        return tb; 
    }
};

var tower_bullet_list: std.ArrayList(TowerBullet) = undefined; 

pub fn createTowerBulletList(alloc: std.mem.Allocator) !std.ArrayList(TowerBullet) {
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

pub fn cleanUpBullets() void {
    for (tower_bullet_list.items, 0..) |*tower_bullet, i| {
        if (tower_bullet.alive == false or tower_bullet.parent.target.x == 40000) {
            _ = tower_bullet_list.swapRemove(i); 
            break; 
        }
    }
}

pub fn checkEnemyCollisionWithBullet(enemy_list: *std.MultiArrayList(enemies.BasicEnemy)) void {
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

pub fn moveBullets(delta_time: f32) void {
    for (tower_bullet_list.items) |*tower_bullet| {
        const current_pos: Vec2 = 
            .{.x = tower_bullet.rect.x, .y = tower_bullet.rect.y}; 
        const track_vector = math.track(current_pos, tower_bullet.parent.target); 
        tower_bullet.speed += std.math.atan2(f32, tower_bullet.speed, 10.0); 
        tower_bullet.rect.x += (track_vector.x * tower_bullet.speed) * delta_time; 
        tower_bullet.rect.y += (track_vector.y * tower_bullet.speed) * delta_time; 
    }
}

pub fn drawBullets() void {
    for (tower_bullet_list.items) |tower_bullet| {
        raylib.DrawRectangleRec(tower_bullet.rect, raylib.PURPLE); 
    }
}

pub fn drawTowerRangeCircle() void {
    for (tower_list.items) |tower| {
        raylib.DrawCircleLines(
            @intFromFloat(tower.range_collider_center.x),
            @intFromFloat(tower.range_collider_center.y),
            tower.stats.range,
            raylib.WHITE
        ); 
    }
}

pub fn addToSpriteList() !void {
    for (tower_list.items) |tower| {
        try entities.entities_list.append(tower.sprite);  
        try entities.collider_list.append(tower.collider); 
    }
}

