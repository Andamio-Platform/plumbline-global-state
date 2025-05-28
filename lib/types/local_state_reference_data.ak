//// @hidden

use aiken/crypto.{ScriptHash}

// Type used as redeemer to register a new local state token reference. 

pub type LocalStateReferenceData {
  ls_id: ByteArray,
  ls_reference_script_hashes: List<ScriptHash>,
}
