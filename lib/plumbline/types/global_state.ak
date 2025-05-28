use aiken/crypto.{ScriptHash}
use cardano/assets.{PolicyId}

pub type LocalStateInformation {
  /// identifier of a local state (nft policy id)
  local_state_id: PolicyId,
  /// index where to find local state in global statepairs
  local_state_index: Int,
  /// hashed data from local state
  local_state_data_hash: ByteArray,
  /// policy id of the state token in a local state (empty if not minted)
  local_state_cs: PolicyId,
}

/// Global state of a user always attached to the global state token.
pub type GlobalStateDatum {
  /// Alias to identify user, no prefix.
  alias: ByteArray,
  /// Each pair one local state. 
  /// `PolicyId` to identify local state. 
  /// `ByteArray` data + local state token as blake2b_256 hash
  local_state_data: Pairs<PolicyId, ByteArray>,
}

/// Action a user can perform on a global state.
pub type GlobalStateAction {
  /// Mint a local state token and add it to global state.
  MintLocalState(LocalStateInformation)
  /// Burn a local state token and change data.
  /// `ByteArray` = new local state data hash -> validation happens in local state token policy.
  BurnLocalState(LocalStateInformation, ByteArray)
  /// Delete a local state from global state. Not possible if minted.
  /// `PolicyId` = local state id to identify local state
  /// `ByteArray` = data of local state
  /// `Int` = index where it can be found in pairs.
  DeleteState(PolicyId, ByteArray, Int)
  /// Move global state to a new validator.
  /// Observed by 0-withdraw script from index ref
  /// `ScriptHash` = 0-withdraw script
  MoveState(ScriptHash)
}
