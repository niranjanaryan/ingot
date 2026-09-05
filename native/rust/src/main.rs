//! Rust baseline for Zenoh-style key match (no NIF).

fn key_match(pat: &str, key: &str) -> bool {
    match_at(pat.as_bytes(), 0, key.as_bytes(), 0)
}

fn match_at(pat: &[u8], mut pi: usize, key: &[u8], mut ki: usize) -> bool {
    loop {
        if pi >= pat.len() {
            return ki >= key.len();
        }
        if pat[pi] == b'*' && pi + 1 < pat.len() && pat[pi + 1] == b'*' {
            pi += 2;
            if pi < pat.len() && pat[pi] == b'/' {
                pi += 1;
            }
            loop {
                if match_at(pat, pi, key, ki) {
                    return true;
                }
                if ki >= key.len() {
                    return false;
                }
                while ki < key.len() && key[ki] != b'/' {
                    ki += 1;
                }
                if ki < key.len() && key[ki] == b'/' {
                    ki += 1;
                }
            }
        }
        if pat[pi] == b'*' {
            while ki < key.len() && key[ki] != b'/' {
                ki += 1;
            }
            pi += 1;
            if pi < pat.len() && pat[pi] == b'/' {
                pi += 1;
            }
            if ki < key.len() && key[ki] == b'/' {
                ki += 1;
            }
            continue;
        }
        if ki >= key.len() || pat[pi] != key[ki] {
            return false;
        }
        pi += 1;
        ki += 1;
    }
}

fn main() {
    let n: u64 = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(200_000);
    let pat = "ingot/cluster/**";
    let key = "ingot/cluster/us-east/node-1";
    let start = std::time::Instant::now();
    let mut ok = 0u64;
    for _ in 0..n {
        if key_match(pat, key) {
            ok += 1;
        }
    }
    let s = start.elapsed().as_secs_f64();
    println!("rust_key_match iters={n} ok={ok} ips={:.0}", n as f64 / s);
}
