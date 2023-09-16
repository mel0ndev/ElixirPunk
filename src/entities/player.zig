const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const renderables = @import("../renderables.zig"); 
const math = @import("../math.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Camera2D = raylib.Camera2D; 

const SlideX = enum {
    LEFT,
    RIGHT,
};

const SlideY = enum {
    UP, 
    DOWN
}; 

pub const Player = struct {
    
    rect: Rect,
    rot: f32, origin: Vec2, 
    current_speed: Vec2,
    slide_dir_x: SlideX,
    slide_dir_y: SlideY,
    alive: bool,


    pub fn init(x: f32, y: f32, w: f32, h: f32, rotation: f32) !Player {
        var player = Player {
            .rect = Rect {
                .x = x, 
                .y = y,
                .width = w,
                .height = h,
            },
            .rot = rotation,
            .origin = Vec2{ 
                .x = w / 2.0,
                .y = h / 2.0
            },
            .current_speed = Vec2 {
                .x = 0,
                .y = 0,     
            },
            .slide_dir_x = undefined,
            .slide_dir_y = undefined,
            .alive = true,
        }; 

        return player; 
    }

    pub fn drawPlayer(self: *Player) void {
        if (self.alive == true) {
            raylib.DrawRectanglePro(
                raylib.Rectangle{
                    .x = self.rect.x,
                    .y = self.rect.y, 
                    .width = self.rect.width,
                    .height = self.rect.height,
                }, 
                self.origin,
                self.rot,
                raylib.BLACK
            );  
        } 
    } 
    
    //TODO: handle diagonal 
    pub fn movePlayer(self: *Player, speed: f32, delta_time: f32) void {
        //basic movement
        //lerp between current speed (0) and max speed (3) (0 -> 3)
        self.current_speed.x = std.math.clamp(self.current_speed.x, 0, speed); 
        self.current_speed.y = std.math.clamp(self.current_speed.y, 0, speed); 

        if (raylib.IsKeyDown(raylib.KEY_D)) {
            self.slide_dir_x = SlideX.RIGHT; 
            self.current_speed.x += 0.1; 
            self.rect.x += self.current_speed.x * delta_time; 
        }
        
        if (raylib.IsKeyUp(raylib.KEY_D) and self.slide_dir_x == SlideX.RIGHT) {
            if (self.current_speed.x > 0) {
                self.current_speed.x -= 0.1;          
                self.rect.x += self.current_speed.x * delta_time; 
            }
        }

        if (raylib.IsKeyDown(raylib.KEY_A)) {
            self.slide_dir_x = SlideX.LEFT; 
            self.current_speed.x += 0.1; 
            self.rect.x -= self.current_speed.x * delta_time; 
        }

        if (raylib.IsKeyUp(raylib.KEY_A) and self.slide_dir_x == SlideX.LEFT) {
            if (self.current_speed.x > 0) {
                self.current_speed.x -= 0.1;          
                self.rect.x -= self.current_speed.x * delta_time; 
            }
        }

        if (raylib.IsKeyDown(raylib.KEY_W)) {
            self.slide_dir_y = SlideY.UP; 
            self.current_speed.y += 0.1; 
            self.rect.y -= self.current_speed.y * delta_time; 
        }

        if (raylib.IsKeyUp(raylib.KEY_W) and self.slide_dir_y == SlideY.UP) {
            if (self.current_speed.y > 0) {
                self.current_speed.y -= 0.1;          
                self.rect.y -= self.current_speed.y * delta_time; 
            }
        }

        if (raylib.IsKeyDown(raylib.KEY_S)) {
            self.slide_dir_y = SlideY.DOWN; 
            self.current_speed.y += 0.1; 
            self.rect.y += self.current_speed.y * delta_time; 
        }
        
        if (raylib.IsKeyUp(raylib.KEY_S) and self.slide_dir_y == SlideY.DOWN) {
            if (self.current_speed.y > 0) {
                self.current_speed.y -= 0.1;          
                self.rect.y += self.current_speed.y * delta_time; 
            }
        }
    }

    pub fn rotatePlayer(self: *Player, camera: *Camera2D) f32 {
        const mouse_vec: Vec2 = raylib.GetMousePosition(); 
        const world_pos: Vec2 = raylib.GetScreenToWorld2D(mouse_vec, camera.*); 
        const radians: f32 = std.math.atan2(f32, world_pos.y - self.rect.y, world_pos.x - self.rect.x);  
        //this is what I was missing -> gotta be in degrees not radians
        const angle: f32 = std.math.radiansToDegrees(f32, radians); 
        
        self.rot = angle; 
        return angle; 
    }


    pub fn getPlayerPos(self: *Player) Vec2 {
        return Vec2{
            .x = self.rect.x,
            .y = self.rect.y
        };
    }

    pub fn getPlayerRect(self: *Player) Rect {
        return self.rect; 
    }
}; 
