# uuid — Agent Guide & Handoff

`Data.UUID` — verified RFC 9562 universally unique identifiers, extracted from
the xeno monorepo (`uuid/`) as a standalone repo.  Part of
`round2-custard-migration` (the first Round-2 package, chosen as the pilot
because it is record-codec-clean and depends only on `fstar-codec`).  F* source
is 0-admit.

## Build commands

```bash
nix build .#checked    # F* verification gate (0-admit)
nix build .#native     # C11 shared/static lib (default)
nix build .#fsharp     # .NET library
nix build .#ocaml      # OCaml findlib package
nix fmt                 # format nix files (treefmt)
nix develop && make check   # dev loop (no nix)
```

## Module split

- **`Data.UUID`** (pure) — the `uuid` type, `uuid_variant`/`uuid_version`
  accessors, `uuid_nil`, and `uuid_codec : codec uuid` (= `equiv_map` over
  `count 16 token`).  The combinator carries the generic roundtrip proof; this
  module adds only the provable byte-arithmetic lemmas (variant/version ranges
  + nil/example concrete vectors).  **Do NOT re-derive `dec (enc v)` per-value**
  — that is §18-opaque for a combinator-composed codec (fstar-proofs §15/§58).
- **`Data.UUID.Pulse`** (`#lang-pulse`) — the extractable leaf.  **`uuid16` is a
  FLAT 16-byte record, not the nested `uuid`** (nested tuples have no C repr).
  The encode/decode `ensures` are **POINTWISE** (`Seq.index s1 (off+N) == byteN`
  per byte), NOT `seq_of_list`/`slice` whole-buffer equalities — the 16-layer
  `Seq.upd`/`seq_to_list` chain exceeds SMT's ~12-layer unwind limit
  (fstar-proofs §11/§18).  `uuid16_of_indices` carries the
  `off + 15 < Seq.length s` refinement so the decoder `ensures` term is typed.

## Key gotchas (learned this session)

- **The codec record's `.roundtrip`/`.wfcv`/`.rest_cond` fields are opaque for
  combinator-composed codecs** (§18).  Never call `uuid_codec.roundtrip` from a
  separate module; the combinator proves roundtrip generically.  Concrete test
  vectors are regression *anchors*, not re-proven `dec (enc v)` facts.
- **16 raw bytes exceed the proven 4-byte-write ceiling.**  The reference
  `fstar-codec` `Data.Codec.Pulse` never writes >4 bytes per `fn`; basen tops at
  4.  A 16-byte fixed struct needs the pointwise-`ensures` pattern above.
- **`--split_queries` is removed in v2026.09.20** (one SMT query per obligation);
  don't reach for it.

## Reference

- Canonical shape: `fstar-basen` (its `default.nix`, `flake.nix`, `Makefile`,
  `Data.BaseN.Pulse`) is the library-with-codec-dep reference this repo
  mirrors (see `https://github.com/dysinger/fstar-basen`).
- F\* skills: `~/.pi/agent/skills/fstar/fstar-2026.09.20/SKILL.md` (Custard/Pulse)
  and `fstar-proofs` §11/§15/§18/§58 (Seq opacity + the 16-byte bridge).
- OpenSpec change (monorepo): `round2-custard-migration` (origin repo
  `openspec/changes/`).
