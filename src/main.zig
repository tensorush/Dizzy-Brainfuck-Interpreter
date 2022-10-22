const std = @import("std");
const dizzy = @import("dizzy.zig");

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

    try dizzy.interpret(code, data, buf_input.reader(), buf_output.writer());

    try buf_output.flush();
}
