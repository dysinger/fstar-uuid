(* Copyright 2026 Department of Code LLC.
   SPDX-License-Identifier: AGPL-3.0-or-later *)

(**
Data.UUID — Universally Unique Identifier (RFC 9562), pure spec.

A UUID is a 128-bit (16-byte) identifier.  This module defines the pure
[uuid] type, the constant UUID values, the variant/version accessors, and a
raw-16-byte [codec uuid] built from [Data.Codec] combinators ([count] of
[token], lifted through [equiv_map]).  The C extraction layer lives in
[Data.UUID.Pulse].

The [codec] combinator carries its own generic roundtrip proof; this module
adds concrete test vectors (nil + a fixed non-nil UUID) and the variant/version
range lemmas, all 0-admit.

@header Data.UUID

@section Type
- [uuid] — 16 bytes, grouped per RFC 9562 §4.1

@section Constants
- [uuid_example] — a fixed non-nil UUID for concrete vectors
- [uuid_nil] — the all-zero UUID

@section Accessors
- [uuid_variant] — the RFC 9562 §4.2 variant (0..3)
- [uuid_version] — the RFC 9562 §4.2 version (0..15)

@section Codec
- [uuid_codec] — raw 16-byte [codec uuid]
- [decode_uuid] / [encode_uuid] — byte-sequence helpers

@section Lemmas
- variant/version range + concrete-vector lemmas (all 0-admit)
*)
module Data.UUID

open Data.Codec
open Data.Codec.Types

module U8 = FStar.UInt8


(* ── Type ───────────────────────────────────────────────────────────── *)


(** A UUID: 16 bytes, grouped per RFC 9562 §4.1.

    [time_low], [time_mid], [time_hi_and_version], [clock_seq], and [node]
    mirror the RFC field layout.  Each field is a [U8.t]. *)
type uuid = {
  time_low                  : U8.t & U8.t & U8.t & U8.t;
  time_mid                  : U8.t & U8.t;
  time_hi_and_version       : U8.t & U8.t;
  clock_seq_hi_and_reserved : U8.t;
  clock_seq_low             : U8.t;
  node                      : U8.t & U8.t & U8.t & U8.t & U8.t & U8.t;
}


(* ── Constants ──────────────────────────────────────────────────────── *)


(** A fixed non-nil UUID (version 4, variant 10xx / RFC 9562 §4.1/§4.2) for concrete
    vectors: `00112233-4455-4677-8899-aabbccddeeff`.

    The version is the high nibble of the 7th byte (0x46 → 4); the variant is
    the high two bits of the 9th byte (0x88 → 10xx, i.e. 2). *)
let uuid_example : uuid = {
  time_low = (0x00uy, 0x11uy, 0x22uy, 0x33uy);
  time_mid = (0x44uy, 0x55uy);
  time_hi_and_version = (0x46uy, 0x77uy);
  clock_seq_hi_and_reserved = 0x88uy;
  clock_seq_low = 0x99uy;
  node = (0xAAuy, 0xBBuy, 0xCCuy, 0xDDuy, 0xEEuy, 0xFFuy);
}


(** The nil UUID: all 16 bytes zero (RFC 9562 §5.7). *)
let uuid_nil : uuid = {
  time_low = (0uy, 0uy, 0uy, 0uy);
  time_mid = (0uy, 0uy);
  time_hi_and_version = (0uy, 0uy);
  clock_seq_hi_and_reserved = 0uy;
  clock_seq_low = 0uy;
  node = (0uy, 0uy, 0uy, 0uy, 0uy, 0uy);
}


(* ── Accessors ──────────────────────────────────────────────────────── *)


(** The RFC 9562 §4.2 variant: the high two bits of
    [clock_seq_hi_and_reserved] (a [nat] in 0..3). *)
let uuid_variant (u: uuid) : nat =
  U8.v u.clock_seq_hi_and_reserved / 64


(** The RFC 9562 §4.2 version: the high nibble of [time_hi_and_version]
    (a [nat] in 0..15). *)
let uuid_version (u: uuid) : nat =
  let (b, _) = u.time_hi_and_version in
  U8.v b / 16


(* ── Codec: raw 16 bytes in RFC field order ─────────────────────────── *)


(** The raw-16-byte UUID codec, in RFC field order.

    Built from [count 16 token] (a 16-byte run) lifted to the [uuid] record
    through [equiv_map].  The combinator's [roundtrip] field carries the
    generic proof; the [uuid] lifting functions are exact inverses.

    The scoped [--z3rlimit 40] is a targeted raise over the Makefile's global
    120 default: the 16-element list pattern-match in the [equiv_map] pruning
    function dispatches 17 obligations, and 40 keeps the whole codec's VCs
    under a single stable budget without relying on the (now-removed)
    `--split_queries`.) *)
#push-options "--z3rlimit 40"
let uuid_codec : codec uuid =
  let raw : codec (list byte) = count 16 token in
  equiv_map
    (fun (bs: list byte) ->
      match bs with
      | [b0;b1;b2;b3; b4;b5;b6;b7; b8;b9;b10;b11; b12;b13;b14;b15] ->
        Some ({ time_low = (b0,b1,b2,b3);
                time_mid = (b4,b5);
                time_hi_and_version = (b6,b7);
                clock_seq_hi_and_reserved = b8;
                clock_seq_low = b9;
                node = (b10,b11,b12,b13,b14,b15) })
      | _ -> None)
    (fun u ->
      let (a,b,c,d) = u.time_low in
      let (e,f) = u.time_mid in
      let (g,h) = u.time_hi_and_version in
      let (i,j,k,l,m,n) = u.node in
      Some [a;b;c;d; e;f;g;h; u.clock_seq_hi_and_reserved; u.clock_seq_low; i;j;k;l;m;n])
    raw
#pop-options


(** Decode a UUID from a byte sequence (raw 16 bytes). *)
let decode_uuid (input: byte_seq) : option uuid =
  match uuid_codec.dec input with
  | Inl _ -> None
  | Inr (v, _) -> Some v


(** Encode a UUID to its raw 16-byte sequence. *)
let encode_uuid (u: uuid) : byte_seq = uuid_codec.enc u


(* ── Lemmas (0-admit) ───────────────────────────────────────────────── *)


(** The example UUID reports variant 2 (binary 10xx). *)
let lemma_uuid_example_variant ()
  : Lemma (uuid_variant uuid_example == 2)
  = ()


(** The example UUID reports version 4. *)
let lemma_uuid_example_version ()
  : Lemma (uuid_version uuid_example == 4)
  = ()


(** The nil UUID has variant 0 and version 0 (all bytes zero). *)
let lemma_uuid_nil_variant_version ()
  : Lemma (uuid_variant uuid_nil == 0 /\ uuid_version uuid_nil == 0)
  = ()


(** The variant is always in the range 0..3 (the top two bits of a byte). *)
let lemma_uuid_variant_range (u: uuid) : Lemma (uuid_variant u < 4) =
  let b = U8.v u.clock_seq_hi_and_reserved in
  assert (b < 256);
  assert_norm (pow2 8 == 256);
  FStar.Math.Lemmas.lemma_div_lt_nat b 8 6


(** The version is always in the range 0..15 (the top nibble of a byte). *)
let lemma_uuid_version_range (u: uuid) : Lemma (uuid_version u < 16) =
  let b = U8.v (fst u.time_hi_and_version) in
  assert (b < 256);
  assert_norm (pow2 8 == 256);
  FStar.Math.Lemmas.lemma_div_lt_nat b 8 4
