const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const player = @import("./player.zig"); 
const Camera2D = raylib.Camera2D; 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 



//TODO: add checks for fullscreen
pub fn init(t: *Rect) Camera2D {
    var c = Camera2D {
        .target = Vec2 {
            .x = t.x,
            .y = t.y,    
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
}

pub fn zoomCamera(camera: *Camera2D) void {
    //camera.zoom = std.math.clamp(camera.zoom, 0.75, 1.5); 
    camera.zoom += raylib.GetMouseWheelMove() * 0.05; 
    if (camera.zoom < 0.75) camera.zoom = 0.75; 
    if (camera.zoom > 1.5) camera.zoom = 1.5; 
}

