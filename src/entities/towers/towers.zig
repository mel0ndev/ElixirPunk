const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const sprites = @import("../entities/sprites.zig"); 
const enemies = @import("../enemies.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;
const Camera2D = raylib.Camera2D; 

var basic_tower_texture: Texture2D = undefined; 
var tower_list: std.ArrayList(Tower) = undefined; 
var tower_shooting_list: std.ArrayList(*Tower) = undefined; 
//TODO why is enemy collions in the towers file? move into tower struct? 
var enemy_collision_list: std.ArrayList(bool) = undefined; 
var tower_map: std.AutoHashMap(TowerType, Texture2D) = undefined; 

pub fn initTowers(alloc: std.mem.Allocator) !void {
    _ = try createTowerList(alloc);      
    _ = try createTowerMap(alloc); 
    _ = try createTowerShootingList(alloc); 
    _ = try createEnemyCollisionList(alloc);
    try setTowerMap(); 
}

//can take in an enum from states/running to be called in DEBUG_MODE so we can draw colldiders, origins, etc.
//called every frame
pub fn update() !void {
    addToSpriteList(); 
    drawTowerRangeCircle();  
    checkEnemyEnterTowerRange(&enemy_list); 
    try towerShoot(); 
    cleanUpTowerShootingList(); 
}

pub fn deinitTowers() void {
    raylib.UnloadTexture(basic_tower_texture); 
    tower_list.deinit(); 
    tower_shooting_list.deinit(); 
    enemy_collision_list.deinit(); 
    tower_map.deinit(); 
}

const TowerType = enum {
    BASIC,
    FIRE,
}; 

const TowerStats = struct {
    damage: f32,
    damage_over_time: f32,
    range: f32,
    cooldown: i64, //in milliseconds
}; 

const Tower = struct {
    sprite: sprites.Sprite, 
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
            .sprite = sprites.Sprite{
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


fn createTowerList(alloc: std.mem.Allocator) !*std.ArrayList(Tower) {
    tower_list = std.ArrayList(Tower).init(alloc); 
    return &tower_list; 
} 

fn createTowerShootingList(alloc: std.mem.Allocator) !*std.ArrayList(*Tower) {
    tower_shooting_list = std.ArrayList(*Tower).init(alloc); 
    return &tower_shooting_list; 
}

fn createEnemyCollisionList(alloc: std.mem.Allocator) !*std.ArrayList(bool) {
    enemy_collision_list = std.ArrayList(bool).init(alloc); 
    return &enemy_collision_list; 
}

fn createTowerMap(alloc: std.mem.Allocator) !*std.AutoHashMap(TowerType, Texture2D) {
    tower_map = std.AutoHashMap(TowerType, Texture2D).init(alloc); 
    return &tower_map; 
}

fn setTowerMap() !void {
    basic_tower_texture =
        raylib.LoadTexture("src/world/assets/interactives/tower.png");  
    try tower_map.putNoClobber(TowerType.BASIC, basic_tower_texture); 
}

fn generateTowerData(ttype: TowerType, camera: *Camera2D) !void {
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
fn towerShoot() !void {
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
fn checkEnemyEnterTowerRange(
    enemy_list: *std.MultiArrayList(enemies.BasicEnemy)
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
        //TODO: memory leak here
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
        
        //TODO: cleanup slice here
        //alloc.free(enemySlice); 
        enemy_collision_list.clearAndFree(); 
    }
}

fn cleanUpTowerShootingList() void {
    for (tower_shooting_list.items, 0..) |tower, i| {
        if (tower.is_shooting == false) {
            _ = tower_shooting_list.swapRemove(i);  
            break; 
        } 
    }
}

fn drawTowerRangeCircle() void {
    for (tower_list.items) |tower| {
        raylib.DrawCircleLines(
            @intFromFloat(tower.range_collider_center.x),
            @intFromFloat(tower.range_collider_center.y),
            tower.stats.range,
            raylib.WHITE
        ); 
    }
}

fn addToSpriteList() !void {
    for (tower_list.items) |tower| {
        try sprites.sprites_list.append(tower.sprite);  
        try sprites.collider_list.append(tower.collider); 
    }
}

