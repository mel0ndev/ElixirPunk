const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const player = @import("./player.zig"); 
const world = @import("../world_gen/world_gen.zig"); 
const Camera2D = raylib.Camera2D; 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 



//TODO: add checks for fullscreen
pub fn init(target: *Rect) Camera2D {
    const c = Camera2D {
        .target = Vec2 {
            .x = target.x,
            .y = target.y,    
        },
        .offset = Vec2 {
            .x = @floatFromInt(@divTrunc(raylib.GetScreenWidth(),  2)),
            .y = @floatFromInt(@divTrunc(raylib.GetScreenHeight(),  2)),
        },
        .rotation = 0.0,
        .zoom = 1.0, 
    };    

    return c; 
}
    
pub fn followPlayer(camera: *Camera2D) void {
    const player_pos: Vec2 = player.Player.getPlayerPos();
    camera.target = player_pos;   
    const camera_x_neg = camera.target.x - @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenWidth(), 2))); 
    const camera_y_neg = camera.target.y - @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenHeight(), 2))); 
    const camera_x_pos = camera.target.x + @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenWidth(), 2))); 
    const camera_y_pos = camera.target.y + @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenHeight(), 2))); 
    
    if (camera_x_neg <= 0) {
        camera.target.x -= camera_x_neg; 
    }

    if (camera_y_neg <= 0) {
        camera.target.y -= camera_y_neg; 
    }

    if (camera_x_pos >= world.MAP_SIZE * 32) {
        camera.target.x -= camera_x_pos - world.MAP_SIZE * 32;
    }

    if (camera_y_pos >= world.MAP_SIZE * 32) {
        camera.target.y -= camera_y_pos - world.MAP_SIZE * 32; 
    }
}

pub fn getCameraBounds(camera: *Camera2D) [4]f32 {
    const camera_x_neg = camera.target.x - @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenWidth(), 2))); 
    const camera_y_neg = camera.target.y - @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenHeight(), 2))); 
    const camera_x_pos = camera.target.x + @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenWidth(), 2))); 
    const camera_y_pos = camera.target.y + @as(f32, @floatFromInt(@divTrunc(raylib.GetScreenHeight(), 2))); 

    const bounding_box = [4]f32{camera_x_neg, camera_y_neg, camera_x_pos, camera_y_pos}; 
    return bounding_box; 
}

pub fn zoomCamera(camera: *Camera2D) void {
    //camera.zoom = std.math.clamp(camera.zoom, 0.75, 1.5); 
    camera.zoom += raylib.GetMouseWheelMove() * 0.05; 
    if (camera.zoom < 0.75) camera.zoom = 0.75; 
    if (camera.zoom > 1.5) camera.zoom = 1.5; 
}

