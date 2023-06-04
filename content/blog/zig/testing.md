---
title: Testing in zig
description: Some things I had to figure out
date: 2023-06-04
tags:
- zig
---

## Introduction

I [learned zig]({{< ref "learning-zig.md" >}}) from working on a [Funge98 interpreter](https://git.adyxax.org/adyxax/zigfunge98). This code base contains a lot of tests (coverage is 96.7%), but I had to figure things out about testing zig code. Zig's documentation is improving but maybe these tips will help you on your journey.

## Testing

### Expects are backwards

The standard library's expect functions are all written backwards, the errors will tell you "error expected this but got that" where this and that are the opposites of what you would find in other languages. This should not be so much a big deal, but it is because of the way the types are inferred by the expect functions: the parameters need to be of the type of the first operrand. Because of that you need to either put what you test first, or repeat the types in all your tests!

This is an example of test that would write a correct error message:
```zig
fn whatever() u8 {
	return 4;
}
test "all" {
	try std.testing.expectEqual(4, whatever());
}
```

But it does not compile because the first parameter `4` does not have a type the compiler can guess. It could be a int of any size or even a float! For this to work you need:`
```zig
test "all" {
	try std.testing.expectEqual(@intCast(u8, 4), whatever());
}
```

The sad reality is that nobody wants to do that, therefore all testing code you will find in the wild does:
```zig
test "all" {
	try std.testing.expectEqual(whatever(), 4);
}
```

And when testing fails, for example if you replace `4` with `1` in this code you will get the backward message:
```
Test [27/33] test.all... expected 4, found 1
```

### Unit testing private declarations

To test public declarations you will quickly be used to top level tests like:
```zig
test "hello" {
    try std.testing.expectEqual(1, 0);
}
```

To test private declarations (like private struct fields), know that you can add test blocks inside the struct:
```zig
const Line = struct {
	x: i64 = 0,
	fn blank(l: *Line, x: i64) void {
		...
	}
	test "blank" {
		const l = Line{x: 1};
		try std.testing.expectEqual(l.x, 1);
	}
}
```

### Code coverage with kcov

Generating code coverage test reports in zig in easy but not well documented. I pieced together the following build.zig from a mix of documentation, stack overflow and reddit posts:
```zig
const std = @import("std");
pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("zigfunge98", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const coverage = b.option(bool, "test-coverage", "Generate test coverage") orelse false;
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    // Code coverage with kcov, we need an allocator for the setup
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = general_purpose_allocator.deinit();
    const gpa = general_purpose_allocator.allocator();
    // We want to exclude the $HOME/.zig path from the coverage report
    const home = std.process.getEnvVarOwned(gpa, "HOME") catch "";
    defer gpa.free(home);
    const exclude = std.fmt.allocPrint(gpa, "--exclude-path={s}/.zig/", .{home}) catch "";
    defer gpa.free(exclude);
    if (coverage) {
        exe_tests.setExecCmd(&[_]?[]const u8{
            "kcov",
            exclude,
            //"--path-strip-level=3", // any kcov flags can be specified here
            "kcov-output", // output dir for kcov
            null, // to get zig to use the --test-cmd-bin flag
        });
    }
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
```

Install the `kcov` tool from your OS' package repository, then run your tests with:
```sh
zig build test -Dtest-coverage
```

Open your coverage report with:
```sh
firefox kcov-output/index.html
```

## Conclusion

Testing in zig is simple and the tooling around `zig build test` is fantastic. Zig's build system is so extensible that we can bolt on the code coverage with external tools easily! But there are rough edges like the backward expects issue.

Zig is still young, I am sure the developers will nail the simple stuff as well as they nailed the hard stuff.
