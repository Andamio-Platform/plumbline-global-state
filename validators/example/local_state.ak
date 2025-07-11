//// @hidden
//// NOT FOR PRODUCTION !!!

use aiken/builtin.{fst_pair, snd_pair}
use aiken/collection/list
use cardano/address.{from_script}
use cardano/assets.{PolicyId}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use plumbline/plumb_address.{get_script_hash_from_address}
use plumbline/plumb_bytearray.{serialise_hash_list}
use plumbline/plumb_global_state.{
  hash_local_state, validate_global_state_burn_ls,
  validate_global_state_mint_ls_with_prereqs,
}
use plumbline/plumb_input.{find_input}
use plumbline/plumb_output.{policy_id_present_in_outputs}
use plumbline/plumb_value.{quantity_is_one, single_name_of_policy_id}

pub type LocalStateData {
  local_state_id: PolicyId,
  local_state_data_clear: List<ByteArray>,
  local_state_cs: PolicyId,
}

pub type LocalStateAction {
  Mint(ByteArray, List<ByteArray>, List<LocalStateData>)
  Issue(ByteArray, List<ByteArray>)
  Burn(ByteArray)
}

// Example implementation of a local state.
// Handles issuing of credentials and interaction with the global state.

validator simple_local_state(
  global_cs: PolicyId,
  local_state_id: PolicyId,
  prerequisits: Pairs<PolicyId, List<ByteArray>>,
) {
  spend(
    datum_opt: Option<List<ByteArray>>,
    redeemer: LocalStateAction,
    output_reference: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      Issue(alias, new_state) -> {
        let Transaction { inputs, outputs, .. } = tx
        let own_input = find_input(inputs, output_reference)
        let own_policy_id =
          get_script_hash_from_address(own_input.output.address)
        policy_id_present_in_outputs(outputs, local_state_id)? && list.any(
          outputs,
          fn(output) {
            output.datum == InlineDatum(new_state) && output.address == own_input.output.address && quantity_is_one(
              output.value,
              own_policy_id,
              alias,
            )
          },
        )
      }
      Burn(alias) -> {
        let Transaction { inputs, mint, redeemers, .. } = tx
        let own_input = find_input(inputs, output_reference)
        expect Some(state) = datum_opt
        let own_policy_id =
          get_script_hash_from_address(own_input.output.address)
        single_name_of_policy_id(mint, own_policy_id, alias, -1)? && validate_global_state_burn_ls(
          inputs,
          redeemers,
          global_cs,
          alias,
          local_state_id,
          own_policy_id,
          serialise_hash_list(state),
        )
      }
      _ -> fail
    }
  }

  mint(redeemer: LocalStateAction, policy_id: PolicyId, tx: Transaction) {
    when redeemer is {
      Mint(alias, state, local_state_data) -> {
        let Transaction { inputs, outputs, mint, redeemers, .. } = tx
        let global_state_data_to_check =
          list.map(
            local_state_data,
            fn(lsd) {
              Pair(
                lsd.local_state_id,
                hash_local_state(
                  serialise_hash_list(lsd.local_state_data_clear),
                  lsd.local_state_cs,
                ),
              )
            },
          )

        validate_global_state_mint_ls_with_prereqs(
          inputs,
          redeemers,
          global_cs,
          alias,
          global_state_data_to_check,
          local_state_id,
          if state == [] {
            ""
          } else {
            serialise_hash_list(state)
          },
          policy_id,
        ) && single_name_of_policy_id(mint, policy_id, alias, 1)? && list.all(
          prerequisits,
          fn(prereq) {
            list.any(
              local_state_data,
              fn(n) {
                n.local_state_id == fst_pair(prereq) && list.all(
                  snd_pair(prereq),
                  fn(p) { list.has(n.local_state_data_clear, p) },
                )
              },
            )
          },
        )? && list.any(
          outputs,
          fn(output) {
            output.datum == InlineDatum(state) && quantity_is_one(
              output.value,
              policy_id,
              alias,
            ) && output.address == from_script(policy_id)
          },
        )
      }
      Burn(_alias) -> (!policy_id_present_in_outputs(tx.outputs, policy_id))?
      _ -> fail
    }
  }

  else(_) {
    fail
  }
}
