use aiken/builtin.{blake2b_224}
use aiken/cbor.{serialise}
use aiken/collection/list.{drop, map, push, sort}
use aiken/primitive/bytearray
use cardano/address.{Script}
use cardano/assets.{from_asset}
use cardano/transaction.{InlineDatum, Input, Output, Transaction, placeholder}
use global/init_global_state_obs as init_obs
use plumbline.{create_100}
use plumbline/plumb_global_state.{hash_local_state}
use plumbline/types/global_state.{GlobalStateDatum}
use plumbproof.{
  create_empty_gs_dat, create_global_output, create_min_ada_token_value,
  global_cs, global_state_addr, mock_script_address, mock_utxo_ref,
  script_address_stake_cred,
}
use types/global_state_v1.{GlobalStateDatumV1, LocalStateInformationV1}

// call withdraw
fn init_gs_obs_withdraw(red: ByteArray, tx: Transaction) {
  init_obs.init_global_state_obs_v2.withdraw(
    global_cs,
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
    outputs: [create_global_output(alias, create_empty_gs_dat(alias))],
    mint: from_asset(global_cs, create_100(alias), 1),
  }
}

// withdraw test when minting a global state token
test init_obs_withdraw_empty_succeed() {
  let user_name = "user_name"
  init_gs_obs_withdraw(user_name, init_gs_obs_tx_empty(user_name))
}

// withdraw fail
// trying to nitiate with a state
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

// move existing global state to new global state transaction
fn init_gs_obs_tx_no_mint_ls(
  alias: ByteArray,
  gs_dat_v1: GlobalStateDatumV1,
  gs_dat: GlobalStateDatum,
) {
  Transaction {
    ..placeholder,
    inputs: [
      Input(
        mock_utxo_ref("0", 0),
        Output {
          address: script_address_stake_cred("global_state_addr_v1"),
          value: create_min_ada_token_value(global_cs, create_100(alias), 1),
          datum: InlineDatum(gs_dat_v1),
          reference_script: None,
        },
      ),
    ],
    outputs: [create_global_output(alias, gs_dat)],
  }
}

// create v1 global state datum from local state infos
fn create_gs_dat_v1(
  alias: ByteArray,
  ls_infos: List<LocalStateInformationV1>,
) -> GlobalStateDatum {
  GlobalStateDatum(
    alias,
    sort(
      map(
        ls_infos,
        fn(n) {
          Pair(
            n.local_state_id,
            hash_local_state(serialise(n.local_state_data), ""),
          )
        },
      ),
      fn(Pair(key1, _), Pair(key2, _)) { bytearray.compare(key1, key2) },
    ),
  )
}

// move existing global state to new global state test succeed
test init_obs_withdraw_no_mint_succeed() {
  let user_name = "user_name"
  let local_state_infos =
    map(
      ["1", "2", "3", "4"],
      fn(n) {
        LocalStateInformationV1(blake2b_224(n), ["100", "102", "103"], False)
      },
    )
  init_gs_obs_withdraw(
    user_name,
    init_gs_obs_tx_no_mint_ls(
      user_name,
      GlobalStateDatumV1(global_cs, user_name, local_state_infos, ""),
      create_gs_dat_v1(user_name, local_state_infos),
    ),
  )
}

// move existing global state to new global state test succeed
// wrong state transition
test init_obs_withdraw_no_mint_fail1_datum1() fail {
  let user_name = "user_name"
  let local_state_infos =
    map(
      ["1", "2", "3", "4", "5"],
      fn(n) {
        LocalStateInformationV1(blake2b_224(n), ["100", "102", "103"], False)
      },
    )
  init_gs_obs_withdraw(
    user_name,
    init_gs_obs_tx_no_mint_ls(
      user_name,
      GlobalStateDatumV1(global_cs, user_name, drop(local_state_infos, 1), ""),
      create_gs_dat_v1(user_name, local_state_infos),
    ),
  )
}

// move existing global state to new global state test succeed
// wrong state transition
test init_obs_withdraw_no_mint_fail2_datum2() fail {
  let user_name = "user_name"
  let local_state_infos =
    map(
      ["1", "2", "3", "4"],
      fn(n) {
        LocalStateInformationV1(blake2b_224(n), ["100", "102", "103"], False)
      },
    )
  init_gs_obs_withdraw(
    user_name,
    init_gs_obs_tx_no_mint_ls(
      user_name,
      GlobalStateDatumV1(global_cs, user_name, local_state_infos, ""),
      create_gs_dat_v1("user_name1", local_state_infos),
    ),
  )
}
