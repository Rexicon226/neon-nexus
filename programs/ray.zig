// A Raytracer built with Neon Nexus

const std = @import("std");
const nexus = @import("nexus");

// Required for pulling symbols.
pub const os = nexus.os;
comptime {
    _ = @import("nexus").os;
}

const gfx = nexus.gfx.Graphics;
const gfx_mode = nexus.gfx.GraphicsModes;

var buffer: [1000]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buffer);
const allocator = fba.allocator();

const vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    fn init(x: f32, y: f32, z: f32) vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    inline fn normalize(self: vec3) vec3 {
        const mag = @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);

        return vec3.init(
            self.x / mag,
            self.y / mag,
            self.z / mag,
        );
    }

    inline fn cross(self: vec3, other: vec3) vec3 {
        return vec3.init(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x,
        );
    }

    inline fn sub(self: vec3, other: vec3) vec3 {
        return vec3.init(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
        );
    }

    inline fn dot(self: vec3, other: vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    inline fn mult(self: vec3, other: f32) vec3 {
        return vec3.init(
            self.x * other,
            self.y * other,
            self.z * other,
        );
    }

    inline fn add(self: vec3, other: vec3) vec3 {
        return vec3.init(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
        );
    }
};

const RGB = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn init(r: u8, g: u8, b: u8) RGB {
        return .{ .r = r, .g = g, .b = b };
    }

    pub fn fromVec3(v: vec3) RGB {
        std.debug.assert(v.x < 255 and v.y < 255 and v.z < 255);

        return RGB.init(
            @as(u8, @intFromFloat(v.x)),
            @as(u8, @intFromFloat(v.y)),
            @as(u8, @intFromFloat(v.z)),
        );
    }

    pub fn toVec3(self: RGB) vec3 {
        return vec3.init(
            @as(f32, @floatFromInt(self.r)),
            @as(f32, @floatFromInt(self.g)),
            @as(f32, @floatFromInt(self.b)),
        );
    }

    pub fn RGB2VGA(self: RGB) u8 {
        return ((self.b & 0xC0) >> 6) | ((self.g & 0xE0) >> 2) | ((self.r & 0xE0) >> 5);
    }
};

const vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    fn init(x: f32, y: f32, z: f32, w: f32) vec4 {
        return .{ .x = x, .y = y, .z = z, .w = w };
    }

    // Truncates, removing the w
    fn xyz(self: vec4) vec3 {
        return .{
            .x = self.x,
            .y = self.y,
            .z = self.z,
        };
    }

    inline fn mult(self: vec4, other: f32) vec4 {
        return vec4.init(
            self.x * other,
            self.y * other,
            self.z * other,
            self.w * other,
        );
    }
};

const mat4 = struct {
    buf: [4]vec4,

    pub fn init(vec_1: vec4, vec_2: vec4, vec_3: vec4, vec_4: vec4) mat4 {
        const buf = [4]vec4{ vec_1, vec_2, vec_3, vec_4 };
        return .{ .buf = buf };
    }

    fn multVec(self: mat4, other: vec4) vec4 {
        const row1 = self.buf[0].x * other.x + self.buf[0].y * other.y + self.buf[0].z * other.z + self.buf[0].w * other.w;
        const row2 = self.buf[1].x * other.x + self.buf[1].y * other.y + self.buf[1].z * other.z + self.buf[1].w * other.w;
        const row3 = self.buf[2].x * other.x + self.buf[2].y * other.y + self.buf[2].z * other.z + self.buf[2].w * other.w;
        const row4 = self.buf[3].x * other.x + self.buf[3].y * other.y + self.buf[3].z * other.z + self.buf[3].w * other.w;

        return vec4.init(row1, row2, row3, row4);
    }
};

const Ray = struct {
    origin: vec3,
    direction: vec3,

    pub fn init(origin: vec3, direction: vec3) Ray {
        return .{
            .origin = origin,
            .direction = direction,
        };
    }

    pub fn trace(self: Ray) u8 {
        _ = self;
        return 0;
    }
};

const Sphere = struct {
    position: vec3,
    radius: f32,
    color: RGB,

    pub fn init(position: vec3, radius: f32, color: RGB) Sphere {
        return .{
            .position = position,
            .radius = radius,
            .color = color,
        };
    }

    pub fn intersect(self: Sphere, ray: Ray) Intersection {
        const oc = ray.origin.sub(self.position);

        const a = ray.direction.dot(ray.direction);

        const b = 2.0 * oc.dot(ray.direction);

        const c = oc.dot(oc) - self.radius * self.radius;

        const discriminant: f32 = b * b - 4.0 * a * c;

        if (discriminant < 0.0) {
            return .{
                .hits = false,
                .position = vec3.init(0, 0, 0),
                .normal = vec3.init(0, 0, 0),
                .distance = 0,
                .color = self.color.toVec3(),
            };
        } else {
            const t = (-b - @sqrt(discriminant)) / (2.0 * a);
            const position = ray.origin.add(ray.direction.mult(t));

            const normal = position.sub(self.position).normalize();
            return .{
                .hits = true,
                .position = position,
                .normal = normal,
                .distance = t,
                .color = self.color.toVec3(),
            };
        }
    }
};

const Intersection = struct { hits: bool, position: vec3, normal: vec3, distance: f32, color: vec3 };

const Point = struct {
    x: u32,
    y: u32,
};

const Scene = struct {
    objects: std.ArrayList(Sphere),

    points: [4]Point,

    pub fn init() Scene {
        return .{ .objects = std.ArrayList(Sphere).init(allocator), .points = [4]Point{ Point{ .x = 0, .y = 0 }, Point{ .x = 0, .y = 0 }, Point{ .x = 0, .y = 0 }, Point{ .x = 0, .y = 0 } } };
    }

    pub fn add(self: *Scene, sphere: Sphere) !void {
        try self.objects.append(sphere);
    }

    fn intersect(self: Scene, ray: Ray) Intersection {
        var closest_intersection: Intersection = .{ .hits = false, .position = vec3.init(0, 0, 0), .normal = vec3.init(0, 0, 0), .distance = 0, .color = vec3.init(0, 0, 0) };

        for (self.objects.items) |sphere| {
            const hit = sphere.intersect(ray);

            if (hit.hits == true) {
                // Check if first hit.
                if (closest_intersection.hits == false) {
                    closest_intersection = sphere.intersect(ray);
                } else {
                    // Check if closer than previous hit.
                    if (hit.distance < closest_intersection.distance) {
                        closest_intersection = hit;
                    }
                }
            }
        }

        return closest_intersection;
    }

    pub fn trace(self: Scene, ray: Ray) u8 {
        const hit = self.intersect(ray);

        if (hit.hits == true) {
            const light_direction = vec3.init(-1.0, 2.0, -1.0).normalize();
            const diffuse_factor: f32 = @max(hit.normal.dot(light_direction), 0.0);
            const color: vec3 = hit.color.mult(diffuse_factor);
            return RGB.fromVec3(color).RGB2VGA();
        }

        return 0;
    }
};

pub fn main() !void {
    try gfx.init(gfx_mode.VGA_320x200x8bpp);

    gfx.clear(0xAC);

    const height = 200;
    const width = 320;

    var scene = Scene.init();

    var sphere = Sphere.init(vec3.init(0, 0, -20), 13, RGB.init(100, 100, 50));
    try scene.add(sphere);

    var camera_pos = vec3.init(0, 0, 0);
    var camera_dir = vec3.init(0.0, 0.0, -1.0);
    var camera_up = vec3.init(0.0, 1.0, 0.0);

    var camera_z = camera_dir.normalize();
    var camera_x = camera_up.cross(camera_z).normalize();
    var camera_y = camera_z.cross(camera_x);

    const view_matrix = mat4.init(vec4.init(camera_x.x, camera_y.x, camera_z.x, 0.0), vec4.init(camera_x.y, camera_y.y, camera_z.y, 0.0), vec4.init(camera_x.z, camera_y.z, camera_z.z, 0.0), vec4.init(0.0, 0.0, 0.0, 1.0));

    const aspect_ratio: f32 = @as(f32, @floatFromInt(width)) / @as(f32, @floatFromInt(height));

    for (0..width * height) |i| {
        const x = i % width;
        const y = i / width;
        const ndc_x: f32 = (2.0 * @as(f32, @floatFromInt(x)) / (width - 1.0)) - 1.0;
        const ndc_y: f32 = 1.0 - (2.0 * @as(f32, @floatFromInt(y)) / (height - 1.0));

        const ray_dir = (view_matrix.multVec(vec4.init(
            ndc_x * aspect_ratio,
            ndc_y,
            -1.0,
            0.0,
        ))).xyz().normalize();

        const ray = Ray.init(camera_pos, ray_dir);

        const result = scene.trace(ray);

        try gfx.drawPixel(@as(u16, @intCast(x)), @as(u16, @intCast(y)), result);
    }

    gfx.present();
}
