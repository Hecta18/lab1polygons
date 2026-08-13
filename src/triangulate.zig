const std = @import("std");
const rl = @import("raylib");

fn cross(o: rl.Vector2, a: rl.Vector2, b: rl.Vector2) f32 {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
}

fn pointInTriangle(p: rl.Vector2, a: rl.Vector2, b: rl.Vector2, c: rl.Vector2) bool {
    const d1 = cross(p, a, b);
    const d2 = cross(p, b, c);
    const d3 = cross(p, c, a);
    const hasNeg = (d1 < 0) or (d2 < 0) or (d3 < 0);
    const hasPos = (d1 > 0) or (d2 > 0) or (d3 > 0);
    return !(hasNeg and hasPos);
}

// Returns a caller-owned slice of triangle indices (3 per triangle).
fn triangulate(allocator: std.mem.Allocator, verts: []const rl.Vector2) ![]usize {
    var indices = std.ArrayList(usize).init(allocator);
    defer indices.deinit();
    var idx = std.ArrayList(usize).init(allocator);
    defer idx.deinit();
    for (0..verts.len) |i| try idx.append(i);

    while (idx.items.len > 3) {
        var earFound = false;
        var i: usize = 0;
        while (i < idx.items.len) : (i += 1) {
            const prev = idx.items[(i + idx.items.len - 1) % idx.items.len];
            const curr = idx.items[i];
            const next = idx.items[(i + 1) % idx.items.len];

            if (cross(verts[prev], verts[curr], verts[next]) <= 0) continue; // reflex, skip

            var isEar = true;
            for (idx.items) |j| {
                if (j == prev or j == curr or j == next) continue;
                if (pointInTriangle(verts[j], verts[prev], verts[curr], verts[next])) {
                    isEar = false;
                    break;
                }
            }
            if (isEar) {
                try indices.append(prev);
                try indices.append(curr);
                try indices.append(next);
                _ = idx.orderedRemove(i);
                earFound = true;
                break;
            }
        }
        if (!earFound) break; // degenerate polygon, bail out
    }
    if (idx.items.len == 3) {
        try indices.append(idx.items[0]);
        try indices.append(idx.items[1]);
        try indices.append(idx.items[2]);
    }
    return indices.toOwnedSlice();
}