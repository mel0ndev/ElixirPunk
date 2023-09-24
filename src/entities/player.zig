const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const renderables = @import("../renderables.zig"); 
const entities = @import("./entities.zig"); 
const towers = @import("./towers.zig"); 
const math = @import("../math.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Camera2D = raylib.Camera2D; 


pub const Player = struct {

    sprite: entities.Sprite, 
    colliders: [4]Rect,
    rot: f32,
    speed: Vec2,
    direction: Vec2,
    alive: bool,


    pub fn init(x: f32, y: f32, w: f32, h: f32, rotation: f32) !Player {
        const texture = raylib.LoadTexture("src/world/assets/tiles/mc.png"); 
        var player = Player {
            .sprite = entities.Sprite{
                .texture = texture,
                .rect = Rect {
                    .x = x, 
                    .y = y,
                    .width = w, .height = h, },
                .origin = Vec2{ 
                    .x = undefined,
                    .y = undefined,
                },
                .scale = 1.0,
            },
            .colliders = undefined,
            .rot = rotation,
            .speed = Vec2{.x = 3, .y = 3}, 
            .direction = Vec2{.x = 0, .y = 0}, 
            .alive = true,
        }; 
        
        return player; 
    }
    
    pub fn movePlayer(self: *Player, delta_time: f32) void {
        //basic movement
        //lerp between negative max and max speed (3) (0 -> 3)
        //self.speed.x = std.math.clamp(self.speed.x, 0, speed); 
        //self.speed.y = std.math.clamp(self.speed.y, 0, speed); 
        self.direction = .{.x = 0, .y = 0};  

        if (raylib.IsKeyDown(raylib.KEY_D)) {
            self.direction.x = 1; 
            self.sprite.rect.x += self.speed.x * delta_time; 
        }

        if (raylib.IsKeyDown(raylib.KEY_A)) {
            self.direction.x = -1.0; 
            self.sprite.rect.x -= self.speed.y * delta_time; 
        }

        if (raylib.IsKeyDown(raylib.KEY_W)) {
            self.direction.y = -1.0;  
            if (self.direction.x != 0) {
                self.sprite.rect.y -= (self.speed.y / 2) * delta_time; 
            } else {
                self.sprite.rect.y -= self.speed.y * delta_time; 
            }
        }

        if (raylib.IsKeyDown(raylib.KEY_S)) {
            self.direction.y = 1.0; 
            if (self.direction.x != 0) {
                self.sprite.rect.y += (self.speed.y / 2) * delta_time; 
            } else {
                self.sprite.rect.y += self.speed.y * delta_time; 
            }
        }
        
    }

    pub fn spawnTower(camera: *Camera2D) !void {
        if (raylib.IsKeyPressed(raylib.KEY_Q)) { 
            try towers.generateTowerData(towers.TowerType.BASIC, camera); 
        }
    }

    pub fn rotatePlayer(self: *Player, camera: *Camera2D) f32 {
        const mouse_vec: Vec2 = raylib.GetMousePosition(); 
        const world_pos: Vec2 = raylib.GetScreenToWorld2D(mouse_vec, camera.*); 
        const radians: f32 = std.math.atan2(f32, world_pos.y - self.sprite.rect.y, world_pos.x - self.sprite.rect.x);  
        //this is what I was missing -> gotta be in degrees not radians
        const angle: f32 = std.math.radiansToDegrees(f32, radians); 
        
        self.rot = angle; 
        return angle; 
    }


    pub fn getPlayerPos(self: *Player) Vec2 {
        return Vec2{
            .x = self.sprite.rect.x,
            .y = self.sprite.rect.y
        };
    }

    pub fn getPlayerRect(self: *Player) Rect {
        return self.sprite.rect; 
    }

    pub fn updateLists(self: *Player) void {
        self.sprite.origin = Vec2{
            .x = self.sprite.rect.x + 8,
            .y = self.sprite.rect.y + 8,
        };

        self.colliders = [4]Rect{
            //top
            Rect{
                .x = self.sprite.rect.x + @as(f32, @floatFromInt(@divTrunc(self.sprite.texture.width, 2))),
                .y = self.sprite.rect.y + 10.0,
                .width = 4,
                .height = 4,
            },
            //right
            Rect{
                .x = self.sprite.rect.x + @as(f32, @floatFromInt(self.sprite.texture.width)) - 4,
                .y = self.sprite.rect.y + @as(f32, @floatFromInt(@divTrunc(self.sprite.texture.height, 2))),
                .width = 4,
                .height = 4,
            },
            //bottom
            Rect{
                .x = self.sprite.rect.x + @as(f32, @floatFromInt(@divTrunc(self.sprite.texture.width, 2))),
                .y = self.sprite.rect.y + @as(f32, @floatFromInt(self.sprite.texture.height)) - 4.0,
                .width = 4,
                .height = 4,
            },
            //left
            Rect{
                .x = self.sprite.rect.x,
                .y = self.sprite.rect.y + @as(f32, @floatFromInt(@divTrunc(self.sprite.texture.height, 2))),
                .width = 4,
                .height = 4,
            },
            
        };
    }

    pub fn addToSpriteList(self: *Player) !void {
        try entities.entities_list.append(self.sprite); 
    } 
};  
