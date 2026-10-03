# Data.UUID API Reference

## Types

### Data.UUID — Pure Spec
| Name | Kind | Description |
|------|------|-------------|
| `uuid` | record | 16 bytes — `time_low` (4), `time_mid` (2), `time_hi_and_version` (2), `clock_seq_hi_and_reserved` (1), `clock_seq_low` (1), `node` (6) |
| `uuid_codec` | `codec uuid` | raw 16-byte codec (RFC field order), `count 16 token` over `equiv_map` |

### Data.UUID.Pulse — Extractable Leaf
| Name | Kind | Description |
|------|------|-------------|
| `uuid16` | record | flat 16-byte C-representable record (not the nested `uuid`) |
| `opt_uuid16` | sum | `OU16_None` / `OU16_Some of (uuid16 & U32.t)` |

## Accessors

| Function | Signature | Description |
|----------|-----------|-------------|
| `uuid_variant` | `uuid -> nat` | RFC 9562 §4.2 variant (0..3) |
| `uuid_version` | `uuid -> nat` | RFC 9562 §4.2 version (0..15) |
| `uuid_nil` | `uuid` | the all-zero UUID (RFC 9562 §5.7) |

## Codec

| Function | Signature | Description |
|----------|-----------|-------------|
| `encode_uuid` | `uuid -> byte_seq` | raw 16-byte encoding |
| `decode_uuid` | `byte_seq -> option uuid` | raw 16-byte decoding |

## Pulse leaf

| Function | Signature | Description |
|----------|-----------|-------------|
| `encode_uuid16` | `fn (uuid16) (A.array U8.t) (U32.t) -> U32.t` | write 16 bytes, returns `16ul` |
| `decode_uuid16` | `fn (A.array U8.t) (U32.t) -> opt_uuid16` | read 16 bytes |
| `lemma_pulse_uuid16_roundtrip` | Pulse `fn` | encode then decode preserves the value |
| `encode16_spec` / `decode16_spec` | `noextract` pure | the byte-level spec mirror |
| `uuid16_of_indices` | `noextract` pure | pointwise reconstruction from `Seq.index` |

## Lemmas

| Lemma | Proves |
|-------|--------|
| `lemma_uuid_variant_range` | `uuid_variant u < 4` |
| `lemma_uuid_version_range` | `uuid_version u < 16` |
| `lemma_uuid_nil_variant_version` | nil has variant 0 and version 0 |
| `lemma_uuid_example_version` | example `00112233-4455-4677-8899-aabbccddeeff` has version 4 |
| `lemma_uuid_example_variant` | example has variant 2 (binary 10xx) |
| `lemma_decode16_encode16_spec` | pure `decode16_spec (encode16_spec u) == Some (u, 16ul)` |
