(* Copyright 2026 Department of Code LLC.
   SPDX-License-Identifier: AGPL-3.0-or-later *)

(**
Data.UUID.Pulse — C-extractable UUID encode/decode via Pulse + Custard.

A raw 16-byte read/write of an RFC 9562 UUID over [Pulse.Lib.Array.array].
There is no validation at the byte level (every byte is a legal UUID byte),
so the decoder is a straight 16-byte read guarded by a bounds precondition.
Each encode/decode carries a POINTWISE byte-level post-condition tying the
buffer contents to the pure spec in [Data.UUID], avoiding the 16-layer
[Seq.upd]/[seq_to_list] chain (fstar-proofs §11/§18).

Written for F* v2026.09.20 (Custard `--custard_backend C`).  Zero admits.

@header Data.UUID.Pulse

@section Type
- [uuid16] — a flat 16-byte C-representable record (not the nested [uuid])

@section Spec
- [encode16_spec] / [decode16_spec] — the pure mirror, over a [list byte]

@section Encode
- [encode_uuid16] — writes the 16 bytes, returns [16ul]

@section Decode
- [decode_uuid16] — reads the 16 bytes, returns [OU16_Some]

@section Roundtrip
- [lemma_pulse_uuid16_roundtrip] — encode then decode preserves the value
*)
module Data.UUID.Pulse
#lang-pulse

open Pulse
open Pulse.Lib.Reference
module A = Pulse.Lib.Array
module US = FStar.SizeT
module U8 = FStar.UInt8
module U32 = FStar.UInt32
module Seq = FStar.Seq

open FStar.Seq
open FStar.Int.Cast

module DU = Data.UUID


(* ── Types ─────────────────────────────────────────────────────────── *)


(** [uuid16] — a flat 16-byte record of an RFC 9562 UUID.

    Custard emits this as a fixed struct; the nested [Data.UUID.uuid]
    tuple grouping has no C representation.  Field order matches the
    RFC 9562 §4.1 wire layout. *)
type uuid16 = {
  byte0: U8.t; byte1: U8.t; byte2: U8.t; byte3: U8.t;
  byte4: U8.t; byte5: U8.t; byte6: U8.t; byte7: U8.t;
  byte8: U8.t; byte9: U8.t; byte10: U8.t; byte11: U8.t;
  byte12: U8.t; byte13: U8.t; byte14: U8.t; byte15: U8.t;
}


(** [opt_uuid16] — the decode result: [OU16_None] (unreachable under the bounds
    precondition) or [OU16_Some] of ([uuid16] & [U32.t]). *)
type opt_uuid16 =
  | OU16_None
  | OU16_Some of (uuid16 & U32.t)


(* ── Pure spec (noextract) ─────────────────────────────────────────── *)


(** [encode16_spec] — flatten a [uuid16] to its 16 raw bytes (in order). *)
noextract
let encode16_spec (u: uuid16) : list U8.t =
  [u.byte0; u.byte1; u.byte2; u.byte3;
   u.byte4; u.byte5; u.byte6; u.byte7;
   u.byte8; u.byte9; u.byte10; u.byte11;
   u.byte12; u.byte13; u.byte14; u.byte15]


(** [decode16_spec] — assemble a [uuid16] from 16 raw bytes; [None] for any
    other length. *)
noextract
let decode16_spec (bs: list U8.t) : option (uuid16 & U32.t) =
  match bs with
  | [b0;b1;b2;b3; b4;b5;b6;b7; b8;b9;b10;b11; b12;b13;b14;b15] ->
    Some ({ byte0 = b0; byte1 = b1; byte2 = b2; byte3 = b3;
            byte4 = b4; byte5 = b5; byte6 = b6; byte7 = b7;
            byte8 = b8; byte9 = b9; byte10 = b10; byte11 = b11;
            byte12 = b12; byte13 = b13; byte14 = b14; byte15 = b15 }, 16ul)
  | _ -> None


(** [decode16_result_spec] — lift [decode16_spec] into the tagged result
    [opt_uuid16]. *)
noextract
let decode16_result_spec (bs: list U8.t) : opt_uuid16 =
  match decode16_spec bs with
  | None -> OU16_None
  | Some (u, n) -> OU16_Some (u, n)


(** [uuid16_of_indices] — the [uuid16] whose [byteN] is [Seq.index s (off+N)].
    Requires [off + 15 < Seq.length s] so every index is in bounds. *)
noextract
let uuid16_of_indices (s: Seq.seq U8.t) (off: nat { off + 15 < Seq.length s }) : uuid16 = {
  byte0 = Seq.index s (off + 0); byte1 = Seq.index s (off + 1);
  byte2 = Seq.index s (off + 2); byte3 = Seq.index s (off + 3);
  byte4 = Seq.index s (off + 4); byte5 = Seq.index s (off + 5);
  byte6 = Seq.index s (off + 6); byte7 = Seq.index s (off + 7);
  byte8 = Seq.index s (off + 8); byte9 = Seq.index s (off + 9);
  byte10 = Seq.index s (off + 10); byte11 = Seq.index s (off + 11);
  byte12 = Seq.index s (off + 12); byte13 = Seq.index s (off + 13);
  byte14 = Seq.index s (off + 14); byte15 = Seq.index s (off + 15);
}


(* ── Encode ────────────────────────────────────────────────────────── *)


(** [encode_uuid16] writes the 16 bytes of [u] into [buf] at [off], pointwise.

    @param u The UUID value to write.
    @param buf The destination buffer (must hold at least 16 bytes at [off]).
    @param off The write offset.
    @returns The number of bytes written (always [16ul]). *)
fn encode_uuid16 (u: uuid16) (buf: A.array U8.t) (off: U32.t)
    (#s0: erased (Seq.seq U8.t))
    requires
      A.pts_to buf s0 **
      pure (U32.v off + 16 <= A.length buf /\ U32.v off + 15 < 4294967296)
    returns w: U32.t
    ensures
      (exists* (s1: Seq.seq U8.t).
        A.pts_to buf s1 **
        pure (U32.v off + 16 <= A.length buf /\
              Seq.length s1 == A.length buf /\
              Seq.index s1 (U32.v off + 0) == u.byte0 /\
              Seq.index s1 (U32.v off + 1) == u.byte1 /\
              Seq.index s1 (U32.v off + 2) == u.byte2 /\
              Seq.index s1 (U32.v off + 3) == u.byte3 /\
              Seq.index s1 (U32.v off + 4) == u.byte4 /\
              Seq.index s1 (U32.v off + 5) == u.byte5 /\
              Seq.index s1 (U32.v off + 6) == u.byte6 /\
              Seq.index s1 (U32.v off + 7) == u.byte7 /\
              Seq.index s1 (U32.v off + 8) == u.byte8 /\
              Seq.index s1 (U32.v off + 9) == u.byte9 /\
              Seq.index s1 (U32.v off + 10) == u.byte10 /\
              Seq.index s1 (U32.v off + 11) == u.byte11 /\
              Seq.index s1 (U32.v off + 12) == u.byte12 /\
              Seq.index s1 (U32.v off + 13) == u.byte13 /\
              Seq.index s1 (U32.v off + 14) == u.byte14 /\
              Seq.index s1 (U32.v off + 15) == u.byte15)) **
      pure (w == 16ul)
{
  let j0 = US.uint32_to_sizet off;
  let j1 = US.uint32_to_sizet (U32.add off 1ul);
  let j2 = US.uint32_to_sizet (U32.add off 2ul);
  let j3 = US.uint32_to_sizet (U32.add off 3ul);
  let j4 = US.uint32_to_sizet (U32.add off 4ul);
  let j5 = US.uint32_to_sizet (U32.add off 5ul);
  let j6 = US.uint32_to_sizet (U32.add off 6ul);
  let j7 = US.uint32_to_sizet (U32.add off 7ul);
  let j8 = US.uint32_to_sizet (U32.add off 8ul);
  let j9 = US.uint32_to_sizet (U32.add off 9ul);
  let j10 = US.uint32_to_sizet (U32.add off 10ul);
  let j11 = US.uint32_to_sizet (U32.add off 11ul);
  let j12 = US.uint32_to_sizet (U32.add off 12ul);
  let j13 = US.uint32_to_sizet (U32.add off 13ul);
  let j14 = US.uint32_to_sizet (U32.add off 14ul);
  let j15 = US.uint32_to_sizet (U32.add off 15ul);
  A.pts_to_len buf;
  buf.(j0) <- u.byte0;
  buf.(j1) <- u.byte1;
  buf.(j2) <- u.byte2;
  buf.(j3) <- u.byte3;
  buf.(j4) <- u.byte4;
  buf.(j5) <- u.byte5;
  buf.(j6) <- u.byte6;
  buf.(j7) <- u.byte7;
  buf.(j8) <- u.byte8;
  buf.(j9) <- u.byte9;
  buf.(j10) <- u.byte10;
  buf.(j11) <- u.byte11;
  buf.(j12) <- u.byte12;
  buf.(j13) <- u.byte13;
  buf.(j14) <- u.byte14;
  buf.(j15) <- u.byte15;
  16ul
}


(* ── Decode ────────────────────────────────────────────────────────── *)


(** [decode_uuid16] reads the 16 bytes at [off] from [buf].

    There is no byte-level validation (every byte is a legal UUID byte); the
    bounds precondition ensures the read is in-bounds, so the result is always
    [OU16_Some].  The [ensures] states the result POINTWISE (each [byteN] is
    [Seq.index s0 (off+N)]), avoiding the [seq_to_list]/[slice] chain.

    @param buf The source buffer (must hold at least 16 bytes at [off]).
    @param off The read offset.
    @returns [OU16_Some (uuid16_of_indices s0 off, 16ul)]. *)
fn decode_uuid16 (buf: A.array U8.t) (off: U32.t)
    (#s0: erased (Seq.seq U8.t))
    requires
      A.pts_to buf s0 **
      pure (U32.v off + 16 <= A.length buf /\ U32.v off + 15 < 4294967296 /\
            A.length buf == Seq.length s0)
    returns r: opt_uuid16
    ensures
      A.pts_to buf s0 **
      pure (
        A.length buf == Seq.length s0 /\
        U32.v off + 16 <= A.length buf /\
        r == OU16_Some (uuid16_of_indices s0 (U32.v off), 16ul))
{
  A.pts_to_len buf;
  let j0 = US.uint32_to_sizet off;
  let j1 = US.uint32_to_sizet (U32.add off 1ul);
  let j2 = US.uint32_to_sizet (U32.add off 2ul);
  let j3 = US.uint32_to_sizet (U32.add off 3ul);
  let j4 = US.uint32_to_sizet (U32.add off 4ul);
  let j5 = US.uint32_to_sizet (U32.add off 5ul);
  let j6 = US.uint32_to_sizet (U32.add off 6ul);
  let j7 = US.uint32_to_sizet (U32.add off 7ul);
  let j8 = US.uint32_to_sizet (U32.add off 8ul);
  let j9 = US.uint32_to_sizet (U32.add off 9ul);
  let j10 = US.uint32_to_sizet (U32.add off 10ul);
  let j11 = US.uint32_to_sizet (U32.add off 11ul);
  let j12 = US.uint32_to_sizet (U32.add off 12ul);
  let j13 = US.uint32_to_sizet (U32.add off 13ul);
  let j14 = US.uint32_to_sizet (U32.add off 14ul);
  let j15 = US.uint32_to_sizet (U32.add off 15ul);
  let b0 = buf.(j0);
  let b1 = buf.(j1);
  let b2 = buf.(j2);
  let b3 = buf.(j3);
  let b4 = buf.(j4);
  let b5 = buf.(j5);
  let b6 = buf.(j6);
  let b7 = buf.(j7);
  let b8 = buf.(j8);
  let b9 = buf.(j9);
  let b10 = buf.(j10);
  let b11 = buf.(j11);
  let b12 = buf.(j12);
  let b13 = buf.(j13);
  let b14 = buf.(j14);
  let b15 = buf.(j15);
  OU16_Some ({ byte0 = b0; byte1 = b1; byte2 = b2; byte3 = b3;
               byte4 = b4; byte5 = b5; byte6 = b6; byte7 = b7;
               byte8 = b8; byte9 = b9; byte10 = b10; byte11 = b11;
               byte12 = b12; byte13 = b13; byte14 = b14; byte15 = b15 }, 16ul)
}


(* ── Pure bridge lemma (noextract) ─────────────────────────────────── *)


(** [lemma_decode16_encode16_spec]: the pure spec roundtrip — decoding the
    encoding of [u] is [Some (u, 16ul)]. *)
noextract
let lemma_decode16_encode16_spec (u: uuid16)
  : Lemma (decode16_spec (encode16_spec u) == Some (u, 16ul))
  = ()


(* ── Roundtrip ─────────────────────────────────────────────────────── *)


(** [lemma_pulse_uuid16_roundtrip]: encode then decode preserves the value.

    @param u The UUID value to roundtrip.
    @param buf The buffer (must hold at least 16 bytes at [off]).
    @param off The offset.
    Proves [decode_uuid16 buf off] after [encode_uuid16 u buf off] returns
    [OU16_Some (u, 16ul)]. *)
fn lemma_pulse_uuid16_roundtrip (u: uuid16) (buf: A.array U8.t) (off: U32.t)
    (#s0: erased (Seq.seq U8.t))
    requires
      A.pts_to buf s0 **
      pure (U32.v off + 16 <= A.length buf /\ U32.v off + 15 < 4294967296)
    returns res: (U32.t & opt_uuid16)
    ensures
      exists* (s1: Seq.seq U8.t).
        A.pts_to buf s1 **
        pure (res == (16ul, OU16_Some (u, 16ul)))
{
  let w = encode_uuid16 u buf off;
  let r = decode_uuid16 buf off;
  (w, r)
}
