const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;


pub var ui_list: std.ArrayList(UiElement) = undefined; 
pub var ui_map: std.StringHashMap(UiElement) = undefined; 

pub const UiElement = struct {
    texture_rect: Rect,
    position_rect: Rect,
    name: []const u8,


    pub fn createUiElement(
        texture_rect: Rect,
        position_rect: Rect, 
        name: []const u8
        ) UiElement {
        var u = UiElement{
            .texture_rect = texture_rect,
            .position_rect = position_rect,
            .name = name,
        };

        return u; 
    }
};

pub fn createUiElementList(alloc: std.mem.Allocator) !std.ArrayList(UiElement) {
    ui_list = std.ArrayList(UiElement).init(alloc); 
    return ui_list; 
}

pub fn createUiElementMap(alloc: std.mem.Allocator) !std.StringHashMap(UiElement) {
    ui_map = std.StringHashMap(UiElement).init(alloc); 
    return ui_map; 
}

var ui_texture_atlas: Texture2D = undefined;
//set ui elements to screen pos
pub fn setUiElements(screen_width: f32, screen_height: f32) !void {
    ui_texture_atlas = raylib.LoadTexture("src/world/assets/ui.png"); 
    //set up hotbar
    const hotbar = UiElement.createUiElement(
        Rect{
            .x = 0,
            .y = 0, 
            .width = 160,
            .height = 32,
        },
        Rect{
            .x = (screen_width / 2) - 160,
            .y = screen_height - 64 - 8,
            .width = 160 * 2, 
            .height = 32 * 2,
        },
        "hotbar"
    ); 

    try ui_list.append(hotbar); 
    try ui_map.putNoClobber("hotbar", hotbar); 
}

pub fn drawUiElements() void {
    for (ui_list.items) |ui_element| {
        raylib.DrawTexturePro(
            ui_texture_atlas,
            ui_element.texture_rect,
            ui_element.position_rect,
            Vec2{.x = 0, .y = 0},
            0,
            raylib.WHITE 
        ); 
    }
}
