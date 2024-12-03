const std = @import("std");
const fs = std.fs;
const debug = std.debug;
const process = std.process;

pub fn main() !void {
    var args = process.args();

    _ = args.skip(); // skip program name

    const input_file = args.next() orelse {
        debug.print("missing input file path argument\n", .{});
        process.exit(1);
    };

    _ = fs.cwd().statFile(input_file) catch |err| {
        debug.print("can not stat file {s}: {s}\n", .{ input_file, @errorName(err) });
        process.exit(1);
    };

    const file = fs.cwd().openFileZ(input_file, .{ .mode = .read_only }) catch |err| {
        debug.print("could not open file {s}: {s}", .{ input_file, @errorName(err) });
        process.exit(1);
    };

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // defer _ = gpa.deinit();

    var left: [1024]u32 = undefined;
    var right: [1024]u32 = undefined;

    var bufReader = std.io.bufferedReader(file.reader());
    var reader = bufReader.reader();
    var buf: [256]u8 = undefined;
    var index: usize = 0;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.assert(index < left.len);

        var splitted = std.mem.splitSequence(u8, line, "   ");
        if (splitted.next()) |numStr| {
            const num = try std.fmt.parseUnsigned(u32, numStr, 10);
            left[index] = num;
        } else {
            debug.panic("missing number left number from input!\n", .{});
        }

        if (splitted.next()) |numStr| {
            const num = try std.fmt.parseUnsigned(u32, numStr, 10);
            right[index] = num;
        } else {
            debug.panic("missing number right number from input!\n", .{});
        }

        index += 1;
    }

    std.mem.sort(u32, left[0..index], {}, std.sort.asc(u32));
    std.mem.sort(u32, right[0..index], {}, std.sort.asc(u32));

    var total_distance: u32 = 0;

    for (0..index) |i| {
        const distance = blk: {
            if (left[i] > right[i]) {
                break :blk left[i] - right[i];
            } else {
                break :blk right[i] - left[i];
            }
        };

        total_distance += distance;
    }

    debug.print("total distance: {}\n", .{total_distance});

    var total_similarity: u32 = 0;
    var j: usize = 0;
    var previous: struct { left: u32, similarity: u32 } = .{ .left = 0, .similarity = 0 };

    for (0..index) |i| {
        if (previous.left == left[i]) {
            total_similarity += previous.similarity;
            continue;
        }

        var count: u32 = 0;
        while (left[i] >= right[j]) {
            if (j >= index) {
                break;
            }

            if (left[i] == right[j]) {
                count += 1;
            }

            j += 1;
        }

        const similarity = left[i] * count;
        previous = .{ .left = left[i], .similarity = similarity };
        total_similarity += similarity;
    }

    debug.print("similarity: {}\n", .{total_similarity});
}
