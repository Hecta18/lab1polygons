const std = @import("std");
const rl = @import("raylib");

const Poly = struct {
    verts: []const rl.Vector2,
    fc: rl.Color,
    lc: rl.Color,
    tris: []const usize = &.{}, // filled in at startup by triangulate()
};

// --- Ear clipping ---
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

fn signedArea(verts: []const rl.Vector2) f32 {
    var sum: f32 = 0;
    for (0..verts.len) |i| {
        const a = verts[i];
        const b = verts[(i + 1) % verts.len];
        sum += (a.x * b.y) - (b.x * a.y); // producto cruz
    }
    return sum * 0.5;
}

/// Triangulates a simple polygon (convex or concave, no self-intersections
/// or holes) via ear clipping. Returns a caller-owned slice of vertex
/// indices, 3 per triangle.
fn triangulate(allocator: std.mem.Allocator, verts: []const rl.Vector2) ![]usize {
    var indices = try std.ArrayList(usize).initCapacity(allocator, 10);

    errdefer indices.deinit(allocator);

    var idx = try std.ArrayList(usize).initCapacity(allocator, 10);
    defer idx.deinit(allocator);
    for (0..verts.len) |i| try idx.append(allocator, i);

    // Ear clipping assumes CCW winding; flip the reflex-test sign if the
    // input polygon is CW (e.g. authored in screen space with y-down).
    const ccw = signedArea(verts) > 0;

    while (idx.items.len > 3) {
        var earFound = false;
        var i: usize = 0;
        while (i < idx.items.len) : (i += 1) {
            const prev = idx.items[(i + idx.items.len - 1) % idx.items.len];
            const curr = idx.items[i];
            const next = idx.items[(i + 1) % idx.items.len];

            const c = cross(verts[prev], verts[curr], verts[next]);
            const isConvex = if (ccw) c > 0 else c < 0;
            if (!isConvex) continue; // reflex vertex, can't be an ear

            var isEar = true;
            for (idx.items) |j| {
                if (j == prev or j == curr or j == next) continue;
                if (pointInTriangle(verts[j], verts[prev], verts[curr], verts[next])) {
                    isEar = false;
                    break;
                }
            }
            if (isEar) {
                try indices.append(allocator, prev);
                try indices.append(allocator, curr);
                try indices.append(allocator, next);
                _ = idx.orderedRemove(i);
                earFound = true;
                break;
            }
        }
        if (!earFound) break; // degenerate input; stop rather than loop forever
    }
    if (idx.items.len == 3) {
        try indices.append(allocator, idx.items[0]);
        try indices.append(allocator, idx.items[1]);
        try indices.append(allocator, idx.items[2]);
    }
    return indices.toOwnedSlice(allocator);
}

// --- Drawing ---

inline fn drawTriangulated(verts: []const rl.Vector2, tris: []const usize, fillColor: rl.Color) void {
    var i: usize = 0;
    while (i < tris.len) : (i += 3) {
        rl.drawTriangle(verts[tris[i]], verts[tris[i + 1]], verts[tris[i + 2]], fillColor);
    }
}

inline fn drawPolygonOutline(puntos: []const rl.Vector2, lineColor: rl.Color, thickness: f32) void {
    const n = puntos.len;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        rl.drawLineEx(puntos[i], puntos[(i + 1) % n], thickness, lineColor);
    }
}

// --- Data ---

const p1 = [_]rl.Vector2{ rl.Vector2.init(165, 380), rl.Vector2.init(185, 360), rl.Vector2.init(180, 330), rl.Vector2.init(207, 345), rl.Vector2.init(233, 330), rl.Vector2.init(230, 360), rl.Vector2.init(250, 380), rl.Vector2.init(220, 385), rl.Vector2.init(205, 410), rl.Vector2.init(193, 383) };
const p2 = [_]rl.Vector2{ rl.Vector2.init(321, 335), rl.Vector2.init(288, 286), rl.Vector2.init(339, 251), rl.Vector2.init(374, 302) };
const p3 = [_]rl.Vector2{ rl.Vector2.init(377, 249), rl.Vector2.init(411, 197), rl.Vector2.init(436, 249) };
const p4 = [_]rl.Vector2{ rl.Vector2.init(413, 177), rl.Vector2.init(448, 159), rl.Vector2.init(502, 88), rl.Vector2.init(553, 53), rl.Vector2.init(535, 36), rl.Vector2.init(676, 37), rl.Vector2.init(660, 52), rl.Vector2.init(750, 145), rl.Vector2.init(761, 179), rl.Vector2.init(672, 192), rl.Vector2.init(659, 214), rl.Vector2.init(615, 214), rl.Vector2.init(632, 230), rl.Vector2.init(580, 230), rl.Vector2.init(597, 215), rl.Vector2.init(552, 214), rl.Vector2.init(517, 144), rl.Vector2.init(466, 180) };
const p5 = [_]rl.Vector2{ rl.Vector2.init(682, 175), rl.Vector2.init(708, 120), rl.Vector2.init(735, 148), rl.Vector2.init(739, 170) };

const white = rl.Color.init(255, 255, 255, 255);

var polygons = [_]Poly{
    .{ .verts = p1[0..], .fc = rl.Color.init(144, 238, 144, 255), .lc = rl.Color.init(0, 100, 0, 255) },
    .{ .verts = p2[0..], .fc = rl.Color.init(173, 216, 230, 255), .lc = rl.Color.init(0, 0, 139, 255) },
    .{ .verts = p3[0..], .fc = rl.Color.init(255, 255, 0, 255), .lc = rl.Color.init(255, 165, 0, 255) },
    .{ .verts = p4[0..], .fc = rl.Color.init(255, 182, 193, 255), .lc = rl.Color.init(139, 0, 0, 255) },
    .{ .verts = p5[0..], .fc = white, .lc = white },
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Triangulate every polygon once, up front.
    for (&polygons) |*p| {
        p.tris = try triangulate(allocator, p.verts);
    }
    defer for (polygons) |p| allocator.free(p.tris);

    rl.initWindow(800, 500, "Relleno de Polígonos");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(white);
        for (polygons) |p| {
            drawTriangulated(p.verts, p.tris, p.fc);
            drawPolygonOutline(p.verts, p.lc, 2);
        }
        rl.endDrawing();
    }
}
