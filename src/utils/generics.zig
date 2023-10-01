const std = @import("std"); 


pub fn cast(comptime T: type, ptr: *anyopaque) *T {
    return @as(*T, @alignCast(@ptrCast(ptr)));  
}

pub fn unwrap(comptime T: type, ptr: *anyopaque) T {
    return @as(T, @ptrCast(@alignCast(ptr))); 
}
