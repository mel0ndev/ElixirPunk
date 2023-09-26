const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const entities = @import("./entities.zig"); 
const math = @import("../math.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Camera2D = raylib.Camera2D; 
const Texture2D = raylib.Texture2D;


pub const InteractableType = enum {
    ALTAR,
    PORTAL,
    CHEST,
    STATUE,
};

pub const Interactable = struct {
    sprite: entities.Sprite,
    collider: ?Rect,
    itype: InteractableType,    

    pub fn createInteractable(
        texture: Texture2D, 
        rect: Rect, 
        collider: ?Rect,
        origin: Vec2, 
        scale: f32,
        itype: InteractableType
    ) Interactable {
        var i = Interactable{
            .sprite = entities.Sprite{
                .texture = texture,
                .rect = rect,
                .origin = origin,
                .scale = scale,
            },
            .collider = undefined,
            .itype = itype
        }; 

        if (collider) |c| {
            i.collider = c; 
        }

        return i; 
    }
};

pub var interactable_list: std.ArrayList(Interactable) = undefined; 
pub var altar: Interactable = undefined; 
pub var portal: Interactable = undefined; 

pub fn createInteractableList(alloc: std.mem.Allocator) !std.ArrayList(Interactable) {
    interactable_list = std.ArrayList(Interactable).init(alloc);  
    return interactable_list; 
}

pub fn initInteractables() !void {
    try createAltar();   
    try createPortal(); 
}

fn createAltar() !void {
    const altar_texture = raylib.LoadTexture("src/world/assets/interactives/altar.png"); 
    altar = Interactable.createInteractable(
        altar_texture,
        Rect{
            .x = (1280 / 2) + 200, 
            .y = (736 / 2) + 120,
            .width = @as(f32, @floatFromInt(altar_texture.width)),
            .height = @as(f32, @floatFromInt(altar_texture.height)),
        },
        Rect{
            .x = (1280 / 2) + 200 + 12,
            .y = (736 / 2) + 120 + @as(f32, @floatFromInt(altar_texture.height)) - 12,
            .width = @as(f32, @floatFromInt(altar_texture.width * 2)) - 24,
            .height = @as(f32, @floatFromInt(@divTrunc(altar_texture.height, 3))),
        },
        Vec2{
            .x = (1280 / 2) + 200, 
            .y = (736 / 2) + 120 + @as(f32, @floatFromInt(altar_texture.height)) - 16,
        },
        2.0,
        InteractableType.ALTAR
    );
    
    try interactable_list.append(altar); 
}

fn createPortal() !void {
    const portal_texture = raylib.LoadTexture("src/world/assets/interactives/portal.png"); 
    portal = Interactable.createInteractable(
        portal_texture,
        Rect{
            .x = (1280 / 2), 
            .y = (736 / 2),
            .width = @as(f32, @floatFromInt(portal_texture.width)),
            .height = @as(f32, @floatFromInt(portal_texture.height)),
        },
        null,
        Vec2{
            .x = (1280 / 2), 
            .y = (736 / 2),
        },
        2.0,
        InteractableType.PORTAL
    );
    
    try interactable_list.append(portal); 
}

pub fn addToSpriteList() !void {
    for (interactable_list.items) |interactable| {
        try entities.entities_list.append(interactable.sprite);     
        if (interactable.collider) |collider| {
            try entities.collider_list.append(collider); 
        }
    } 
}

