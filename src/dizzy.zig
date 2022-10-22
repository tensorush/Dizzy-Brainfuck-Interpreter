const std = @import("std");

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
