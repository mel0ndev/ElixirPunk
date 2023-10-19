const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const player = @import("entities/player.zig"); 
const enemy = @import("entities/enemies.zig"); 
const sprites = @import("../sprites.zig"); 
const math = @import("./math.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Camera2D = raylib.Camera2D; 

var bullet_list: std.ArrayList(Bullet) = undefined; 

pub fn initBullets(alloc: std.mem.Allocator) !void {
    _ = createBulletList(alloc); 
}

pub fn update(delta_time: f32) void {
    _ = delta_time; 
    moveBullet(delta_time); 
    drawBullet(); 
    checkBoundry(); 
    checkEnemyCollision(); 
}

pub fn deinitBullets() void {
    bullet_list.deinit(); 
}

//to unwrap the correct struct
const BulletParentType = enum {
    PLAYER,
    ENEMY,
    TOWER, //??? maybe???
};

const Bullet = struct {

    sprite: entities.Sprite, 
    speed: f32 = 5.0, 
    parent: *anyopaque, //we would know the parent ahead of time
    parent_type: BulletParentType,
    direction: Vec2,
    alive: bool = true,

    //direction is inherited from the parent 
    pub fn createBullet(
        width: f32, 
        height: f32, 
        speed: f32
        parent: *anyopaque, 
        p_type: BulletParentType, 
        ) Bullet {
        //x, y, and direction are all inherited from the parent
        var b = Bullet{
            .sprite = entities.Sprite{
                .texture = texture,
                .rect = Rect {
                    .x = x, 
                    .y = y,
                    .width = width, 
                    .height = height, 
                },
                .origin = Vec2{ 
                    .x = undefined,
                    .y = undefined,
                },
                .scale = 1.0,
            },
            .parent = parent,
            .parent_type = p_type,
            .direction = undefined,
        }; 

        return b; 
    }

    
}; 

fn createBulletList(alloc: std.mem.Allocator) !*std.ArrayList(Bullet) {
    bullet_list = std.ArrayList(Bullet).init(); 
    return &bullet_list; 
}

//TODO move to player
fn shoot(p: *player.Player, list: *[45]Bullet, camera: *Camera2D
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

fn checkBoundry() void {
    for (bullet_list.items) |bullet| {
        if (bullet.sprite.rect.x > raylib.GetScreenWidth() or
            bullet.sprite.rect.y > raylib.GetScreenHeight()) {
            bullet.alive = false; 
        }
    }
}

fn checkCollisions(enemy_list: *std.MultiArrayList(enemy.BasicEnemy)) void {
    for (bullet_list.items) |bullet| {
        for (enemy_list.items(.rect), enemy_list.items(.alive)) |*rect, *alive| {
            var overlap: bool = raylib.CheckCollisionRecs(bullet.sprite.rect, rect); 
            if (overlap == true) {
                alive.* = false; 
                bullet.alive = false;
                bullet.sprite.rect.x = 100000.0;
                bullet.sprite.rect.y = 1000.0; 
            }
        }   
    }
}

//TODO: add DrawTexture etc
fn drawBullet() void {
    for (bullet_list.items) |bullet| {
        if (self.alive == true) {
            raylib.DrawRectangleRec(
                bullet.rect,
                raylib.YELLOW
            );  
        }
}

fn moveBullet(delta_time: f32) void {
    for (bullet_list.items) |bullet| 
    if (bullet.alive == true) {
        bullet.speed += std.math.atan2(f32, bullet.speed, 10.0); 
        bullet.rect.x += (bullet.direction.x * bullet.speed) * delta_time; 
        bullet.rect.y += (bullet.direction.y * bullet.speed) * delta_time;  
    }
} 

