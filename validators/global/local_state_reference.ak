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
use plumbline/types/local_state_reference_data.{LocalStateReferenceData}

// validator where local state reference scripts are stored to be used in a global state.
// Every local state reference is identified by a fungible token and differentiated by the policy in the datum.
// two actions, minting and burning
validator local_state_reference(
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
    let own_input = find_input(inputs, output_reference)
    let own_policy = get_script_hash_from_address(own_input.output.address)
    expect Some(datum) = datum_opt
    policy_id_present_in_outputs(outputs, datum)? && (policy_id_present_in_outputs(
      outputs,
      own_policy,
    ) == False)?
  }

  mint(
    lsrd: List<LocalStateReferenceData>,
    policy_id: PolicyId,
    tx: Transaction,
  ) {
    if length(lsrd) > 0 {
      let own_addr = Address(Script(policy_id), Some(stake_cred))
      all(
        lsrd,
        fn(LocalStateReferenceData { ls_id, ls_reference_script_hashes }) {
          any(
            tx.outputs,
            fn(output) {
              let value = output.value
              quantity_is_one(value, policy_id, state_token_name) && (output.datum == InlineDatum(
                ls_id,
              ))? && (output.address == own_addr)? && two_token_value(value)? && output.reference_script == Some(
                ls_reference_script_hashes,
              )
            },
          )? && policy_id_present_in_outputs(tx.outputs, ls_id)?
        },
      ) && (unique(lsrd) == lsrd)? && single_name_of_policy_id(
        tx.mint,
        policy_id,
        state_token_name,
        length(lsrd),
      )?
    } else {
      (quantity_of(tx.mint, policy_id, state_token_name) < 0)?
    }
  }

  else(_) {
    fail
  }
}
