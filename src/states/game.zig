const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const world_gen = @import("../world_gen/world_gen.zig"); 
const sprites = @import("../entities/sprites.zig"); 
const player = @import("../entities/player.zig"); 
const camera = @import("../entities/camera.zig"); 
pub var cam: raylib.Camera2D = undefined; 

pub fn initGame(alloc: std.mem.Allocator) !void {
    try world_gen.initMap(alloc); 
    try sprites.initSprites(alloc); 
    try player.initPlayer(alloc); 
    //cam = camera.init(&p.sprite.rect, p.sprite.rect.x, p.sprite.rect.y); 
}

pub fn update(alloc: std.mem.Allocator, delta_time: f32) !void {
    try world_gen.update(alloc); 
    player.update(delta_time); 
}

pub fn deinitGame(alloc: std.mem.Allocator) void {
    player.deinitPlayer(); 
    sprites.deinitSprites(); 
    world_gen.deinitMap(alloc); 
}
