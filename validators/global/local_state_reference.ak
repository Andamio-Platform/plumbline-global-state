//// @hidden

use aiken/collection/dict
use aiken/collection/list.{all, any, unique}
use cardano/address.{Address, Script, StakeCredential}
use cardano/assets.{AssetName, PolicyId, quantity_of, tokens}
use cardano/transaction.{InlineDatum, OutputReference, Transaction, find_input}
use plumbline/plumb_output.{
   policy_id_present_in_outputs,
}
use plumbline/plumb_value.{two_token_value, quantity_is_one}
use plumbline/plumb_address.{get_script_hash_from_address}
use types/local_state_reference_data.{LocalStateReferenceData}

// validator where local state reference scripts are stored to be used in a global state.
// Every local state reference is identified by a fungible token and differentiated by the policy in the datum.
// two actions, minting and burning
validator local_state_reference(
  stake_cred: StakeCredential,
  state_token_name: AssetName,
) {
  spend(
    datum_opt: Option<ByteArray>,
    _redeemer: ByteArray,
    output_reference: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { inputs, outputs, .. } = tx
    expect Some(own_input) = find_input(inputs, output_reference)
    let own_policy = get_script_hash_from_address(own_input.output.address)
    expect Some(datum) = datum_opt
    policy_id_present_in_outputs(outputs, datum)? && (policy_id_present_in_outputs(
      outputs,
      own_policy,
    ) == False)?
  }

  mint(redeemer: LocalStateReferenceData, policy_id: PolicyId, tx: Transaction) {
    (dict.size(tokens(tx.mint, policy_id)) == 1)? && if (quantity_of(
      tx.mint,
      policy_id,
      state_token_name,
    ) > 0)? {
      all(
        redeemer.ls_reference_script_hashes,
        fn(reference_script) {
          any(
            tx.outputs,
            fn(output) {
              quantity_is_one(output.value, policy_id, state_token_name) && (output.datum == InlineDatum(
                redeemer.ls_id,
              ))? && (output.address == Address(
                Script(policy_id),
                Some(stake_cred),
              ))? && two_token_value(output.value)? && output.reference_script == Some(
                reference_script,
              )
            },
          )
        },
      ) && policy_id_present_in_outputs(tx.outputs, redeemer.ls_id)? && (unique(
        redeemer.ls_reference_script_hashes,
      ) == redeemer.ls_reference_script_hashes)?
    } else {
      True
    }
  }

  else(_) {
    fail
  }
}
