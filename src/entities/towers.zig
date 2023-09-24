const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
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
    attack_speed: f32, //how many times they attack per second
}; 

pub const Tower = struct {
    sprite: entities.Sprite, 
    collider: Rect, 
    stats: TowerStats,
    ttype: TowerType,

    fn createTower(
        texture: Texture2D, 
        rect: Rect, 
        collider: Rect,
        origin: Vec2, 
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
            .stats = stats,
            .collider = collider,
            .ttype = ttype
        }; 

        return t; 
    } 
}; 

pub var tower_list: std.ArrayList(Tower) = undefined; 
pub var tower_map: std.AutoHashMap(TowerType, Texture2D) = undefined; 

pub fn createTowerList(alloc: std.mem.Allocator) !std.ArrayList(Tower) {
    tower_list = std.ArrayList(Tower).init(alloc); 
    return tower_list; 
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
                Rect{.x = world_mouse_x - (texture_width),
                     .y = world_mouse_y - (texture_height),
                     .width = @floatFromInt(texture.width),
                     .height = @floatFromInt(texture.height)
                 }, 
                Rect{.x = world_mouse_x + texture_width - 5.0, 
                     .y = world_mouse_y + texture_height - 12.0,
                     .width = 10,
                     .height = 10,
                 },
                 Vec2{.x = world_mouse_x + texture_width,
                      .y = world_mouse_y,
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
            .range = 10, 
            .attack_speed = 2,
        },
        TowerType.FIRE => stats = .{
            .damage = 15,
            .damage_over_time = 5, 
            .range = 5,
            .attack_speed = 1, 
        },
    } 

    return stats; 
}

pub fn addToSpriteList() !void {
    for (tower_list.items) |tower| {
        try entities.entities_list.append(tower.sprite);  
        try entities.collider_list.append(tower.collider); 
    }
}
