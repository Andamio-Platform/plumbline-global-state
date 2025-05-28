//// @hidden

use cardano/assets.{PolicyId}

// Types from global state version 1.

pub type LocalStateInformationV1 {
  local_state_id: PolicyId,
  local_state_data: List<ByteArray>,
  minted: Bool,
}

pub type GlobalStateDatumV1 {
  global_cs: PolicyId,
  user_name: ByteArray,
  local_state_infos: List<LocalStateInformationV1>,
  user_info: Data,
}
