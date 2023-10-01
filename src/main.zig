const std = @import("std");
const raylib = @cImport({
    @cInclude("raylib.h");
});
//const player = @import("entities/player.zig"); 
//const camera = @import("entities/camera.zig"); 
//const enemies = @import("entities/enemies.zig"); 
//const entities = @import("entities/entities.zig"); 
//const towers = @import("entities/towers/towers.zig"); 
//const towerbullets = @import("entities/towers/tower_bullets.zig"); 
//const interactables = @import("entities/interactables/interactables.zig"); 
//const bullets = @import("entities/interactables/bullets.zig"); 
const world = @import("world_gen/world_gen.zig"); 
const tiles = @import("world_gen/tiles.zig"); 
//const foliage = @import("world_gen/foliage.zig"); 
//const bullets = @import("entities/interactables/bullets.zig"); 
//const ui = @import("./ui/ui.zig"); 

const target_frame_time: f32 = 0.016667; 

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) std.testing.expect(false) catch @panic("TEST FAIL");
    }
    const allocator = gpa.allocator();

    // Initialization
    //-----------------------------------------------------------------------------------
    const screen_width: f32 = 1280;
    const screen_height: f32 = 736;

    raylib.InitWindow(screen_width, screen_height, "Elixir Punk -- dev v0.1");

    raylib.SetTargetFPS(60); // Set our game to run at 60 frames-per-second
    //-----------------------------------------------------------------------------------
    
    //init enemies array list
    //Each game element will have it's own constructor, and will take in the allocator passed in by main()
    //it can then pass the allocator around, and we can free when we need to
    //
    //each game element needs 2 things: an initialzer function, we will use createXList() to create the list on the heap, so we can access it from other places in the program.
    //TODO: move logic to appropriate state location IE states/loading.zig or states/init.zig
    //[x]
    //try ui.initUiElements(allocator); 
    //defer ui.deinitUiElements(); 

    ////[x]
    //try initPlayer(); //can have this return a player pointer if we need 
    //defer deinitPlayer(); 
    ////we have to refactor enemies completely, so leave until last
    ////[ ]
    //var enemy_list = try enemies.BasicEnemy.addEnemies(allocator, 10); 
    //defer enemy_list.deinit(allocator); 
    
   
    //TODO 
    //rework and refactor
    //[ ] [x] 
    //try bullets.initBullets(); 
    //defer deinitBullets(); 

    ////[x] 
    //try sprites.initSprites(allocator); 
    //defer sprites.deinitSprites(); 
    //
    ////[x]
    //try towers.initTowers(alloc);
    //defer towers.deinitTowers(); 
    
    //rework and refactor 
    //possibly leaking memory  
    //[ ]
    //suspected memory leaker
    try world.initMap(allocator); 
    //defer world.deinitMap(); 

    //var cam = camera.init(&p.sprite.rect, p.sprite.rect.x, p.sprite.rect.y); 
    //_ = try world.createTileHapMap(allocator); 
    //try world.Tile.setTileMap(16); 
    //try world.Tile.pickTiles(); 

    // Main game loop
    while (!raylib.WindowShouldClose()) { // Detect window close button or ESC key
                                          
        //----------------------------------------------------------------------------------
        var delta_time = raylib.GetFrameTime() / target_frame_time; 
        _ = delta_time; 
        //enemies.spawn_timer -= 0.09; 
        // Draw
        //----------------------------------------------------------------------------------
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.WHITE);

        //enter 2d camera mode
        //raylib.BeginMode2D(cam);

        try world.drawMap(); 
        
       //player updates 
        //_ = player.Player.rotatePlayer(&p, &cam); 
        //player.Player.movePlayer(&p, delta_time); 
        //try player.Player.spawnTower(&cam); 
        ////player.Player.drawPlayer(&p);   
        ////
        //try entities.drawEntitiesInOrder(&p); 
        ////try entities.checkCollisions(&p); 

        //camera.followPlayer(&cam, &p); 
        //camera.zoomCamera(&cam); 


        //
        ////bullet logic
        //renderables.Bullet.shoot(&p, &bullet_list, &cam);
        ////check if bullet is inside screen area
        //for (&bullet_list) |*bullet| {
        //    if (bullet != undefined) {
        //        renderables.Bullet.drawBullet(bullet); 
        //        renderables.Bullet.moveBullet(bullet, delta_time); 
        //        renderables.Bullet.checkCollisions(bullet, &enemy_list); 
        //        renderables.Bullet.checkBoundry(bullet, cam.target.x * 2, cam.target.y * 2); 
        //    }
        //} 

        ////enemy updates
        //enemies.BasicEnemy.drawEnemy();  
        //enemies.BasicEnemy.moveEnemy(
        //    raylib.Vector2{
        //        .x = interactables.portal.sprite.rect.x + @as(f32, @floatFromInt(interactables.portal.sprite.texture.width)),
        //        .y = interactables.portal.sprite.rect.y + @as(f32, @floatFromInt(interactables.portal.sprite.texture.height))
        //    }); 
        //enemies.enemySpawnTimer(); 
        //enemies.BasicEnemy.checkEnemyCollision(&p); 

        ////TOWERS
        //towers.update(); 
        //towerbullets.update(delta_time); 

        raylib.EndMode2D();  
        
        //draw UI
        raylib.DrawFPS(25, 25); 
        //ui.drawUiElements(); 

        raylib.EndDrawing();
        //----------------------------------------------------------------------------------
    }
    
    world.deinitMap(); 

    // De-Initialization
    //--------------------------------------------------------------------------------------
    raylib.CloseWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}




