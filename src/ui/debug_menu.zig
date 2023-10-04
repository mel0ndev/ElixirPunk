const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const raygui = @cImport({
    @cInclude("raygui.h"); 
}); 
const world_gen = @import("../world_gen/world_gen.zig"); 
const Rect = raylib.Rectangle;
const gRect = raygui.Rectangle; 

const menu_width: f32 = 300; 
const menu_height: f32 = 700; 
var menu_rect: Rect = undefined; 
var SHOW_DEBUG_MENU: bool = false; 

pub fn initDebugMenu() void {

    menu_rect = .{ 
        .x = @as(f32, @floatFromInt(raylib.GetScreenWidth())) - menu_width - 10,
        .y = 20,
        .width = menu_width, 
        .height = menu_height
    };
    
}

pub fn update() void {
    if (raylib.IsKeyPressed(raylib.KEY_L)) {
        if (SHOW_DEBUG_MENU == false) {
            SHOW_DEBUG_MENU = true; 
        } else {
            SHOW_DEBUG_MENU = false; 
        }
    }
    
    debugMenu(); 
}

fn debugMenu() void {   
    if (SHOW_DEBUG_MENU == true) {
        raylib.DrawRectangleRec(
            menu_rect,
            raylib.LIGHTGRAY
        ); 

        _ = raygui.GuiCheckBox(gRect{.x = menu_rect.x + 40, .y = 50, .width = 20, .height = 20}, "Show Tile Neighbors", &world_gen.DEBUG_MODE_NEIGHBORS); 
        _ = raygui.GuiCheckBox(gRect{.x = menu_rect.x + 40, .y = 75, .width = 20, .height = 20}, "Show Tile Positions", &world_gen.DEBUG_MODE_TILE_POS); 


    }
}
