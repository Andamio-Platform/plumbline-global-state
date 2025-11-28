//// @hidden

use aiken/builtin.{head_list, tail_list, unconstr_fields}
use aiken/collection/list.{any, map}
use cardano/address.{Address, Credential}
use cardano/assets.{PolicyId, has_nft}
use cardano/certificate.{Certificate, RegisterCredential}
use cardano/transaction.{InlineDatum, Input, Output, Transaction}
use plumbline/plumb_bytearray.{serialise_hash_list}
use plumbline/plumb_global_state.{hash_local_state}
use plumbline/plumb_input.{find_input_with_single_token}
use plumbline/plumb_value.{create_global_tn}
use plumbline/types/global_state.{GlobalStateDatum}
use types/global_state_v1.{LocalStateInformationV1}

// Zero wihtdraw validator observing minting of global state token or moving from global state v1 to global state v2.
// Purpose is to watch the output to the global state validator. Either empty when initializing or moving from v1.
// Three types of interactions: register credentials (always true), initialize new empty global state, or moving from v1 to v2.

validator init_global_state_obs_v2(
  global_cs: PolicyId,
  global_state_addr: Address,
) {
  withdraw(redeemer: ByteArray, _account: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, mint, .. } = tx
    let tn_r = create_global_tn(redeemer)
    let global_state_datum =
      if has_nft(mint, global_cs, tn_r) {
        GlobalStateDatum { alias: redeemer, local_state_data: [] }
      } else {
        expect ls_infos: List<LocalStateInformationV1> =
          find_input_with_single_token(inputs, global_cs, tn_r).output.datum
            |> unconstr_fields()
            |> head_list()
            |> unconstr_fields()
            |> tail_list()
            |> tail_list()
            |> head_list()
        let ls_info =
          map(
            ls_infos,
            fn(
              LocalStateInformationV1 {
                local_state_id,
                local_state_data,
                minted,
              },
            ) {
              if !minted {
                Pair(
                  local_state_id,
                  hash_local_state(serialise_hash_list(local_state_data), ""),
                )
              } else {
                fail
              }
            },
          )
        GlobalStateDatum { alias: redeemer, local_state_data: ls_info }
      }

    any(
      outputs,
      fn(Output { address, value, datum, .. }) {
        (address == global_state_addr)? && has_nft(value, global_cs, tn_r)? && (datum == InlineDatum(
          global_state_datum,
        ))?
      },
    )
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
