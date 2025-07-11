use aiken/builtin.{
  blake2b_256, fst_pair, head_list, snd_pair, tail_list, un_b_data, un_i_data,
  unconstr_fields,
}
use aiken/collection/list
use aiken/collection/pairs
use aiken/primitive/bytearray
use cardano/assets.{PolicyId}
use cardano/transaction.{Input, Redeemer, ScriptPurpose, Spend}
use plumbline/plumb_input.{find_input_with_single_token}
use plumbline/plumb_redeemers.{get_single_token_spend_redeemer_by_constructor}
use plumbline/plumb_value.{create_100}

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
    [] -> fail @"at_validate: index does not exist"
    [x, ..xs] ->
      if index == 0 {
        if id == fst_pair(x) {
          if data == snd_pair(x) {
            list.concat(new, xs)
          } else {
            fail @"at_validate: provided data wrong"
          }
        } else {
          fail @"at_validate: data index wrong"
        }
      } else {
        at_validate(xs, list.push(new, x), id, data, index - 1)
      }
  }
}

/// Get `local_state_id` from global state redeemer fields.
/// Does make sense to use it together with `get_global_state_red_data`.
pub fn get_ls_id_gs_red(gs_red: List<Data>) -> ByteArray {
  gs_red
    |> head_list()
    |> un_b_data()
}

/// Get `local_state_index` from global state redeemer fields.
/// Does make sense to use it together with `get_global_state_red_data`.
pub fn get_ls_state_index_gs_red(gs_red: List<Data>) -> Int {
  gs_red
    |> tail_list()
    |> head_list()
    |> un_i_data()
}

/// Get `local_state_data_hash` from global state redeemer fields.
/// Does make sense to use it together with `get_global_state_red_data`.
pub fn get_ls_state_gs_red(gs_red: List<Data>) -> ByteArray {
  gs_red
    |> tail_list()
    |> tail_list()
    |> head_list()
    |> un_b_data()
}

/// Get `local_state_cs` from global state redeemer fields.
/// Does make sense to use it together with `get_global_state_red_data`.
pub fn get_ls_cs_gs_red(gs_red: List<Data>) -> ByteArray {
  gs_red
    |> tail_list()
    |> tail_list()
    |> tail_list()
    |> head_list()
    |> un_b_data()
}

/// Get `new_data_hash` from BurnLocalState redeemer fields.
/// Does make sense to use it together with `get_global_state_red_data`.
pub fn get_ls_new_state_gs_red(gs_red: List<Data>) -> ByteArray {
  gs_red
    |> tail_list()
    |> tail_list()
    |> tail_list()
    |> tail_list()
    |> head_list()
    |> un_b_data()
}

/// Validate provided data matches global state `MintLocalState` redeemer.
/// Should be used if no prerequisits are needed.
pub fn validate_global_state_mint_ls_no_prereqs(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  global_cs: PolicyId,
  alias: ByteArray,
  ls_id: PolicyId,
  ls_data_hash: ByteArray,
  ls_cs: PolicyId,
) -> Bool {
  let global_state_redeemer_fields =
    get_single_token_spend_redeemer_by_constructor(
      inputs,
      redeemers,
      0,
      global_cs,
      create_100(alias),
    )
  (ls_id == get_ls_id_gs_red(global_state_redeemer_fields))? && (ls_data_hash == get_ls_state_gs_red(
    global_state_redeemer_fields,
  ))? && (ls_cs == get_ls_cs_gs_red(global_state_redeemer_fields))?
}

/// Get `local_state_data` from `GlobalStateDatum` by searching for 100 global state token.
/// Return `local_state_data`.
pub fn get_local_state_data(
  inputs: List<Input>,
  global_cs: PolicyId,
  alias: ByteArray,
) -> Pairs<PolicyId, ByteArray> {
  expect local_state_data: Pairs<PolicyId, ByteArray> =
    find_input_with_single_token(inputs, global_cs, create_100(alias)).output.datum
      |> unconstr_fields()
      |> head_list()
      |> unconstr_fields()
      |> tail_list()
      |> head_list()
  local_state_data
}

/// Validate provided data matches global state `MintLocalState` redeemer and `GloblStateDatum` datum.
/// Should be used if prerequisits are needed.
pub fn validate_global_state_mint_ls_with_prereqs(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  global_cs: PolicyId,
  alias: ByteArray,
  local_state_data_prereqs: Pairs<PolicyId, ByteArray>,
  ls_id: PolicyId,
  ls_data_hash: ByteArray,
  ls_cs: PolicyId,
) -> Bool {
  let global_input =
    find_input_with_single_token(inputs, global_cs, create_100(alias))
  expect local_state_data: Pairs<PolicyId, ByteArray> =
    global_input.output.datum
      |> unconstr_fields()
      |> head_list()
      |> unconstr_fields()
      |> tail_list()
      |> head_list()
  let global_state_redeemer_fields =
    pairs.get_first(redeemers, Spend(global_input.output_reference))
      |> unconstr_fields()
      |> head_list()
      |> unconstr_fields()

  (ls_id == get_ls_id_gs_red(global_state_redeemer_fields))? && (ls_data_hash == get_ls_state_gs_red(
    global_state_redeemer_fields,
  ))? && (ls_cs == get_ls_cs_gs_red(global_state_redeemer_fields))? && list.all(
    local_state_data_prereqs,
    fn(ls_data) {
      list.any(local_state_data, fn(gs_pair) { gs_pair == ls_data })
    },
  )?
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
  new_state_hash: ByteArray,
) -> Bool {
  let global_state_redeemer_fields =
    get_single_token_spend_redeemer_by_constructor(
      inputs,
      redeemers,
      1,
      global_cs,
      create_100(alias),
    )
  (new_state_hash == get_ls_new_state_gs_red(global_state_redeemer_fields))? && (ls_id == get_ls_id_gs_red(
    global_state_redeemer_fields,
  ))? && (ls_cs == get_ls_cs_gs_red(global_state_redeemer_fields))?
}
