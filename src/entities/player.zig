const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const sprites = @import("./sprites.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D; 

//store this somewhere on the heap?
var player_texture: Texture2D = undefined;  
pub var player: Player = undefined; 

pub fn initPlayer(screen_width: f32, screen_height: f32) !void {
    player_texture = raylib.LoadTexture("src/assets/mc.png");
    player = Player.init(
        screen_width / 2, 
        screen_height / 2,
        16, 
        16, 
        0.0
    ); 
    try player.addToSpriteList();  
}

//update all player logic
pub fn update(delta_time: f32) void {
    //TODO: temp, should be handled by sprite renderer
    player.drawPlayer(); 
    player.movePlayer(delta_time); 
    player.updateLists(); 
    player.checkForHitboxCollisions(); 
}

pub fn deinitPlayer() void {
    raylib.UnloadTexture(player_texture);  
}

pub const Player = struct {

    sprite: sprites.Sprite, 
    colliders: [4]Rect,
    rotation: f32,
    speed: Vec2,
    direction: Vec2,
    alive: bool = true,


    pub fn init(x: f32, y: f32, width: f32, height: f32, rotation: f32) Player {
        var p = Player {
            .sprite = sprites.Sprite{
                .texture = player_texture,
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
            .colliders = undefined,
            .rotation = rotation,
            .speed = Vec2{.x = 3, .y = 3}, 
            .direction = Vec2{.x = 0, .y = 0}, 
        }; 
        
        return p; 
    }

    pub fn drawPlayer(self: *Player) void {
        raylib.DrawTextureV(
            self.sprite.texture,
            Vec2{.x = self.sprite.rect.x, .y = self.sprite.rect.y},
            raylib.WHITE
        );
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

//    pub fn spawnTower(camera: *Camera2D) !void {
//        if (raylib.IsKeyPressed(raylib.KEY_Q)) { 
//            try towers.generateTowerData(towers.TowerType.BASIC, camera); 
//        }
//    }

    //pub fn rotatePlater(self: *Player, camera: *Camera2D) f32 {
    //    const mouse_vec: Vec2 = raylib.GetMousePosition(); 
    //    const world_pos: Vec2 = raylib.GetScreenToWorld2D(mouse_vec, camera.*); 
    //    const radians: f32 = std.math.atan2(f32, world_pos.y - self.sprite.rect.y, world_pos.x - self.sprite.rect.x);  
    //    //this is what I was missing -> gotta be in degrees not radians
    //    const angle: f32 = std.math.radiansToDegrees(f32, radians); 
    //    
    //    self.rotation = angle; 
    //    return angle; 
    //}


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

    pub fn checkForHitboxCollisions(self: *Player) void {
    for (sprites.collider_list.items) |collider| {
        for (self.colliders, 0..) |player_collider, i| {
            const overlap: bool = raylib.CheckCollisionRecs(player_collider, collider);
            if (overlap == true) {
                switch (i) {
                    0 => {
                        self.sprite.rect.y = collider.y + collider.height - 10.0;
                    },
                    1 => {
                        self.sprite.rect.x =
                            collider.x - @as(f32, @floatFromInt(
                            self.sprite.texture.width));
                    },
                    2 => {
                        self.sprite.rect.y =
                            collider.y - @as(f32, @floatFromInt(
                                 self.sprite.texture.height));
                    },
                    3 => {
                        self.sprite.rect.x =
                            collider.x + collider.width;
                    },
                    else => break,
                }
            }
        }
    }
}

    pub fn addToSpriteList(self: *Player) !void {
        try sprites.sprites_list.append(self.sprite); 
    } 
};  
