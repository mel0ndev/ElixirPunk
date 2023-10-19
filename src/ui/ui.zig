const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const Vec2 = raylib.Vector2; 
const Rect = raylib.Rectangle; 
const Texture2D = raylib.Texture2D;


var ui_list: std.ArrayList(UiElement) = undefined; 
var ui_map: std.StringHashMap(UiElement) = undefined; 

var ui_texture_atlas: Texture2D = undefined;

pub fn initUiElements(alloc: std.mem.Allocator) !void {
    _ = try createUiElementList(alloc);        
    _ = try createUiElementMap(alloc); 
    try setUiElements(rayib.getScreenWidth(), rayib.getScreenHeight()); 
};

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

pub fn deinitUiElements() !void {
    ui_list.deinit(); 
    ui_map.deinit(); 
}

const UiElement = struct {
    texture_rect: Rect,
    position_rect: Rect,
    name: []const u8,

    pub fn createUiElement(
        texture_rect: Rect,
        position_rect: Rect, 
        name: []const u8
        ) !UiElement {
        var u = UiElement{
            .texture_rect = texture_rect,
            .position_rect = position_rect,
            .name = name,
        };

        try ui_list.append(hotbar); 
        try ui_map.putNoClobber(name, u); 

        return u; 
    }
};


fn createUiElementList(alloc: std.mem.Allocator) !std.ArrayList(UiElement) {
    ui_list = std.ArrayList(UiElement).init(alloc); 
    return &ui_list; 
}

fn createUiElementMap(alloc: std.mem.Allocator) !std.StringHashMap(UiElement) {
    ui_map = std.StringHashMap(UiElement).init(alloc); 
    return &ui_map; 
}

//set ui elements to screen pos
fn setUiElements(screen_width: f32, screen_height: f32) !void {
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

}

