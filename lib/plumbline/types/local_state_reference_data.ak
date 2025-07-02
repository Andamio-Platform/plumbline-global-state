use aiken/crypto.{ScriptHash}

// Type as list used as redeemer to register a new local state token reference. 

pub type LocalStateReferenceData {
  /// identifier of a local state (nft policy id) 
  ls_id: ByteArray,
  /// local state token script hash
  ls_reference_script_hashes: ScriptHash,
}
