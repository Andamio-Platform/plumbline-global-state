//// @hidden

use aiken/builtin.{head_list}
use aiken/collection/list.{any, has}
use aiken/collection/pairs.{has_key}
use cardano/address.{Script}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use plumbline/plumb_global_state.{
  at_validate, create_new_gs_dat_delete, hash_local_state,
}
use plumbline/plumb_input.{
  find_input, find_input_with_policy, in_out_token_address_same,
}
use plumbline/plumb_output.{policy_id_present_in_output}
use plumbline/plumb_value.{create_100, create_222, quantity_is_one}
use plumbline/types/global_state.{
  BurnLocalState, DeleteState, GlobalStateAction, GlobalStateDatum,
  MintLocalState, MoveState,
}
use types/index_data.{IndexData}

// global state validator, manage global states of a user. 

pub fn validate_input_and_output(
  inputs: List<Input>,
  output_reference: OutputReference,
  outputs: List<Output>,
  global_cs: PolicyId,
  datum: GlobalStateDatum,
) -> Bool {
  let own_input_output = find_input(inputs, output_reference).output
  let tn_100 = create_100(datum.alias)
  quantity_is_one(own_input_output.value, global_cs, tn_100)? && in_out_token_address_same(
    inputs,
    outputs,
    global_cs,
    create_222(datum.alias),
  )? && any(
    outputs,
    fn(output) {
      (output.address == own_input_output.address)? && (output.datum == InlineDatum(
        datum,
      ))? && quantity_is_one(output.value, global_cs, tn_100)?
    },
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
        expect Some(datum) = datum_opt
        (quantity_of(mint, local_state_cs, datum.alias) > 0)? && any(
          reference_inputs,
          fn(input) {
            let input_output = input.output
            policy_id_present_in_output(input_output, local_state_register_cs) && input_output.datum == InlineDatum(
              local_state_id,
            ) && input_output.reference_script == Some(local_state_cs)
          },
        )? && validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          GlobalStateDatum {
            ..datum,
            local_state_data: if local_state_index > -1 {
              list.push(
                at_validate(
                  datum.local_state_data,
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
              if has_key(datum.local_state_data, local_state_id) {
                fail
              } else {
                list.push(
                  datum.local_state_data,
                  Pair(local_state_id, hash_local_state("", local_state_cs)),
                )
              }
            },
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
        expect Some(datum) = datum_opt
        (quantity_of(mint, local_state_cs, datum.alias) < 0)? && validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          GlobalStateDatum {
            ..datum,
            local_state_data: list.push(
              at_validate(
                datum.local_state_data,
                [],
                local_state_id,
                hash_local_state(local_state_data_hash, local_state_cs),
                local_state_index,
              ),
              Pair(local_state_id, hash_local_state(new_data_hash, "")),
            ),
          },
        )
      }
      DeleteState { local_state_id, local_state_data_hash, local_state_index } -> {
        let Transaction { inputs, outputs, .. } = tx
        expect Some(datum) = datum_opt

        validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          create_new_gs_dat_delete(
            datum,
            local_state_id,
            local_state_data_hash,
            local_state_index,
          ),
        )
      }

      MoveState { new_state_obs } -> {
        let Transaction { inputs, outputs, reference_inputs, withdrawals, .. } =
          tx
        expect Some(datum) = datum_opt
        expect InlineDatum(index_ref_datum) =
          find_input_with_policy(reference_inputs, index_ref_cs).output.datum
        expect index_data: IndexData = index_ref_datum
        let alias = datum.alias
        let obs_scr = Script(new_state_obs)
        quantity_is_one(
          find_input(inputs, output_reference).output.value,
          global_cs,
          create_100(alias),
        )? && in_out_token_address_same(
          inputs,
          outputs,
          global_cs,
          create_222(alias),
        )? && has(index_data.init_gs_obs_sh_list, obs_scr)? && (head_list(
          withdrawals,
        ) == Pair(obs_scr, 0))?
      }
    }
  }

  else(_) {
    fail
  }
}
