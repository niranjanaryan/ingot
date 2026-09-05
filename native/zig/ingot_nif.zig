const erl_nif = @cImport({
    @cInclude("erl_nif.h");
});

fn inspect_bin(env: *erl_nif.ErlNifEnv, term: erl_nif.ERL_NIF_TERM) ?[]const u8 {
    var bin: erl_nif.ErlNifBinary = undefined;
    if (erl_nif.enif_inspect_iolist_as_binary(env, term, &bin) == 0) return null;
    const p: [*]const u8 = @ptrCast(bin.data);
    return p[0..bin.size];
}

fn fnv1a(data: []const u8) u64 {
    var h: u64 = 0xcbf29ce484222325;
    for (data) |b| {
        h ^= b;
        h *%= 0x100000001b3;
    }
    return h;
}

export fn nif_hash64(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse {
        return erl_nif.enif_make_tuple2(env, erl_nif.enif_make_atom(env, "error"), erl_nif.enif_make_atom(env, "badarg"));
    };
    return erl_nif.enif_make_uint64(env, fnv1a(data));
}

var nif_funcs = [_]erl_nif.ErlNifFunc{
    .{ .name = @as([*]const u8, @ptrCast("hash64")), .arity = 1, .fptr = @ptrCast(&nif_hash64), .flags = 0 },
};

var nif_entry = erl_nif.ErlNifEntry{
    .major = erl_nif.ERL_NIF_MAJOR_VERSION,
    .minor = erl_nif.ERL_NIF_MINOR_VERSION,
    .name = @as([*]const u8, @ptrCast("Elixir.Ingot.Native")),
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
