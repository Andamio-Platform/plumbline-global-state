//// @hidden

use aiken/collection/list.{all, any, length, unique}
use cardano/address.{Address, Script, StakeCredential}
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use plumbline/plumb_address.{get_script_hash_from_address}
use plumbline/plumb_input.{find_input}
use plumbline/plumb_output.{policy_id_present_in_outputs}
use plumbline/plumb_value.{
  quantity_is_one, single_name_of_policy_id, two_token_value,
}
use plumbline/types/local_state_registration_data.{LocalStateRegistrationData}

// Validator where local state reference scripts are stored to be used in a global state.
// Every local state reference token stands for a local state token which is identified by a policy id in the datum.
// two actions, minting and burning
validator local_state_registration(
  stake_cred: StakeCredential,
  state_token_name: AssetName,
) {
  spend(
    datum_opt: Option<ByteArray>,
    _redeemer: Data,
    output_reference: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { inputs, outputs, .. } = tx
    let own_policy =
      get_script_hash_from_address(
        find_input(inputs, output_reference).output.address,
      )
    expect Some(datum) = datum_opt
    policy_id_present_in_outputs(outputs, datum)? && (!policy_id_present_in_outputs(
      outputs,
      own_policy,
    ))?
  }

  mint(
    lsrd: List<LocalStateRegistrationData>,
    policy_id: PolicyId,
    tx: Transaction,
  ) {
    let lsrd_len = length(lsrd)
    if lsrd_len > 0 {
      let own_addr = Address(Script(policy_id), Some(stake_cred))
      all(
        lsrd,
        fn(LocalStateRegistrationData { ls_id, ls_reference_script_hash }) {
          let ref_scr = Some(ls_reference_script_hash)
          let ref_datum = InlineDatum(ls_id)
          any(
            tx.outputs,
            fn(output) {
              let value = output.value
              quantity_is_one(value, policy_id, state_token_name) && (output.datum == ref_datum)? && (output.address == own_addr)? && two_token_value(
                value,
              )? && output.reference_script == ref_scr
            },
          )? && policy_id_present_in_outputs(tx.outputs, ls_id)?
        },
      ) && (unique(lsrd) == lsrd)? && single_name_of_policy_id(
        tx.mint,
        policy_id,
        state_token_name,
        lsrd_len,
      )?
    } else {
      (quantity_of(tx.mint, policy_id, state_token_name) < 0)?
    }
  }

  else(_) {
    fail
  }
}
