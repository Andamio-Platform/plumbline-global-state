//// @hidden

use aiken/collection/list.{any, map}
use cardano/address.{Address, Credential}
use cardano/assets.{PolicyId}
use cardano/certificate.{Certificate, RegisterCredential}
use cardano/transaction.{InlineDatum, Transaction}
use plumbline/plumb_bytearray.{serialise_hash_list}
use plumbline/plumb_global_state.{hash_local_state}
use plumbline/plumb_input.{find_input_with_single_token}
use plumbline/plumb_value.{create_100, quantity_is_one}
use plumbline/types/global_state.{GlobalStateDatum}
use types/global_state_v1.{GlobalStateDatumV1, LocalStateInformationV1}

// zero wihtdraw validator observing minting of global state token or moving from global state v1 to global state v2

validator init_global_state_obs_v2(
  global_cs: PolicyId,
  global_state_addr: Address,
) {
  withdraw(redeemer: ByteArray, _account: Credential, tx: Transaction) {
    let Transaction { inputs, outputs, mint, .. } = tx
    let tn_100 = create_100(redeemer)
    let global_state_datum =
      if quantity_is_one(mint, global_cs, tn_100) {
        GlobalStateDatum { alias: redeemer, local_state_data: [] }
      } else {
        expect InlineDatum(gs_dat_old_data) =
          find_input_with_single_token(inputs, global_cs, tn_100).output.datum
        expect gs_dat_old: GlobalStateDatumV1 = gs_dat_old_data
        let ls_info =
          map(
            gs_dat_old.local_state_infos,
            fn(
              LocalStateInformationV1 {
                local_state_id,
                local_state_data,
                minted,
              },
            ) {
              if minted == False {
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
      fn(output) {
        (output.address == global_state_addr)? && quantity_is_one(
          output.value,
          global_cs,
          tn_100,
        )? && (output.datum == InlineDatum(global_state_datum))?
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
