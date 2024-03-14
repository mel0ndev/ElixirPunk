const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const world_gen = @import("../world_gen/world_gen.zig"); 
const sprites = @import("../entities/sprites.zig"); 
const enemies = @import("../entities/enemies/basic_enemy.zig"); 
const player = @import("../entities/player.zig"); 
const camera = @import("../entities/camera.zig"); 
pub var cam: raylib.Camera2D = undefined; 

pub fn initGame(alloc: std.mem.Allocator) !void {
    try world_gen.initMap(alloc); 
    try sprites.initSprites(alloc); 
    try player.initPlayer(alloc); 
    _ = try enemies.addEnemies(alloc, 1); 
    //cam = camera.init(&p.sprite.rect, p.sprite.rect.x, p.sprite.rect.y); 
}

pub fn update(alloc: std.mem.Allocator, delta_time: f32) !void {
    try world_gen.update(alloc); 
    player.update(delta_time); 
    enemies.drawEnemy();
    try enemies.pathfindToPortal();
}

pub fn deinitGame(alloc: std.mem.Allocator) void {
    player.deinitPlayer(); 
    sprites.deinitSprites(); 
    enemies.deinitEnemies(); 
    world_gen.deinitMap(alloc); 
}
