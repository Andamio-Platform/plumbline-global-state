//// @hidden

use aiken/builtin.{
  fst_pair, head_list, tail_list, un_b_data, un_list_data, unconstr_fields,
}
use aiken/collection/list.{any}
use aiken/collection/pairs.{has_key}
use cardano/address.{Script}
use cardano/assets.{PolicyId, has_nft, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use plumbline/plumb_global_state.{at_validate, hash_local_state}
use plumbline/plumb_input.{
  find_input, find_input_with_policy, in_out_token_address_same,
}
use plumbline/plumb_value.{
  create_global_tn, create_user_tn, policy_id_present_in_value,
}
use plumbline/types/global_state.{
  BurnLocalState, DeleteState, GlobalStateAction, GlobalStateDatum,
  MintLocalState, MoveState,
}

// Global state validator, manage global states of a user.
// 4 actions: mint local state, burn local state, delete local state, move to new global state validator version.
// mint local state: verify state is not minted, local state exists, output represents minted local state.
// burn local state: verify state has been minted before, output represents new local state data.
// delete local state: verify state is not minted, local state gets removed forever.
// move global state: verify zero withdraw observer is present.

// Validate inputs and outputs. Same for mint/burn and delete.
pub fn validate_input_and_output(
  inputs: List<Input>,
  output_reference: OutputReference,
  outputs: List<Output>,
  global_cs: PolicyId,
  gs_datum: GlobalStateDatum,
) -> Bool {
  let Input { output: own_input, .. } = find_input(inputs, output_reference)
  let Output { address: input_address, value: input_value, .. } = own_input
  let alias = gs_datum.alias
  let tn_r = create_global_tn(alias)
  has_nft(input_value, global_cs, tn_r)? && in_out_token_address_same(
    inputs,
    outputs,
    global_cs,
    create_user_tn(alias),
  )? && any(
    outputs,
    fn(Output { address, value, datum, .. }) {
      (address == input_address)? && (datum == InlineDatum(gs_datum))? && has_nft(
        value,
        global_cs,
        tn_r,
      )?
    },
  )
}

// Create output datum if local state minted.
pub fn create_gs_datum_mint(
  self: Pairs<PolicyId, ByteArray>,
  local_state_id: PolicyId,
  local_state_index: Int,
  local_state_data_hash: ByteArray,
  local_state_cs: PolicyId,
) -> Pairs<PolicyId, ByteArray> {
  if local_state_index > -1 {
    list.push(
      at_validate(
        self,
        [],
        local_state_id,
        hash_local_state(local_state_data_hash, ""),
        local_state_index,
      ),
      Pair(
        local_state_id,
        hash_local_state(local_state_data_hash, local_state_cs),
      ),
    )
  } else {
    if has_key(self, local_state_id) {
      fail @"key does exist"
    } else {
      list.push(
        self,
        Pair(local_state_id, hash_local_state("", local_state_cs)),
      )
    }
  }
}

// Create output datum if local state burned.
pub fn create_gs_datum_burn(
  self: Pairs<PolicyId, ByteArray>,
  local_state_id: PolicyId,
  local_state_index: Int,
  local_state_data_hash: ByteArray,
  local_state_cs: PolicyId,
  new_data_hash: ByteArray,
) -> Pairs<PolicyId, ByteArray> {
  list.push(
    at_validate(
      self,
      [],
      local_state_id,
      hash_local_state(local_state_data_hash, local_state_cs),
      local_state_index,
    ),
    Pair(local_state_id, hash_local_state(new_data_hash, "")),
  )
}

// Create output datum if local state removed.
pub fn create_gs_datum_delete(
  self: Pairs<PolicyId, ByteArray>,
  local_state_id: PolicyId,
  local_state_data_hash: ByteArray,
  local_state_index: Int,
) -> Pairs<PolicyId, ByteArray> {
  at_validate(
    self,
    [],
    local_state_id,
    hash_local_state(local_state_data_hash, ""),
    local_state_index,
  )
}

validator global_state_validator(
  global_cs: PolicyId,
  index_ref_cs: PolicyId,
  local_state_register_cs: PolicyId,
) {
  spend(
    datum_opt: Option<GlobalStateDatum>,
    redeemer: GlobalStateAction,
    output_reference: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      MintLocalState {
        local_state_id,
        local_state_index,
        local_state_data_hash,
        local_state_cs,
      } -> {
        let Transaction { inputs, reference_inputs, outputs, mint, .. } = tx
        expect Some(GlobalStateDatum { alias, local_state_data }) = datum_opt
        (quantity_of(mint, local_state_cs, alias) > 0)? && any(
          reference_inputs,
          fn(Input { output: input_output, .. }) {
            let Output { value, datum, reference_script, .. } = input_output
            policy_id_present_in_value(value, local_state_register_cs) && datum == InlineDatum(
              local_state_id,
            ) && reference_script == Some(local_state_cs)
          },
        )? && validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          GlobalStateDatum {
            alias,
            local_state_data: create_gs_datum_mint(
              local_state_data,
              local_state_id,
              local_state_index,
              local_state_data_hash,
              local_state_cs,
            ),
          },
        )
      }
      BurnLocalState {
        local_state_id,
        local_state_index,
        local_state_data_hash,
        local_state_cs,
        new_data_hash,
      } -> {
        let Transaction { inputs, outputs, mint, .. } = tx
        expect Some(GlobalStateDatum { alias, local_state_data }) = datum_opt
        (quantity_of(mint, local_state_cs, alias) < 0)? && validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          GlobalStateDatum {
            alias,
            local_state_data: create_gs_datum_burn(
              local_state_data,
              local_state_id,
              local_state_index,
              local_state_data_hash,
              local_state_cs,
              new_data_hash,
            ),
          },
        )
      }
      DeleteState { local_state_id, local_state_data_hash, local_state_index } -> {
        let Transaction { inputs, outputs, .. } = tx
        expect Some(GlobalStateDatum { alias, local_state_data }) = datum_opt
        validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          GlobalStateDatum {
            alias,
            local_state_data: create_gs_datum_delete(
              local_state_data,
              local_state_id,
              local_state_data_hash,
              local_state_index,
            ),
          },
        )
      }
      MoveState { new_state_obs } -> {
        let Transaction { inputs, outputs, reference_inputs, withdrawals, .. } =
          tx
        expect Some(GlobalStateDatum { alias, .. }) = datum_opt
        let init_gs_obs_sh_list =
          find_input_with_policy(reference_inputs, index_ref_cs).output.datum
            |> unconstr_fields()
            |> head_list()
            |> unconstr_fields()
            |> tail_list()
            |> tail_list()
            |> tail_list()
            |> head_list()
            |> un_list_data()
        has_nft(
          find_input(inputs, output_reference).output.value,
          global_cs,
          create_global_tn(alias),
        )? && in_out_token_address_same(
          inputs,
          outputs,
          global_cs,
          create_user_tn(alias),
        )? && any(
          init_gs_obs_sh_list,
          fn(init_gs) {
            un_b_data(head_list(unconstr_fields(init_gs))) == new_state_obs
          },
        )? && (fst_pair(head_list(withdrawals)) == Script(new_state_obs))?
      }
    }
  }

  else(_) {
    fail
  }
}
