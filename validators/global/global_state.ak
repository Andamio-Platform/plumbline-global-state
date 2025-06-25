//// @hidden

use aiken/builtin.{head_list}
use aiken/collection/list.{any, has}
use cardano/address.{Script}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, find_input,
}
use plumbline/plumb_global_state.{
  create_new_gs_dat_burn, create_new_gs_dat_delete, create_new_gs_dat_mint,
}
use plumbline/plumb_input.{find_input_with_policy, in_out_token_address_same}
use plumbline/plumb_output.{policy_id_present_in_output}
use plumbline/plumb_value.{create_100, create_222, quantity_is_one}
use plumbline/types/global_state.{
  BurnLocalState, DeleteState, GlobalStateAction, GlobalStateDatum,
  LocalStateInformation, MintLocalState, MoveState,
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
  expect Some(own_input) = find_input(inputs, output_reference)
  let own_input_output = own_input.output
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
      MintLocalState(ls_info) -> {
        let Transaction { inputs, reference_inputs, outputs, mint, .. } = tx
        expect Some(datum) = datum_opt
        let ls_cs = ls_info.local_state_cs
        (quantity_of(mint, ls_cs, datum.alias) > 0)? && any(
          reference_inputs,
          fn(input) {
            let input_output = input.output
            policy_id_present_in_output(input_output, local_state_register_cs) && input_output.datum == InlineDatum(
              ls_info.local_state_id,
            ) && input_output.reference_script == Some(ls_cs)
          },
        )? && validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          create_new_gs_dat_mint(datum, ls_info),
        )
      }
      BurnLocalState(ls_info, new_data) -> {
        let Transaction { inputs, outputs, mint, .. } = tx
        expect Some(datum) = datum_opt
        (quantity_of(mint, ls_info.local_state_cs, datum.alias) < 0)? && validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          create_new_gs_dat_burn(datum, ls_info, new_data),
        )
      }
      DeleteState(ls_id, ls_data, index) -> {
        let Transaction { inputs, outputs, .. } = tx
        expect Some(datum) = datum_opt

        validate_input_and_output(
          inputs,
          output_reference,
          outputs,
          global_cs,
          create_new_gs_dat_delete(datum, ls_id, ls_data, index),
        )
      }

      MoveState(obs) -> {
        let Transaction { inputs, outputs, reference_inputs, withdrawals, .. } =
          tx
        expect Some(own_input) = find_input(inputs, output_reference)
        expect Some(datum) = datum_opt
        expect InlineDatum(index_ref_datum) =
          find_input_with_policy(reference_inputs, index_ref_cs).output.datum
        expect index_data: IndexData = index_ref_datum
        let alias = datum.alias

        quantity_is_one(own_input.output.value, global_cs, create_100(alias))? && in_out_token_address_same(
          inputs,
          outputs,
          global_cs,
          create_222(alias),
        )? && has(index_data.init_gs_obs_sh_list, Script(obs))? && (head_list(
          withdrawals,
        ) == Pair(Script(obs), 0))?
      }
    }
  }

  else(_) {
    fail
  }
}
