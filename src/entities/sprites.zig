const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;

//do we need access outside of this file? maybe pass them in via function 
//for now we can leave these public since we need them for other files 
pub var sprites_list: std.ArrayList(Sprite) = undefined; 
pub var collider_list: std.ArrayList(Rect) = undefined;  

pub const Sprite = struct {
    texture: Texture2D,
    rect: Rect,
    origin: Vec2, 
    scale: f32,
};

pub fn initSprites(alloc: std.mem.Allocator) !void {
    _ = try createEntitiesList(alloc);     
    _ = try createColliderList(alloc); 
}

pub fn update(alloc: std.mem.Allocator) !void {
   //update logic  
   //I don't think these need to be called every update?
    const sorted_list = try sortSpritesForDrawOrder(); 
    try drawSpritesInOrder(alloc, sorted_list); 
    //checkForHitboxCollisions(p); 
}

pub fn deinitSprites() void {
    sprites_list.deinit(); 
    collider_list.deinit(); 
}

fn createEntitiesList(alloc: std.mem.Allocator) !*std.ArrayList(Sprite) {
    sprites_list = std.ArrayList(Sprite).init(alloc); 
    return &sprites_list; 
}

fn createColliderList(alloc: std.mem.Allocator) !*std.ArrayList(Rect) {
    collider_list = std.ArrayList(Rect).init(alloc);  
    return &collider_list; 
}

fn sortingContext(context: void, a: Sprite, b: Sprite) bool {
    _ = context; 
    if (a.origin.y < b.origin.y) return true;
    return false; 
}

fn sortSpritesForDrawOrder() ![]Sprite {
    const list = try sprites_list.toOwnedSlice();   
    std.mem.sort(Sprite, list, {}, sortingContext); 

    return list; 
}

//TODO: see if there a way we can avoid passing in an allocator here, if not, oh well
fn drawSpritesInOrder(alloc: std.mem.Allocator, sorted_list: []Sprite) !void {
     
    for (sorted_list) |entity| {
        raylib.DrawTextureEx(
            entity.texture,
            Vec2{.x = entity.rect.x, .y = entity.rect.y},
            0, //rotation
            entity.scale,
            raylib.WHITE
        );
    }
    
    //debug origin
   // for (sorted_list) |origin_point| {
   //     raylib.DrawRectangleV(
   //         origin_point.origin,
   //         Vec2{.x = 5, .y = 5},
   //         raylib.RED
   //     );
   // }

  //  for (collider_list.items) |collider| {
  //      raylib.DrawRectangleRec(
  //          collider,
  //          raylib.BLUE
  //      );
  //  }

    //for (p.colliders) |p_collider| {
    //    raylib.DrawRectangleRec(
    //        p_collider,
    //        raylib.RED
    //    ); 
    //}
    
    //sprites_list is already emptied by used toOwnedSlice();  
    //but we need to free the list now 
    alloc.free(sorted_list); 
    collider_list.clearAndFree(); 
}



