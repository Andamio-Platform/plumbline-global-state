use aiken/builtin.{b_data, blake2b_224}
use aiken/cbor.{serialise}
use aiken/collection/list.{push}
use cardano/address.{Script}
use cardano/transaction.{Input, Mint, Output, Transaction, placeholder}
use global/init_global_state_obs as init_obs
use plumbline/plumb_global_state.{hash_local_state}
use plumbline/types/global_state.{GlobalStateDatum}
use plumbproof.{
  create_empty_gs_dat, create_global_output, create_min_ada_token_value,
  global_cs, global_state_addr, mock_pub_key_output, mock_script_address,
  mock_utxo_ref,
}

// call withdraw
fn init_gs_obs_withdraw(red: ByteArray, tx: Transaction) {
  init_obs.init_global_state_obs_v2.withdraw(
    global_cs,
    "init_index_policy_id",
    global_state_addr,
    red,
    Script(blake2b_224("init_obs")),
    tx,
  )
}

// newly minted global state token with an empty datum
fn init_gs_obs_tx_empty(alias: ByteArray) {
  Transaction {
    ..placeholder,
    inputs: [
      Input(
        mock_utxo_ref("0", 0),
        mock_pub_key_output(
          global_state_addr,
          create_min_ada_token_value(global_cs, " ", 1),
        ),
      ),
    ],
    outputs: [create_global_output(alias, create_empty_gs_dat(alias))],
    redeemers: [Pair(Mint(global_cs), b_data(alias))],
  }
}

// withdraw test when minting a global state token
test init_obs_withdraw_empty_succeed() {
  let user_name = "user_name"
  init_gs_obs_withdraw(user_name, init_gs_obs_tx_empty(user_name))
}

// withdraw fail
// trying to initiate with a state
test init_obs_withdraw_empty_fail1_datum() fail {
  let user_name = "user_name"
  init_gs_obs_withdraw(
    user_name,
    Transaction {
      ..init_gs_obs_tx_empty(user_name),
      outputs: [
        create_global_output(
          user_name,
          GlobalStateDatum(
            user_name,
            push(
              [],
              Pair(blake2b_224("ls_id"), hash_local_state(serialise([]), "")),
            ),
          ),
        ),
      ],
    },
  )
}

// withdraw fail
// wrong token in output
test init_obs_withdraw_empty_fail2_value() fail {
  let user_name = "user_name"
  init_gs_obs_withdraw(
    user_name,
    Transaction {
      ..init_gs_obs_tx_empty(user_name),
      outputs: [
        Output {
          ..create_global_output(user_name, create_empty_gs_dat(user_name)),
          value: create_min_ada_token_value(global_cs, user_name, 1),
        },
      ],
    },
  )
}

// withdraw fail
// send to wrong global state address
test init_obs_withdraw_empty_fail3_address() fail {
  let user_name = "user_name"
  init_gs_obs_withdraw(
    user_name,
    Transaction {
      ..init_gs_obs_tx_empty(user_name),
      outputs: [
        Output {
          ..create_global_output(user_name, create_empty_gs_dat(user_name)),
          address: mock_script_address("1"),
        },
      ],
    },
  )
}

// withdraw test when minting a global state token
test init_obs_withdraw_empty_fail4_wrong_redeemer() fail {
  let user_name = "user_name"
  init_gs_obs_withdraw(
    user_name,
    Transaction {
      ..init_gs_obs_tx_empty(user_name),
      redeemers: [Pair(Mint(global_cs), b_data("wrong_alias"))],
    },
  )
}
