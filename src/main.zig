const std = @import("std");
const rl = @import("raylib");

const Position = enum { left_up, up, right_up, left, middle, right, left_down, down, right_down };
const Frame = struct { char: u8, position: Position };
const GameState = struct {
    step: u32,
    game_states: [game_steps]?Frame,
    player_choices: [game_steps]?PlayerChoice,
    start_timestep: f64,
    is_running: bool,
    is_finished: bool,
};
const RandGen = std.rand.DefaultPrng;
const PlayerChoice = struct { position: bool, symbol: bool };

// game config
const legal_chars = [_]u8{
    'a',
    't',
    'e',
    'n',
    'r',
};
const seconds_per_step = 1;
const game_steps = 30;

// graphical config
const padding = 50;
const start_pos = rl.Vector2.init(0, 50);
const square_size = 100;
const offset = 110;

pub fn main() anyerror!void {
    // Initialization // --------------------------------------------------------------------------------------
    var rand = RandGen.init(0);
    const screenWidth = 450;
    const screenHeight = 450;

    var gs = GameState{ .is_running = false, .is_finished = false, .step = 0, .game_states = [1]?Frame{null} ** game_steps, .player_choices = [1]?PlayerChoice{null} ** game_steps, .start_timestep = 0 };

    rl.initWindow(screenWidth, screenHeight, "n-back zig");
    defer rl.closeWindow(); // Close window and OpenGL context

    var cursorPosition = rl.Vector2.init(-100, -100);
    var frame = Frame{ .char = 'c', .position = Position.left_down };
    var current_choice = PlayerChoice{ .position = false, .symbol = false };

    var score = rl.Vector2.init(0, 0);

    rl.setTargetFPS(30); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Handle keys
        cursorPosition = rl.getMousePosition();
        if (rl.isKeyDown(rl.KeyboardKey.key_backspace)) {
            current_choice.position = true;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_enter)) {
            current_choice.symbol = true;
        }
        if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            gs.is_running = true;
            gs.start_timestep = rl.getTime();
        }
        handleGameState(&rand, &gs, &frame, &current_choice, &score);

        // Draw //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);
        //rl.drawText(
        //    rl.textFormat("Mouse position X: %03i, Y: %03i", .{ @as(i32, @intFromFloat(cursorPosition.x)), @as(i32, @intFromFloat(cursorPosition.y)) }),
        //    10,
        //    40,
        //    20,
        //    rl.Color.light_gray,
        //);
        if (gs.is_finished) {
            display_score(&score);
        }
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

fn handleGameState(rand: *RandGen, game_state: *GameState, frame: *Frame, control: *PlayerChoice, score: *rl.Vector2) void {
    if (!game_state.is_running or game_state.is_finished) return;

    const t = rl.getTime();
    const current: f64 = t - game_state.start_timestep;
    const step: u32 = @intFromFloat(@divFloor(current, seconds_per_step));

    if (step == game_steps) {
        game_state.is_finished = true;
        game_state.is_running = false;
        calculate_score(game_state, score);
    }

    if (step >= game_steps) {
        return;
    }

    if (game_state.game_states[step] == null) {
        game_state.game_states[step] = frame.*;
        game_state.player_choices[step] = control.*;
        frame.position = std.rand.Random.enumValue(rand.random(), Position);
        frame.char = legal_chars[std.rand.Random.uintLessThan(rand.random(), u8, legal_chars.len)];
        //game_state.step = step;
    }

    game_state.step = step;
}

fn calculate_score(state: *GameState, score: *rl.Vector2) void {
    std.debug.print("\nstate:{}", .{state});
    for (2..game_steps) |i| {
        const true_state = state.game_states[i - 2].?;
        const second_true_state = state.game_states[i].?;
        const player_choice = state.player_choices[i];
        if (player_choice != null) {
            score.x += if (player_choice.?.position and second_true_state.position == true_state.position) 1 else 0;
            score.y += if (player_choice.?.symbol and second_true_state.char == true_state.char) 1 else 0;
        }
    }
}

fn display_score(score: *rl.Vector2) void {
    rl.drawText(rl.textFormat("Score position:\t%03d / %03d\nScore symbol:\t%03d / %03d", .{ score.x, @as(u32, game_steps), score.y, @as(u32, game_steps) }), @intFromFloat(30), @intFromFloat(40), 20, rl.Color.dark_gray);
}
