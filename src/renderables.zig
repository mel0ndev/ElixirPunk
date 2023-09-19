const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const player = @import("entities/player.zig"); 
const enemy = @import("entities/enemies.zig"); 
const math = @import("./math.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Camera2D = raylib.Camera2D; 

pub var bullet_index: usize = 0; 

pub fn initBulletList(comptime n: usize) [n]Bullet {
    comptime var bullet_list: [n]Bullet = undefined; 
    return bullet_list; 
}

pub const Bullet = struct {

    rect: Rect, 
    velocity: Vec2,
    speed: f32 = 5.0, 
    angle: f32,
    alive: bool,

    
    pub fn init(x: f32, y: f32, a: f32, vx: f32, vy: f32, al: bool) Bullet {
        var b = Bullet{
            .rect = Rect {
                .x = x,
                .y = y,
                .width = 10,
                .height = 10, 
            },
            .velocity = Vec2 {
                .x = vx,
                .y = vy
            },
            .angle = a,
            .alive = al,
        }; 

        return b; 
    }
    
    //TODO: make list accept whatever N bullets is -- prolly not even needed
    pub fn shoot(
        p: *player.Player, 
        list: *[45]Bullet,
        camera: *Camera2D
        ) void {
        if (raylib.IsMouseButtonPressed(raylib.MOUSE_BUTTON_LEFT)) {
            const mouse_pos: Vec2 = raylib.GetMousePosition(); 
            const world_pos: Vec2 = raylib.GetScreenToWorld2D(mouse_pos, camera.*); 
            var dx = world_pos.x - p.sprite.rect.x; 
            var dy = world_pos.y - p.sprite.rect.y; 

            const length: f32 = @sqrt(dx * dx + dy * dy); 
            dx /= length; 
            dy /= length;

            var bullet = init(p.sprite.rect.x, p.sprite.rect.y, p.rot, dx, dy, true); //alive
            
            //add bullet to array on first empty slot
            //array is full, check for bullets that are not alive and replace those    
            for (list) |*b| {
                if (b.alive == false) {
                    b.* = bullet; 
                    break; 
                }
            }
        }
    }    
    
    pub fn checkBoundry(self: *Bullet, w: f32, h: f32) void {
        if (self.rect.x > w or
            self.rect.y > h) {
                self.alive = false; 
            }
    }
    
   //TODO: refactor to check which enemy is being hit
    pub fn checkCollisions(self: *Bullet, enemy_list: *std.MultiArrayList(enemy.BasicEnemy)) void {
        var bullet_rect = getBulletRect(self); 

        for (enemy_list.items(.rect), enemy_list.items(.alive), 0..) |*rect, *alive, i| {
            //var enemy_rect = enemy.BasicEnemy.getEnemyRect(rect); 
            var overlap: bool = raylib.CheckCollisionRecs(bullet_rect, rect.*); 
            if (overlap == true) {
                alive.* = false; 
                self.alive = false;
                self.rect.x = 100000.0;
                self.rect.y = 1000.0; 
                std.debug.print("{}", .{i}); 
            }
        }   
    }

    pub fn drawBullet(self: *Bullet) void {
        if (self.alive == true) {
            raylib.DrawRectangleRec(
                self.rect,
                raylib.YELLOW
            );  
        }
    }

    pub fn moveBullet(self: *Bullet, delta_time: f32) void {
        if (self.alive == true) {
            self.speed += std.math.atan2(f32, self.speed, 10.0); 
            self.rect.x += (self.velocity.x * self.speed) * delta_time; 
            self.rect.y += (self.velocity.y * self.speed) * delta_time;  
        }
    } 
    
    pub fn getBulletRect(self: *Bullet) Rect {
        return self.rect; 
    }

}; 



