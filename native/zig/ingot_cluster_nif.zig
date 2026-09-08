//! Hot path: Zenoh-style key-expr match + FNV-1a hash. Zig NIF.

const std = @import("std");
const erl_nif = @cImport({
    @cInclude("erl_nif.h");
});

fn inspect_bin(env: *erl_nif.ErlNifEnv, term: erl_nif.ERL_NIF_TERM) ?[]const u8 {
    var bin: erl_nif.ErlNifBinary = undefined;
    if (erl_nif.enif_inspect_iolist_as_binary(env, term, &bin) == 0) return null;
    const p: [*]const u8 = @ptrCast(bin.data);
    return p[0..bin.size];
}

fn atom(env: *erl_nif.ErlNifEnv, name: [*c]const u8) erl_nif.ERL_NIF_TERM {
    return erl_nif.enif_make_atom(env, name);
}

fn err(env: *erl_nif.ErlNifEnv, name: [*c]const u8) erl_nif.ERL_NIF_TERM {
    return erl_nif.enif_make_tuple2(env, atom(env, "error"), atom(env, name));
}

/// Zenoh keyexpr: `*` one chunk, `**` any remainder. `/` is the separator.
fn key_match(pat: []const u8, key: []const u8) bool {
    return match(pat, 0, key, 0);
}

fn match(pat: []const u8, pi: usize, key: []const u8, ki: usize) bool {
    if (pi >= pat.len) return ki >= key.len;
    if (pat[pi] == '*' and pi + 1 < pat.len and pat[pi + 1] == '*') {
        var rest = pi + 2;
        if (rest < pat.len and pat[rest] == '/') rest += 1;
        var k = ki;
        while (true) {
            if (match(pat, rest, key, k)) return true;
            if (k >= key.len) return false;
            while (k < key.len and key[k] != '/') k += 1;
            if (k < key.len and key[k] == '/') k += 1;
        }
    }
    if (pat[pi] == '*') {
        var k = ki;
        while (k < key.len and key[k] != '/') k += 1;
        var next = pi + 1;
        if (next < pat.len and pat[next] == '/') next += 1;
        if (k < key.len and key[k] == '/') k += 1;
        return match(pat, next, key, k);
    }
    if (ki >= key.len) return false;
    if (pat[pi] != key[ki]) return false;
    return match(pat, pi + 1, key, ki + 1);
}

fn fnv1a(data: []const u8) u64 {
    var h: u64 = 0xcbf29ce484222325;
    for (data) |b| {
        h ^= b;
        h *%= 0x100000001b3;
    }
    return h;
}

export fn nif_key_match(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const pat = inspect_bin(env, argv[0]) orelse return err(env, "badarg");
    const key = inspect_bin(env, argv[1]) orelse return err(env, "badarg");
    return if (key_match(pat, key)) atom(env, "true") else atom(env, "false");
}

export fn nif_hash64(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err(env, "badarg");
    const h = fnv1a(data);
    return erl_nif.enif_make_uint64(env, h);
}

fn make_bin(env: *erl_nif.ErlNifEnv, data: []const u8) erl_nif.ERL_NIF_TERM {
    var bin: erl_nif.ErlNifBinary = undefined;
    if (erl_nif.enif_alloc_binary(data.len, &bin) == 0) return err(env, "enomem");
    @memcpy(bin.data[0..data.len], data);
    return erl_nif.enif_make_binary(env, &bin);
}

export fn nif_blake3(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err(env, "badarg");
    var out: [32]u8 = undefined;
    std.crypto.hash.Blake3.hash(data, &out, .{});
    return make_bin(env, &out);
}

export fn nif_xxh3(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err(env, "badarg");
    const h = std.hash.XxHash3.hash(0, data);
    return erl_nif.enif_make_uint64(env, h);
}

const dirty_cpu: c_uint = erl_nif.ERL_NIF_DIRTY_JOB_CPU_BOUND;

var nif_funcs = [_]erl_nif.ErlNifFunc{
    .{ .name = @as([*]const u8, @ptrCast("key_match")), .arity = 2, .fptr = @ptrCast(&nif_key_match), .flags = dirty_cpu },
    .{ .name = @as([*]const u8, @ptrCast("hash64")), .arity = 1, .fptr = @ptrCast(&nif_hash64), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("blake3")), .arity = 1, .fptr = @ptrCast(&nif_blake3), .flags = dirty_cpu },
    .{ .name = @as([*]const u8, @ptrCast("xxh3")), .arity = 1, .fptr = @ptrCast(&nif_xxh3), .flags = dirty_cpu },
};

var nif_entry = erl_nif.ErlNifEntry{
    .major = erl_nif.ERL_NIF_MAJOR_VERSION,
    .minor = erl_nif.ERL_NIF_MINOR_VERSION,
    .name = @as([*]const u8, @ptrCast("Elixir.IngotCluster.Native")),
    .num_of_funcs = nif_funcs.len,
    .funcs = @as([*]erl_nif.ErlNifFunc, &nif_funcs),
    .load = null,
    .reload = null,
    .upgrade = null,
    .unload = null,
    .vm_variant = @as([*]const u8, @ptrCast(erl_nif.ERL_NIF_VM_VARIANT)),
    .options = 1,
    .sizeof_ErlNifResourceTypeInit = @sizeOf(erl_nif.ErlNifResourceTypeInit),
    .min_erts = null,
};

export fn nif_init() callconv(.c) [*c]erl_nif.ErlNifEntry {
    return &nif_entry;
}
