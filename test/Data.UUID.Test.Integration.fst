(* Copyright 2026 Department of Code LLC.
   SPDX-License-Identifier: AGPL-3.0-or-later *)

(**
Data.UUID.Test.Integration — Binds all uuid lemmas, values, and tests.

If any lemma or test function is deleted or renamed, F* verification fails.
This guarantees mechanically-enforced test coverage.

Uses [--admit_smt_queries true] for integration anchoring only.
Individual lemmas are proven without admits in their source modules.

@header Data.UUID.Test.Integration
*)
module Data.UUID.Test.Integration


open Data.UUID
open Data.UUID.Pulse


#push-options "--admit_smt_queries true"


(** Values *)


(** [uuid_example] *)
let _uuid_example = uuid_example
(** [uuid_nil] *)
let _uuid_nil = uuid_nil


(** Codec + accessors (protected against deletion) *)


(** [uuid_codec] *)
let _uuid_codec = uuid_codec
(** [decode_uuid] *)
let _decode_uuid = decode_uuid
(** [encode_uuid] *)
let _encode_uuid = encode_uuid
(** [uuid_variant] *)
let _uuid_variant = uuid_variant
(** [uuid_version] *)
let _uuid_version = uuid_version


(** Accessor range lemmas *)


(** [lemma_uuid_variant_range] *)
let _lemma_uuid_variant_range = lemma_uuid_variant_range
(** [lemma_uuid_version_range] *)
let _lemma_uuid_version_range = lemma_uuid_version_range


(** Concrete-vector lemmas *)


(** [lemma_uuid_example_variant] *)
let _lemma_uuid_example_variant = lemma_uuid_example_variant
(** [lemma_uuid_example_version] *)
let _lemma_uuid_example_version = lemma_uuid_example_version
(** [lemma_uuid_nil_variant_version] *)
let _lemma_uuid_nil_variant_version = lemma_uuid_nil_variant_version


(** Pulse roundtrip *)


(** [lemma_decode16_encode16_spec] *)
let _lemma_decode16_encode16_spec = lemma_decode16_encode16_spec
(** [lemma_pulse_uuid16_roundtrip] *)
let _lemma_pulse_uuid16_roundtrip = lemma_pulse_uuid16_roundtrip


(** Pulse encode/decode functions — mechanically protected against deletion *)


(** [encode_uuid16] *)
let _encode_uuid16 = encode_uuid16
(** [decode_uuid16] *)
let _decode_uuid16 = decode_uuid16


(* The Pulse spec mirrors [decode16_spec]/[encode16_spec]/[uuid16_of_indices]
   are [noextract] and are NOT given direct value anchors: they are
   transitively covered by [lemma_decode16_encode16_spec] (bound above), which
   is the same policy as [fstar-basen] (its [decode_base16_spec] etc. are
   covered by their roundtrip lemmas, not anchored directly). *)


#pop-options
