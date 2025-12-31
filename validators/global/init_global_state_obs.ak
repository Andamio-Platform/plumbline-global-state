//// @hidden

use aiken/builtin.{b_data}
use aiken/collection/list.{any, filter, has}
use cardano/address.{Address, Credential}
use cardano/assets.{PolicyId, policies}
use cardano/certificate.{Certificate, RegisterCredential}
use cardano/transaction.{InlineDatum, Mint, Output, Transaction}
use plumbline/plumb_value.{create_global_tn, token_present_in_value_head}
use plumbline/types/global_state.{GlobalStateDatum}

// Zero wihtdraw validator observing minting of global state token.
// Purpose is to watch the output of the global state token.
// Two types of interactions: register credentials (always true), initialize new empty global state.

validator init_global_state_obs_v2(
  global_policy_id: PolicyId,
  init_index_policy_id: PolicyId,
  global_state_addr: Address,
) {
  withdraw(redeemer: ByteArray, _account: Credential, tx: Transaction) {
    let Transaction { outputs, inputs, redeemers, .. } = tx
    expect [_input] =
      filter(
        inputs,
        fn(n) {
          has(policies(n.output.value), global_policy_id) || has(
            policies(n.output.value),
            init_index_policy_id,
          )
        },
      )
    let global_mint_purpose_red = Pair(Mint(global_policy_id), b_data(redeemer))
    let is_access_token_minting =
      any(
        redeemers,
        fn(purpose_redeemer) { purpose_redeemer == global_mint_purpose_red },
      )
    let global_state_datum =
      InlineDatum(GlobalStateDatum { alias: redeemer, local_state_data: [] })
    let global_output_exists =
      any(
        outputs,
        fn(Output { address, value, datum, .. }) {
          (address == global_state_addr)? && token_present_in_value_head(
            value,
            global_policy_id,
            create_global_tn(redeemer),
          )? && (datum == global_state_datum)?
        },
      )
    global_output_exists? && is_access_token_minting?
  }

  publish(_redeemer: Data, certificate: Certificate, _self: Transaction) {
    when certificate is {
      RegisterCredential { .. } -> True
      _ -> fail
    }
  }

  else(_) {
    fail
  }
}
