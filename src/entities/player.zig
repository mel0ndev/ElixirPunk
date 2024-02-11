const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const sprites = @import("./sprites.zig"); 
const utils = @import("../utils/utils.zig");
const world_gen = @import("../world_gen/world_gen.zig"); 
const tiles = @import("../world_gen/tiles.zig"); 
var r  = std.rand.DefaultPrng.init(0); 
const Vec2 = raylib.Vector2; 
const iVec2 = utils.iVec2;
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D; 

//store this somewhere on the heap?
var player_texture: Texture2D = undefined;  
pub var player: Player = undefined; 
var player_animation_frame: f32 = 0.0; 
var player_animation_speed: f32 = 8.0; 
var frame_rec: Rect = undefined; 
var source_rec: Rect = undefined; 

pub var player_current_chunk: iVec2 = undefined; 

pub fn initPlayer(alloc: std.mem.Allocator, initialChunk: *world_gen.Chunk) !void {
    player_texture = raylib.LoadTexture("src/assets/newmc1-sheet.png");
    frame_rec = .{
        .x = 0, 
        .y = 0,
        .width = @floatFromInt(@divTrunc(player_texture.width, 4)),
        .height = @floatFromInt(@divTrunc(player_texture.height, 2))
    };
    source_rec = Rect{.x = frame_rec.x, .y = frame_rec.y, .width = 32, .height = 32}; 
    var spawnable_tiles = std.ArrayList(tiles.Tile).init(alloc); 
    defer spawnable_tiles.deinit(); 

    for (initialChunk.tile_list.items) |tile| {
        if (tile.tile_id < 16) {
            try spawnable_tiles.append(tile); 
        }
    }

    var spawn_index: usize = r.random().intRangeLessThan(usize, 0, spawnable_tiles.items.len); 
    const spawn_tile = spawnable_tiles.swapRemove(spawn_index); 

    player = Player.init(
        spawn_tile.tile_data.pos.x * 32, 
        spawn_tile.tile_data.pos.y * 32,
        16, 
        16, 
        0.0
    ); 
    player_current_chunk = getPlayerToChunkPosition(); 

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
        player_animation_speed -= 1.0; 
        if (player_animation_speed < 0) {
            source_rec.x = player_animation_frame * @as(f32, @floatFromInt(@divTrunc(player_texture.width, 8))); 
            player_animation_speed = 8.0; 
        } 


        raylib.DrawTextureRec(
            self.sprite.texture,
            source_rec,
            .{
                .x = self.sprite.rect.x,
                .y = self.sprite.rect.y,
            },
            raylib.WHITE
        );
        
        player_animation_frame += 1; 
        if (player_animation_frame == 8) player_animation_frame = 0; 
    }
    
    pub fn movePlayer(self: *Player, delta_time: f32) void {
        //basic movement
        //lerp between negative max and max speed (3) (0 -> 3)
        //self.speed.x = std.math.clamp(self.speed.x, 0, speed); 
        //self.speed.y = std.math.clamp(self.speed.y, 0, speed); 
        self.direction = .{.x = 0, .y = 0};  
        const current_tile = getPlayerToTilePosition(); 
        const current_tile_info = world_gen.getTileInfo(getPlayerToChunkPosition(), current_tile.x, current_tile.y); 
        
        switch(current_tile_info.tile_id) {
            20 => player.speed = .{.x = 1.0, .y = 1.0},
            else => player.speed = .{.x = 3.0, .y = 3.0},
        }

        
        if (raylib.IsKeyDown(raylib.KEY_D)) {
            source_rec.width = 32; 
            self.direction.x = 1; 
            self.sprite.rect.x += self.speed.x * delta_time; 
        }

        if (raylib.IsKeyDown(raylib.KEY_A)) {
            source_rec.width = -32; 
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


    pub fn getPlayerPos() Vec2 {
        return Vec2{
            .x = player.sprite.rect.x,
            .y = player.sprite.rect.y
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

pub fn getPlayerToTilePosition() Vec2 {
    const player_position = Player.getPlayerPos(); 
    const tile_x = @divFloor(player_position.x, 32); 
    const tile_y = @divFloor(player_position.y, 32); 

    return .{.x = tile_x, .y = tile_y}; 
}

pub fn getPlayerToChunkPosition() iVec2 {
    const tile_pos = getPlayerToTilePosition(); 
    const chunk_x = @as(i32, @intFromFloat(@divFloor(tile_pos.x, 64))); 
    const chunk_y = @as(i32, @intFromFloat(@divFloor(tile_pos.y, 64))); 

    return .{.x = chunk_x, .y = chunk_y}; 
}


//TODO: REMOVE DEBUG
pub fn drawPlayerTilePosition() void {
    const pv = getPlayerToChunkPosition(); 
        var font = raylib.GetFontDefault(); 
        var buf: [1024]u8 = undefined;
        const s = std.fmt.bufPrintZ(
            &buf, 
            "{d}, {d}", 
            .{pv.x, pv.y}
        ) catch @panic("error");
        raylib.DrawTextPro(
            font,
            s,
            Vec2{
                .x = 50,
                .y = 50,
            },
            Vec2{
                .x = 0,
                .y = 0,
            },
            0,
            10,
            1,
            raylib.BLACK
    ); 
}
