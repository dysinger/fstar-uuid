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


#pop-options
