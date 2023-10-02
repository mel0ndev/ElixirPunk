const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const raygui = @cImport({
    @cInclude("raygui.h"); 
}); 
const Rect = raylib.Rectangle;
const gRect = raygui.Rectangle; 

const menu_width: f32 = 300; 
const menu_height: f32 = 700; 
var menu_rect: Rect = undefined; 
var SHOW_DEBUG_MENU: bool = false; 

pub fn initDebugMenu() void {

    menu_rect = .{ 
        .x = @as(f32, @floatFromInt(raylib.GetScreenWidth())) - menu_width - 10,
        .y = 10,
        .width = menu_width, 
        .height = menu_height
    };
    
}

pub fn update() void {
    if (raylib.IsKeyPressed(raylib.KEY_I)) {
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
            raylib.DARKGRAY
        ); 

    }
}
