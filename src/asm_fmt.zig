const std = @import("std");

const ascii = std.ascii;
const fmt = std.fmt;
const io = std.io;
const unicode = std.unicode;

const String = []const u8;

const Statement = struct {
    instruction: String,
    params: []const String, // Parameters
    comment: String, // Without slashes
    function: bool, // Probably define call
    continued: bool, // Multiline statement, continues on next line
    contComment: bool, // Multiline statement, comment only

    const Self = @This();

    // Return true if this line should be at indentation level 0.
    pub fn level0(self: Self) bool {
        return self.isLabel() or self.isText() or self.isGlobal();
    }

    // Will return true if the statement is a label.
    pub fn isLabel(self: Self) bool {
        return std.ascii.endsWithIgnoreCase(self.instruction, ":");
    }

    // isPreProcessor will return if the statement is a preprocessor statement.
    pub fn isPreProcessor(self: Self) bool {
        return std.ascii.startsWithIgnoreCase(self.instruction, "#");
    }

    // isGlobal returns true if the current instruction is
    // a global. Currently that is DATA, GLOBL, FUNCDATA and PCDATA
    pub fn isGlobal(self: Self) bool {
        var buf: [256]u8 = undefined;
        const up = ascii.upperString(&buf, self.instruction);
        _ = up; // autofix
        // switch (up) {
        //     "DATA", "GLOBL", "FUNCDATA", "PCDATA" => return true,
        //     else => return false,
        // }
        return true;
    }

    // isText returns true if the instruction is "TEXT"
    // or one of the "isGlobal" types
    pub fn isText(self: Self) bool {
        return std.ascii.eqlIgnoreCase(self.instruction, "TEXT") || self.isGlobal();
    }

    // We attempt to identify "terminators", after which
    // indentation is likely to be level 0.
    pub fn isTerminator(self: Self) bool {
        var buf: [256]u8 = undefined;
        const up = ascii.upperString(&buf, self.instruction);
        return std.ascii.eqlIgnoreCase(up, "RET") || self.ascii.eqlIgnoreCase(up, "JMP");
    }

    // Detects commands based on case.
    pub fn isCommand(self: Self) bool {
        if (self.isLabel()) {
            return false;
        }
        var buf: [256]u8 = undefined;
        return std.mem.eql(std.ascii.upperString(&buf, self.instruction), self.instruction);
    }

    // Detect if last character is '\', indicating a multiline statement.
    pub fn willContinued(self: Self) bool {
        if (self.continued) {
            return true;
        }
        if (self.params.len) {
            return false;
        }
        return std.ascii.endsWithIgnoreCase(self.params, "\\");
    }

    // define returns the macro defined in this line.
    // if none is defined "" is returned.
    pub fn define(self: Self) String {
        if (std.ascii.eqlIgnoreCase(self.instruction, "#define") and self.params.len > 0) {
            var it = std.mem.tokenizeAny(self.params[0], "(");
            const value = it.next().?;
            var r = std.mem.trim(u8, value, std.ascii.whitespace);
            r = std.mem.trim(u8, r, "\\");
            return r;
        }
        return "";
    }

    pub fn clearParams(self: *Self) void {
        // Remove whitespace before semicolons
        if (std.ascii.endsWithIgnoreCase(self.instruction, ";")) {
            const s = std.mem.trim(u8, self.instruction, ";");
            self.instruction = std.mem.trim(u8, s, std.ascii.whitespace);
        }
    }
};

const Fstate = struct {
    out: std.ArrayList([]const u8),
    insideBlock: bool, // Block comment
    indentation: u8, // Indentation level
    lastEmpty: bool,
    lastComment: bool,
    lastStar: bool, // Block comment, last line started with a star
    lastLabel: bool,
    anyContents: bool,
    lastContinued: bool, // Last line continued
    queued: ?[]Statement,
    comments: ?[]const String,
    defines: std.StringHashMap(String),

    const Self = @This();

    // indent the current line with current indentation.
    pub fn indent(self: *Self) void {
        for (0..self.indentation) |_| {
            self.out.writer().writeByte('\t');
        }
    }

    pub fn addLine(self: *Self) void!anyerror {
        _ = self; // autofix
    }

    // flush any queued comments and commands
    pub fn flush(self: *Self) void {
        for (self.comments.?) |line| {
            self.indent();
            self.out.appendSlice(line);
        }
        self.comments = null;
        const stat = formatStatements(self.queued.?);
        for (stat) |line| {
            self.indent();
            self.out.appendSlice(line);
        }
        self.queued = null;
    }

    // Add a newline, unless last line was empty or a comment
    pub fn newLine(self: *Self) void {
        // Always newline before comment-only line.
        if (!self.lastEmpty and !self.lastComment and !self.lastLabel and self.anyContents) {
            self.out.writer().writeByte('\n');
        }
    }
};

pub fn newStatement(s: String, defs: std.StringHashMap(String)) ?*Statement {
    _ = s; // autofix
    _ = defs; // autofix
}

// formatStatements will format a slice of statements and return each line
// as a separate string.
// Comments and line-continuation (\) are aligned with spaces.
pub fn formatStatements(st: []const Statement) []const String {
    _ = st; // autofix
}
