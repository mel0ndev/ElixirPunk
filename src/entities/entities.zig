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
pub var hitbox_list: std.ArrayList(Rect) = undefined;  


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
    hitbox_list = std.ArrayList(Rect).init(alloc);  
    return hitbox_list; 
}

pub fn drawEntitiesInOrder(p: *player.Player) !void {
    p.updateLists(); 
    try p.addToSpriteList(); 
    try foliage.addToSpriteList(); 
    var sorted_list = try sortEntitiesForDrawOrder(); 
     
    for (sorted_list) |entity| {
        raylib.DrawTextureV(
            entity.texture,
            Vec2{.x = entity.rect.x, .y = entity.rect.y},
            raylib.WHITE
        );
    }
    
    //debug origin
    for (sorted_list) |origin_point| {
        raylib.DrawRectangleV(
            origin_point.origin,
            Vec2{.x = 5, .y = 5},
            raylib.RED
        );
    }

    for (hitbox_list.items) |hitbox| {
        raylib.DrawRectangleRec(
            hitbox,
            raylib.BLUE
        );
    }

    entities_list.clearAndFree(); 
    hitbox_list.clearAndFree(); 

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



