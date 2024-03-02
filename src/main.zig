const std = @import("std");
const rl = @import("raylib");

const Position = enum { left_up, up, right_up, left, middle, right, left_down, down, right_down };
const Frame = struct { char: u8, position: Position };
const RandGen = std.rand.DefaultPrng;
const PlayerChoice = struct { position: bool, symbol: bool };

// game config
const legal_chars = [_]u8{
    'A',
    'T',
    'E',
    'N',
    'R',
};

const seconds_per_step = 3;
const game_steps = 30;
const X_back = 2;

const amount_of_position_points_to_score = game_steps / 6;
const chance_for_same_position: f32 = 1 / amount_of_position_points_to_score;

const amount_of_char_points_to_score = game_steps / 6;
const chance_for_same_char_point: f32 = 1 / amount_of_char_points_to_score;

// graphical config
const screenWidth = 450;
const screenHeight = 450;

const padding = 50;
const start_pos = rl.Vector2.init(10, 50);
const square_size = 100;
const offset = 110;

const grid_size = 2 * padding + 2 * offset + 3 * square_size;

var is_running = false;
var step: u32 = 0;
var game_states = [1]?Frame{null} ** game_steps;
var player_choices = [1]?PlayerChoice{null} ** game_steps;
var start_timestep: f64 = 0;

var score = rl.Vector2.init(0, 0);
var total_score = rl.Vector2.init(0, 0);

var blink = false;

pub fn main() anyerror!void {
    // Initialization // --------------------------------------------------------------------------------------
    var rand = RandGen.init(0);

    rl.initWindow(screenWidth, screenHeight, "n-back zig");
    defer rl.closeWindow(); // Close window and OpenGL context

    var cursorPosition = rl.Vector2.init(-100, -100);
    var frame = Frame{ .char = 'c', .position = Position.left_down };
    var current_choice = PlayerChoice{ .position = false, .symbol = false };

    rl.setTargetFPS(30); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Handle keys
        cursorPosition = rl.getMousePosition();
        if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
            current_choice.position = true;
            rl.drawCircle((screenWidth / 2) - padding, screenHeight - 15, 5, rl.Color.red);
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
            current_choice.symbol = true;
            rl.drawCircle((screenWidth / 2) + padding, screenHeight - 15, 5, rl.Color.blue);
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            if (!is_running) {
                for (0..game_steps) |i| {
                    player_choices[i] = null;
                    game_states[i] = null;
                }
                score.x = 0;
                score.y = 0;
                is_running = true;
                start_timestep = rl.getTime();
            }
        }

        handleGameState(&rand, &frame, &current_choice);

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);

        if (is_running) {
            rl.drawText(
                rl.textFormat("N = %01d\t Left - position\t Right - symbol", .{@as(u32, X_back)}),
                10,
                10,
                20,
                rl.Color.light_gray,
            );
            draw_grid();
            render_frame(&frame);
        } else {
            draw_stop_screen();
        }
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
        25,
        rl.Color.light_gray,
    );
    if (blink) {
        rl.drawCircle((screenWidth / 2), 50, 5, rl.Color.gold);
        blink = false;
    }
}

fn handleGameState(rand: *RandGen, frame: *Frame, control: *PlayerChoice) void {
    if (!is_running) return;

    const t = rl.getTime();
    const current: f64 = t - start_timestep;
    const c_step: u32 = @intFromFloat(@divFloor(current, seconds_per_step));

    if (c_step == game_steps) {
        is_running = false;
        calculate_score();
        return;
    }

    if (step >= game_steps) {
        return;
    }

    if (game_states[c_step] == null) {
        game_states[c_step] = frame.*;
        player_choices[c_step] = control.*;
        frame.position = if (c_step > 1 and std.rand.Random.float(rand.random(), f32) < chance_for_same_position) game_states[c_step - 2].?.position else std.rand.Random.enumValue(rand.random(), Position);
        frame.char = legal_chars[std.rand.Random.uintLessThan(rand.random(), u8, legal_chars.len)];
        blink = true;
    }

    step = c_step;
}

fn calculate_score() void {
    std.debug.print("calculate score call\n", .{});
    for (2..game_steps) |i| {
        const true_state = game_states[i - X_back].?;
        const second_true_state = game_states[i].?;
        const player_choice = player_choices[i];
        std.debug.print("####\nSymbol: {c} : {c} => {?}\n{?} : {?} => {?}\n{?}\n\n\n", .{ true_state.char, game_states[i].?.char, true_state.char == game_states[i].?.char, true_state.position, game_states[i].?.position, true_state.position == game_states[i].?.position, player_choice });
        if (player_choice != null) {
            score.x += if (player_choice.?.position and second_true_state.position == true_state.position) 1 else 0;
            score.y += if (player_choice.?.symbol and second_true_state.char == true_state.char) 1 else 0;
        }
        total_score.x += if (second_true_state.position == true_state.position) 1 else 0;
        total_score.y += if (second_true_state.char == true_state.char) 1 else 0;
    }
    std.debug.print("final score: {?},\ntotal score: {?}", .{ score, total_score });
}

fn draw_stop_screen() void {
    rl.drawText(rl.textFormat("Press s to start", .{}), @intFromFloat(100), @intFromFloat(10), 20, rl.Color.dark_gray);
    rl.drawText(rl.textFormat("Score position:\t%03d / %03d\nScore symbol:\t%03d / %03d", .{ score.x, total_score.x, score.y, total_score.y }), @intFromFloat(30), @intFromFloat(40), 20, rl.Color.dark_gray);
    rl.drawText(rl.textFormat("Config:\n\nMaxIter:\t\t\t%02d\n\nN count:\t\t\t%02d\n\nTicks/s:\t\t\t%02d", .{ @as(u32, game_steps), @as(u32, X_back), @as(u32, seconds_per_step) }), @intFromFloat(10), @intFromFloat(80), 35, rl.Color.dark_gray);
}
