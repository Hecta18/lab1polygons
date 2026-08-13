const rl = @import("raylib");
const tr = @import("triangulate.zig");

const Poly = struct { verts: []const rl.Vector2, fc: rl.Color, lc: rl.Color };

inline fn drawPolygonOutline(puntos: []const rl.Vector2, lineColor: rl.Color, thickness: f32) void {
    const n = puntos.len;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        rl.drawLineEx(puntos[i], puntos[(i + 1) % n], thickness, lineColor);
    }
}

const p1 = [_]rl.Vector2{ rl.Vector2.init(193, 383), rl.Vector2.init(205, 410), rl.Vector2.init(220, 385), rl.Vector2.init(250, 380), rl.Vector2.init(230, 360), rl.Vector2.init(233, 330), rl.Vector2.init(207, 345), rl.Vector2.init(180, 330), rl.Vector2.init(185, 360), rl.Vector2.init(165, 380) };
const p2 = [_]rl.Vector2{ rl.Vector2.init(374, 302), rl.Vector2.init(339, 251), rl.Vector2.init(288, 286), rl.Vector2.init(321, 335) };
const p3 = [_]rl.Vector2{ rl.Vector2.init(436, 249), rl.Vector2.init(411, 197), rl.Vector2.init(377, 249) };
const p4 = [_]rl.Vector2{ rl.Vector2.init(466, 180), rl.Vector2.init(517, 144), rl.Vector2.init(552, 214), rl.Vector2.init(597, 215), rl.Vector2.init(580, 230), rl.Vector2.init(632, 230), rl.Vector2.init(615, 214), rl.Vector2.init(659, 214), rl.Vector2.init(672, 192), rl.Vector2.init(761, 179), rl.Vector2.init(750, 145), rl.Vector2.init(660, 52), rl.Vector2.init(676, 37), rl.Vector2.init(535, 36), rl.Vector2.init(553, 53), rl.Vector2.init(502, 88), rl.Vector2.init(448, 159), rl.Vector2.init(413, 177) };
const p5 = [_]rl.Vector2{ rl.Vector2.init(739, 170), rl.Vector2.init(735, 148), rl.Vector2.init(708, 120), rl.Vector2.init(682, 175) };

const white = rl.Color.init(255, 255, 255, 255);

const polygons = [_]Poly{
    .{ .verts = p1[0..], .fc = rl.Color.init(144, 238, 144, 255), .lc = rl.Color.init(0, 100, 0, 255) },
    .{ .verts = p2[0..], .fc = rl.Color.init(173, 216, 230, 255), .lc = rl.Color.init(0, 0, 139, 255) },
    .{ .verts = p3[0..], .fc = rl.Color.init(255, 255, 0, 255), .lc = rl.Color.init(255, 165, 0, 255) },
    .{ .verts = p4[0..], .fc = rl.Color.init(255, 182, 193, 255), .lc = rl.Color.init(139, 0, 0, 255) },
    .{ .verts = p5[0..], .fc = white, .lc = white },
};

pub fn main() void {
    rl.initWindow(800, 500, "Relleno de Polígonos");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(white);
        for (polygons) |p| {
            const triangles = tr.triangulate(p.verts);
            for (triangles) |t| {
                rl.drawTriangle(t[0], t[1], t[2], p.fc);
            }
            drawPolygonOutline(p.verts, p.lc, 2);
        }
        rl.endDrawing();
    }
}
