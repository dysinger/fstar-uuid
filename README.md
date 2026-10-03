# uuid — RFC 9562 universally unique identifiers

`Data.UUID` implements UUIDs per RFC 9562.

## Modules

| Module | Purpose |
|--------|---------|
| `Data.UUID` | Pure spec: the `uuid` type, variant/version accessors, the raw 16-byte `codec`, and 0-admit lemmas |
| `Data.UUID.Pulse` | C/OCaml/F#-extractable Pulse leaf: raw 16-byte buffer encode/decode over `Pulse.Lib.Array` |

## RFC coverage

| Feature | RFC 9562 | Notes |
|---------|----------|-------|
| UUID type (16 bytes) | §4.1 | `uuid` record, field-grouped per the RFC layout |
| Variant (`uuid_variant`, 0..3) | §4.2 | high two bits of `clock_seq_hi_and_reserved` |
| Version (`uuid_version`, 0..15) | §4.2 | high nibble of `time_hi_and_version` |
| Nil UUID | §5.7 | `uuid_nil`, all zero bytes |
| Raw 16-byte codec | §4 | `uuid_codec : codec uuid` via `count 16 token` |

## Build

```bash
nix build .#checked   # F* verification gate (0-admit)
nix build .#native    # C11 shared/static lib (default)
nix build .#fsharp    # .NET library
nix build .#ocaml     # OCaml findlib package
nix fmt               # format nix files (treefmt)
nix develop && make check   # dev loop (no nix)
```

The `codec` dependency is injected as a flake input (`github:dysinger/fstar-codec`),
its source as `codec-src` and its pre-verified `.checked` set as `codec-checked`.
