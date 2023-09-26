const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const math = @import("../math.zig"); 
const player = @import("./player.zig"); 
const entities = @import("../entities/entities.zig"); 
const enemies = @import("./enemies.zig"); 
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;


pub var ui_list: std.ArrayList(UiElement) = undefined; 

pub const UiElement = enum {
    texture: Texture2D, 
    position: Vec2,


    pub fn createUiElement(texture_path: []const u8, position: Vec2) UiElement {
        const texture = raylib.LoadTexture(texture_path); 
        var u = UiElement{
            .texture = texture,
            .position = position,
        };

        return u; 
    }
}


pub fn createUiElementList(alloc: std.mem.Allocator) !std.ArrayList(UiElement) {
    ui_list = std.ArrayList(UiElement).init(alloc); 
    return ui_list; 
}


//pub fn initUiElements(
