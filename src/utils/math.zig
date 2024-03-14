const std = @import("std"); 
const raylib = @cImport({
    @cInclude("raylib.h");
});
const Vec2 = raylib.Vector2; 



pub fn distance(current: Vec2, target: Vec2) f32 { 
    const a = std.math.pow(f32, (target.y - current.y), 2); 
    const b = std.math.pow(f32, (target.x - current.x), 2); 
    const dis: f32 = std.math.sqrt(a + b); 

    return dis; 
}

pub fn abs(n: i32) i32 {
    if (n < 0) {
        return n * -1; 
    }

    return n; 
}

pub fn direction(current: Vec2, target: Vec2) Vec2 {
    const dir: Vec2 = Vec2{
        .x = (target.x - current.x),
        .y = (target.y - current.y)
    };

    return dir; 
}

pub fn moveTowards(current: Vec2, target: Vec2, speed: f32) Vec2 {
    var x: f32 = current.x; 
    var y: f32 = current.y; 

    //enemy is to the left and above target 
    if (x < target.x and y < target.y) {
        while (x <= target.x and y <= target.y) {
            x += 1 * speed; 
            y += 1 * speed; 
            return Vec2{
                .x = x,
                .y = y
            }; 
        }
    } else if (x < target.x and y > target.y) {
        while (x <= target.x and y >= target.y) {
            x += 1 * speed; 
            y -= 1 * speed;  
            return Vec2{
                .x = x,
                .y = y
            }; 
        }
    } else if (x > target.x and y > target.y) {
        while (x >= target.x and y >= target.y) {
            x -= 1 * speed; 
            y -= 1 * speed;    
            return Vec2 {
                .x = x,
                .y = y
            };
        }
    } else if (x > target.x and y < target.y) {
        while (x >= target.x and y <= target.y) {
            x -= 1 * speed;
            y += 1 * speed; 
            return Vec2{
                .x = x,
                .y = y
            };
        }
     } else if (x > target.x and y == target.y) {
        while (x >= target.x) {
            x -= 1 * speed; 
            return Vec2{
                .x = x,
                .y = y
            };
        }
     } else if (x < target.x and y == target.y) {
        while (x <= target.x) {
            x += 1 * speed; 
            return Vec2{
                .x = x,
                .y = y
            }; 
        } 
     } else if (y < target.y and x == target.x) {
        while (y <= target.y) {
            y += 1 * speed; 
            return Vec2{
                .x = x, 
                .y = y
            }; 
        }
     }  else if ( y > target.y and x == target.x) {
        while (y >= target.y) {
            y -= 1 * speed;
            return Vec2{
                .x = x,
                .y = y
            };
        }
     }
        
    return Vec2{.x = x, .y = y}; 
}

pub fn easeInCubic(x: f32) f32 {
    return x * x * x; 
}

pub fn track(current_pos: Vec2, target_pos: Vec2) Vec2 {
        var dx = target_pos.x - current_pos.x; 
        var dy = target_pos.y - current_pos.y; 
        const length: f32 = @sqrt(dx * dx + dy * dy);    
        dx /= length; 
        dy /= length; 

        return Vec2{.x = dx, .y = dy}; 
}



