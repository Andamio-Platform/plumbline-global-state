use aiken/builtin.{blake2b_256, fst_pair, snd_pair}
use aiken/collection/list
use aiken/collection/pairs.{has_key}
use aiken/primitive/bytearray
use cardano/assets.{PolicyId}
use cardano/transaction.{InlineDatum, Input, Redeemer, ScriptPurpose, Spend}
use plumbline/plumb_input.{find_input_with_single_token}
use plumbline/plumb_value.{create_100}
use plumbline/types/global_state.{
  BurnLocalState, GlobalStateDatum, LocalStateInformation, MintLocalState,
}

/// Returns a BLAKE2b-256 hash of the local state by combining the state data hash
/// and the local state token policy ID. Useful for uniquely identifying a specific contract state.
/// If no local state minted, ls_cs is an empty bytestring.
pub fn hash_local_state(
  local_state_data_hash: ByteArray,
  ls_cs: PolicyId,
) -> ByteArray {
  blake2b_256(bytearray.concat(local_state_data_hash, ls_cs))
}

/// Validates that the pair at the given index matches the expected local state id and data derived by `hash_local_state`.
/// Return pairs without validated pair.
pub fn at_validate(
  self: Pairs<ByteArray, ByteArray>,
  new: Pairs<ByteArray, ByteArray>,
  id: PolicyId,
  data: ByteArray,
  index: Int,
) -> Pairs<ByteArray, ByteArray> {
  when self is {
    [] -> fail
    [x, ..xs] ->
      if index == 0 {
        if id == fst_pair(x) {
          if data == snd_pair(x) {
            list.concat(new, xs)
          } else {
            fail
          }
        } else {
          fail
        }
      } else {
        at_validate(xs, list.push(new, x), id, data, index - 1)
      }
  }
}

/// Create a new global state datum with local state token minted. 
pub fn create_new_gs_dat_mint(
  gs_dat: GlobalStateDatum,
  ls_info: LocalStateInformation,
) -> GlobalStateDatum {
  GlobalStateDatum {
    ..gs_dat,
    local_state_data: if ls_info.local_state_index > -1 {
      list.push(
        at_validate(
          gs_dat.local_state_data,
          [],
          ls_info.local_state_id,
          hash_local_state(ls_info.local_state_data_hash, ""),
          ls_info.local_state_index,
        ),
        Pair(
          ls_info.local_state_id,
          hash_local_state(
            ls_info.local_state_data_hash,
            ls_info.local_state_cs,
          ),
        ),
      )
    } else {
      if has_key(gs_dat.local_state_data, ls_info.local_state_id) {
        fail
      } else {
        list.push(
          gs_dat.local_state_data,
          Pair(
            ls_info.local_state_id,
            hash_local_state("", ls_info.local_state_cs),
          ),
        )
      }
    },
  }
}

/// Updates global state datum with new data hash for a local state. 
pub fn create_new_gs_dat_burn(
  gs_dat: GlobalStateDatum,
  ls_info: LocalStateInformation,
  new_data: ByteArray,
) -> GlobalStateDatum {
  GlobalStateDatum {
    ..gs_dat,
    local_state_data: list.push(
      at_validate(
        gs_dat.local_state_data,
        [],
        ls_info.local_state_id,
        hash_local_state(ls_info.local_state_data_hash, ls_info.local_state_cs),
        ls_info.local_state_index,
      ),
      Pair(ls_info.local_state_id, hash_local_state(new_data, "")),
    ),
  }
}

/// Deletes local state if not minted from global state datum.
pub fn create_new_gs_dat_delete(
  gs_dat: GlobalStateDatum,
  policy_id: PolicyId,
  data_hash: ByteArray,
  index: Int,
) -> GlobalStateDatum {
  GlobalStateDatum {
    ..gs_dat,
    local_state_data: at_validate(
      gs_dat.local_state_data,
      [],
      policy_id,
      hash_local_state(data_hash, ""),
      index,
    ),
  }
}

/// Function to check if given local states exist in global state and `LocalStateInformation` is used
/// Only works for minting local state.
pub fn validate_global_state_mint_ls(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  global_cs: PolicyId,
  alias: ByteArray,
  local_state_data: Pairs<PolicyId, ByteArray>,
  ls_info: LocalStateInformation,
) -> Bool {
  let global_state_input =
    find_input_with_single_token(inputs, global_cs, create_100(alias))
  expect InlineDatum(global_state_dat) = global_state_input.output.datum
  expect global_state_datum: GlobalStateDatum = global_state_dat
  expect Some(global_state_redeemer) =
    pairs.get_first(redeemers, Spend(global_state_input.output_reference))
  let msl: Data = MintLocalState(ls_info)
  list.all(
    local_state_data,
    fn(ls_data) {
      list.any(
        global_state_datum.local_state_data,
        fn(gs_pair) { gs_pair == ls_data },
      )
    },
  )? && (global_state_redeemer == msl)?
}

/// Function to validate correct redeemer is used for global state burn local state.
/// Only works for burning local state.
pub fn validate_global_state_burn_ls(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  global_cs: PolicyId,
  alias: ByteArray,
  ls_id: PolicyId,
  ls_cs: PolicyId,
  /// will be new local state atttached in global state
  new_state_hash: ByteArray,
) -> Bool {
  expect Some(global_state_redeemer) =
    pairs.get_first(
      redeemers,
      Spend(
        find_input_with_single_token(inputs, global_cs, create_100(alias)).output_reference,
      ),
    )
  expect BurnLocalState(local_state_info, new_data_hash_red) =
    global_state_redeemer
  (new_state_hash == new_data_hash_red)? && (ls_id == local_state_info.local_state_id)? && (ls_cs == local_state_info.local_state_cs)?
}
