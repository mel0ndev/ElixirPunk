const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const player = @import("entities/player.zig"); 
const camera = @import("entities/camera.zig"); 
const enemies = @import("entities/enemies.zig"); 
const entities = @import("entities/entities.zig"); 
const world = @import("world/world.zig"); 
const renderables = @import("./renderables.zig"); 

const target_frame_time: f32 = 0.016667; 


pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator); 
    defer arena.deinit(); 
    const allocator = arena.allocator(); 

    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth: f32 = 1280;
    const screenHeight: f32 = 736;

    raylib.InitWindow(screenWidth, screenHeight, "Simple");

    raylib.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    
    //init enemies array list
    var enemy_list = try enemies.BasicEnemy.addEnemies(allocator, 3); 
    var p = try player.Player.init(screenWidth / 2, screenHeight / 2, 16, 16, 0.0); 
    var bullet_list = renderables.initBulletList(45); 
    var entities_list = try entities.createEntitiesList(allocator); 
    var hitbox_list = try entities.createHitboxList(allocator); 
    defer entities_list.deinit(); 
    defer hitbox_list.deinit(); 
    //var tiles = world.Tile.loadTexture("src/world/grass.png"); 
    try world.createMap(allocator); 
    var cam = camera.init(&p.sprite.rect, p.sprite.rect.x, p.sprite.rect.y); 
    //_ = try world.createTileHapMap(allocator); 
    //try world.Tile.setTileMap(16); 
    //try world.Tile.pickTiles(); 

    // Main game loop
    while (!raylib.WindowShouldClose()) { // Detect window close button or ESC key
                                          
        //----------------------------------------------------------------------------------
        var delta_time = raylib.GetFrameTime() / target_frame_time; 
        //enemies.spawn_timer -= 0.09; 
        // Draw
        //----------------------------------------------------------------------------------
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);

        //enter 2d camera mode
        raylib.BeginMode2D(cam);

        try world.drawMap(); 
        
       //player updates 
        _ = player.Player.rotatePlayer(&p, &cam); 
        player.Player.movePlayer(&p, 3.0, delta_time); 
        //player.Player.drawPlayer(&p);   
        //
        try entities.drawEntitiesInOrder(&p); 
        //try entities.checkCollisions(&p); 

        camera.followPlayer(&cam, &p); 
        camera.zoomCamera(&cam); 

        
        //bullet logic
        renderables.Bullet.shoot(&p, &bullet_list, &cam);
        //check if bullet is inside screen area
        for (&bullet_list) |*bullet| {
            if (bullet != undefined) {
                renderables.Bullet.drawBullet(bullet); 
                renderables.Bullet.moveBullet(bullet, delta_time); 
                renderables.Bullet.checkCollisions(bullet, &enemy_list); 
                renderables.Bullet.checkBoundry(bullet, cam.target.x * 2, cam.target.y * 2); 
            }
        } 

        //enemy updates
        //enemies.BasicEnemy.drawEnemy();  
        //enemies.BasicEnemy.moveEnemy(&p); 
        //enemies.enemySpawnTimer(); 
        //enemies.BasicEnemy.checkEnemyCollision(&p); 

        raylib.EndMode2D();  
        raylib.EndDrawing();
        //----------------------------------------------------------------------------------
    }
    
    world.cleanup(); 

    // De-Initialization
    //--------------------------------------------------------------------------------------
    raylib.CloseWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}




