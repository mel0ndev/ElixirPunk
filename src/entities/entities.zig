const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const player = @import("./player.zig"); 
const foliage = @import("../world/foliage.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;


pub var entities_list: std.ArrayList(Sprite) = undefined; 
pub var collider_list: std.ArrayList(Rect) = undefined;  


pub const Sprite = struct {
    
    texture: Texture2D,
    rect: Rect,
    origin: Vec2, 

};


pub fn createEntitiesList(alloc: std.mem.Allocator) !std.ArrayList(Sprite) {
    entities_list = std.ArrayList(Sprite).init(alloc); 
    return entities_list; 
}

pub fn createHitboxList(alloc: std.mem.Allocator) !std.ArrayList(Rect) {
    collider_list = std.ArrayList(Rect).init(alloc);  
    return collider_list; 
}

//TODO: move update logic outside of draw function
pub fn drawEntitiesInOrder(p: *player.Player) !void {
    p.updateLists(); //update origin and collider
    try p.addToSpriteList(); 
    try foliage.addToSpriteList(); 
    var sorted_list = try sortEntitiesForDrawOrder(); 
    checkForHitboxCollisions(p); 
     
    for (sorted_list) |entity| {
        raylib.DrawTextureV(
            entity.texture,
            Vec2{.x = entity.rect.x, .y = entity.rect.y},
            raylib.WHITE
        );
    }
    
    //debug origin
 //   for (sorted_list) |origin_point| {
 //       raylib.DrawRectangleV(
 //           origin_point.origin,
 //           Vec2{.x = 5, .y = 5},
 //           raylib.RED
 //       );
 //   }

    for (collider_list.items) |collider| {
        raylib.DrawRectangleRec(
            collider,
            raylib.BLUE
        );
    }

    for (p.colliders) |p_collider| {
        raylib.DrawRectangleRec(
            p_collider,
            raylib.RED
        ); 
    }

    entities_list.clearAndFree(); 
    collider_list.clearAndFree(); 

}

//useless for collisions?
pub fn checkForHitboxCollisions(p: *player.Player) void {
    for (collider_list.items) |collider| {
        for (p.colliders, 0..) |player_collider, i| {
            const overlap: bool = raylib.CheckCollisionRecs(player_collider, collider); 
            if (overlap == true) {
                switch (i) {
                    0 => {
                        p.sprite.rect.y = collider.y + collider.height;
                    },
                    1 => {
                        p.sprite.rect.x = 
                            collider.x - @as(f32, @floatFromInt(
                            p.sprite.texture.width)); 
                    },
                    2 => {
                        p.sprite.rect.y = 
                            collider.y - @as(f32, @floatFromInt(
                                 p.sprite.texture.height));   
                    }, 
                    3 => {
                        p.sprite.rect.x = 
                            collider.x + collider.width;   
                    }, 
                    else => break,
                }
            }
        }
    }
}


fn sortEntitiesForDrawOrder() ![]Sprite {
    var list = try entities_list.toOwnedSlice();   
    std.mem.sort(Sprite, list, {}, sortingContext); 

    return list; 
}


fn sortingContext(context: void, a: Sprite, b: Sprite) bool {
    _ = context; 
    if (a.origin.y < b.origin.y) return true;
    return false; 
}



