---
title: Advent of code 2022 in zig
description: My patterns for solving advent of code puzzles
date: 2023-05-28
tags:
- zig
---

## Introduction

I did the [advent of code 2022](https://adventofcode.com/2022/) in zig, it was a fun experience! This article explains some patterns I used for solving the puzzles.

## Zig for puzzles

### Memory management

Of course explicit memory management is cumbersome for puzzles solving. In zig it is doubly so because you are passing allocators around to use data structures like the `arraylist` type.

When developing an application like [zigfunge98](https://git.adyxax.org/adyxax/zigfunge98/about/) I liked zig's memory management a lot, but for puzzles it really gets in the way.

### Error management
Error management is very good when writing programs, but for puzzles it really gets in the way. For example I found myself often writing stuff like:
```zig
var it = std.mem.tokenize(u8, line, "-,");
const a = try std.fmt.parseInt(u64, it.next() orelse unreachable, 10);
```

### Parsing

Another thing I must note is that after enjoying parsing stuff in haskell with parser combinators, I found that parsing in zig is not fun at all. Comptime is fantastic, but for it to work you need to explicitly pass types around in many places and that makes parsing libraries in zig a bit cumbersome. Maybe I did not find the right library or the ecosystem is still immature, or maybe the limited type inference makes this a limitation of the language.

### Comptime

Comptime is so great that I suspect nearly all my solutions must compile to a single print statement with the compiler running all the important computations by itself!

### The standard library

Zig's standard library is really extensive, outside of parsing I did not even try to reach for an external dependency: everything is there and there is a real coherence to the whole thing.

## Solution Template

Here is (spoiler alert) my solution to the first part of the first problem.
```zig
const std = @import("std");

const example = @embedFile("example");
const input = @embedFile("input");

pub fn main() anyerror!void {
    try std.testing.expectEqual(solve(example), 24000);
    const result = try solve(input);
    try std.io.getStdOut().writer().print("{}\n", .{result});
}

fn solve(puzzle: []const u8) !u64 {
    var it = std.mem.split(u8, puzzle, "\n");
    var max: u64 = 0;
    var tot: u64 = 0;
    while (it.next()) |value| {
        const n = std.fmt.parseInt(u64, value, 10) catch 0;
        if (n == 0) {
            if (tot > max) {
                max = tot;
            }
            tot = 0;
        } else {
            tot += n;
        }
    }
    return max;
}
```

I take advantage of external files embedding which is really easy in zig.

When in need of a memory allocator, I reached for the arena allocator:
```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const allocator = arena.allocator();

var stack = std.ArrayList(u64).init(allocator);
```

## Conclusion

Learning zig is worthwhile, it is really a great language. Puzzle solving is not where it shines, but it still is a good way to practice with a lot of its extensive standard library.
