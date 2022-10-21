const std = @import("std");

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);

    var file_path = args[1];
    var code_size: usize = 4096;
    var data_size: usize = 30_000;

    if (args.len > 2) {
        if (args.len == 4 and std.mem.eql(u8, args[2], "-cs")) {
            code_size = try std.fmt.parseInt(usize, args[3], 10);
        } else if (args.len == 4 and std.mem.eql(u8, args[2], "-ds")) {
            data_size = try std.fmt.parseInt(usize, args[3], 10);
        } else if (args.len == 6 and std.mem.eql(u8, args[2], "-cs") and std.mem.eql(u8, args[4], "-ds")) {
            code_size = try std.fmt.parseInt(usize, args[3], 10);
            data_size = try std.fmt.parseInt(usize, args[5], 10);
        } else if (args.len == 6 and std.mem.eql(u8, args[2], "-ds") and std.mem.eql(u8, args[4], "-cs")) {
            data_size = try std.fmt.parseInt(usize, args[3], 10);
            code_size = try std.fmt.parseInt(usize, args[5], 10);
        } else {
            std.debug.print("Usage: dizzy FILE_PATH [-cs CODE_SIZE] [-ds DATA_SIZE]\n", .{});
            return {};
        }
    }

    const code = try std.fs.cwd().readFileAlloc(allocator, file_path, code_size);

    var data = try allocator.alloc(u8, data_size);
    std.mem.set(u8, data, 0);

    const input = std.io.getStdIn();
    var buf_input = std.io.bufferedReader(input.reader());

    const output = std.io.getStdOut();
    var buf_output = std.io.bufferedWriter(output.writer());

    try interpret(code, data, buf_input.reader(), buf_output.writer());

    try buf_output.flush();
}

pub const Error = error{
    UnmatchedLeftBracket,
    UnmatchedRightBracket,
};

pub fn interpret(code: []const u8, data: []u8, buf_reader: anytype, buf_writer: anytype) anyerror!void {
    var code_ptr: usize = 0;
    var data_ptr: usize = 0;

    while (code_ptr < code.len) : (code_ptr += 1) {
        switch (code[code_ptr]) {
            '+' => {
                data[data_ptr] +%= 1;
            },
            '-' => {
                data[data_ptr] -%= 1;
            },
            '>' => {
                data_ptr += 1;
            },
            '<' => {
                data_ptr -= 1;
            },
            '[' => {
                if (data[data_ptr] == 0) {
                    var bracket_count: usize = 1;
                    while (bracket_count > 0 and code_ptr < code.len - 1) {
                        code_ptr += 1;
                        if (code[code_ptr] == '[') {
                            bracket_count += 1;
                        } else if (code[code_ptr] == ']') {
                            bracket_count -= 1;
                        }
                    }
                    if (bracket_count > 0 and code_ptr == code.len - 1)
                        return Error.UnmatchedLeftBracket;
                }
            },
            ']' => {
                if (data[data_ptr] > 0) {
                    var bracket_count: usize = 1;
                    while (bracket_count > 0 and code_ptr > 0) {
                        code_ptr -= 1;
                        if (code[code_ptr] == '[') {
                            bracket_count -= 1;
                        } else if (code[code_ptr] == ']') {
                            bracket_count += 1;
                        }
                    }
                    if (bracket_count > 0 and code_ptr == 0)
                        return Error.UnmatchedRightBracket;
                }
            },
            '.' => {
                try buf_writer.writeByte(data[data_ptr]);
            },
            ',' => {
                data[data_ptr] = try buf_reader.readByte();
            },
            else => {},
        }
    }
}

fn testInterpret(comptime code: []const u8, comptime data_size: usize, comptime input_size: usize, comptime output_size: usize) anyerror!void {
    var data = [_]u8{0} ** data_size;

    var input: [input_size]u8 = undefined;
    var output: [output_size]u8 = undefined;

    var buf_input = std.io.fixedBufferStream(input[0..]);
    var buf_output = std.io.fixedBufferStream(output[0..]);

    try interpret(code[0..], data[0..], buf_input.reader(), buf_output.writer());
}

test "Error.UnmatchedLeftBracket" {
    try std.testing.expectError(Error.UnmatchedLeftBracket, testInterpret("[><", 64, 64, 64));
}

test "Error.UnmatchedRightBracket" {
    try std.testing.expectError(Error.UnmatchedRightBracket, testInterpret("+><]", 64, 64, 64));
}
