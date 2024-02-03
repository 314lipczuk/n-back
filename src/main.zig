const std = @import("std");
const rl = @import("raylib");

const Position = enum { left_up, up, right_up, left, middle, right, left_down, down, right_down };
const Frame = struct { char: u8, position: Position };
const GameState = struct {
    var Self = @This();
    previous_timestep: i64,
    step: u32,
    is_finished: bool,
    start_timestep: i64,
    pub fn init() Self {}
};
const RandGen = std.rand.DefaultPrng;

const legal_chars = [_]u8{ 'a', 'g', 't', 'e', 'f', 'n', 'r', 'p', 'l', 'c', 'g' };
const time_per_step = 3;

const padding = 50;
const start_pos = rl.Vector2.init(0, 50);
const square_size = 100;
const offset = 110;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    var rand = RandGen.init(0);
    const screenWidth = 450;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "n-back zig");
    defer rl.closeWindow(); // Close window and OpenGL context

    var cursorPosition = rl.Vector2.init(-100, -100);
    var frame = Frame{ .char = 'c', .position = Position.left_down };

    rl.setTargetFPS(30); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Handle keys
        cursorPosition = rl.getMousePosition();
        if (rl.isKeyDown(rl.KeyboardKey.key_backspace)) {
            // frame = generate_frame(rand);
            frame = Frame{ .position = std.rand.Random.enumValue(rand.random(), Position), .char = std.rand.Random.uintAtMost(rand.random(), u8, legal_chars.len) };
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_enter)) {
            //frame = generate_frame(rand);
        }

        // Draw //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);
        rl.drawText(
            rl.textFormat("Mouse position X: %03i, Y: %03i", .{ @as(i32, @intFromFloat(cursorPosition.x)), @as(i32, @intFromFloat(cursorPosition.y)) }),
            10,
            40,
            20,
            rl.Color.light_gray,
        );
        draw_grid();
        render_frame(&frame);
    }
}

fn draw_grid() void {
    std.debug.assert(offset > square_size);
    inline for (0..3) |row| {
        inline for (0..3) |col| {
            rl.drawRectangleLines(padding + start_pos.x + col * offset, padding + start_pos.y + row * offset, square_size, square_size, rl.Color.dark_gray);
        }
    }
}

//fn generate_frame(r: std.rand.Xoshiro256) Frame {
//    var f: Frame = Frame{ .position = std.rand.Random.enumValue(r.random(), Position), .char = std.rand.Random.uintAtMost(r.random(), usize, legal_chars.len) };
//    return f;
//}

fn render_frame(f: *Frame) void {
    const position = switch (f.position) {
        .left_up => .{ start_pos.x + 2 * padding, start_pos.y + 2 * padding },
        .up => .{ start_pos.x + 2 * padding + offset, start_pos.y + 2 * padding },
        .right_up => .{ start_pos.x + 2 * padding + 2 * offset, start_pos.y + 2 * padding },
        .left => .{ start_pos.x + 2 * padding, start_pos.y + 2 * padding + offset },
        .middle => .{ start_pos.x + 2 * padding + offset, start_pos.y + 2 * padding + offset },
        .right => .{ start_pos.x + 2 * padding + 2 * offset, start_pos.y + 2 * padding + 2 * offset },
        .left_down => .{ start_pos.x + 2 * padding, start_pos.y + 2 * padding + 2 * offset },
        .down => .{ start_pos.x + 2 * padding + offset, start_pos.y + 2 * padding + 2 * offset },
        .right_down => .{ start_pos.x + 2 * padding + 2 * offset, start_pos.y + 2 * padding + 2 * offset },
    };
    rl.drawText(
        rl.textFormat("%c", .{f.char}),
        @intFromFloat(position[0]),
        @intFromFloat(position[1]),
        20,
        rl.Color.light_gray,
    );
}

// 450 -> full width of window
//
