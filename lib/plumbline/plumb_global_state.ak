use aiken/builtin.{blake2b_256, fst_pair, snd_pair}
use aiken/collection/list
use aiken/primitive/bytearray
use cardano/assets.{PolicyId}
use plumbline/types/global_state.{GlobalStateDatum, LocalStateInformation}

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
      list.push(
        gs_dat.local_state_data,
        Pair(
          ls_info.local_state_id,
          hash_local_state("", ls_info.local_state_cs),
        ),
      )
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
