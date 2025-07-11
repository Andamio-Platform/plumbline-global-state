//// @hidden
//// NOT FOR PRODUCTION !!!

use aiken/crypto.{blake2b_224}
use cardano/address.{from_script}
use cardano/assets.{from_asset}
use cardano/transaction.{InlineDatum, Input, Spend, Transaction, placeholder}
use example/local_state as simple_local_state
use plumbline/plumb_bytearray.{serialise_hash_list}
use plumbline/plumb_global_state.{hash_local_state}
use plumbline/types/global_state.{
  BurnLocalState, GlobalStateDatum, MintLocalState,
}
use plumbproof.{
  create_empty_gs_dat, create_global_output, create_min_ada_token_value,
  global_cs, mock_pub_key_address, mock_pub_key_output, mock_script_output,
  mock_utxo_ref,
}

const ls_id = blake2b_224("local_state_id")

const ls_cs = blake2b_224("loal_state_cs")

const alias = "user_name"

const input_100_utxo_ref = mock_utxo_ref("0", 1)

const mint_local_state_succeed_tx =
  Transaction { ..placeholder, mint: from_asset(ls_cs, alias, 1) }

test simple_local_state_mint_succeed_empty() {
  let red: Data = MintLocalState(ls_id, -1, "", ls_cs)
  simple_local_state.simple_local_state.mint(
    global_cs,
    ls_id,
    [],
    simple_local_state.Mint(alias, [], []),
    ls_cs,
    Transaction {
      ..mint_local_state_succeed_tx,
      inputs: [
        Input(
          input_100_utxo_ref,
          create_global_output(alias, create_empty_gs_dat(alias)),
        ),
      ],
      outputs: [
        mock_script_output(
          from_script(ls_cs),
          create_min_ada_token_value(ls_cs, alias, 1),
          InlineDatum([]),
        ),
      ],
      redeemers: [Pair(Spend(input_100_utxo_ref), red)],
    },
  )
}

test simple_local_state_mint_succeed_prereq() {
  let red: Data = MintLocalState(ls_id, 0, "", ls_cs)
  simple_local_state.simple_local_state.mint(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    simple_local_state.Mint(
      alias,
      [],
      [
        simple_local_state.LocalStateData(
          blake2b_224("id1"),
          ["1.1"],
          blake2b_224("cs1"),
        ),
      ],
    ),
    ls_cs,
    Transaction {
      ..mint_local_state_succeed_tx,
      inputs: [
        Input(
          input_100_utxo_ref,
          create_global_output(
            alias,
            GlobalStateDatum {
              alias,
              local_state_data: [
                Pair(
                  blake2b_224("id1"),
                  hash_local_state(
                    serialise_hash_list(["1.1"]),
                    blake2b_224("cs1"),
                  ),
                ),
              ],
            },
          ),
        ),
      ],
      outputs: [
        mock_script_output(
          from_script(ls_cs),
          create_min_ada_token_value(ls_cs, alias, 1),
          InlineDatum([]),
        ),
      ],
      redeemers: [Pair(Spend(input_100_utxo_ref), red)],
    },
  )
}

test simple_local_state_mint_succeed_with_state() {
  let red: Data = MintLocalState(ls_id, 0, serialise_hash_list(["0"]), ls_cs)
  simple_local_state.simple_local_state.mint(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    simple_local_state.Mint(
      alias,
      ["0"],
      [
        simple_local_state.LocalStateData(
          blake2b_224("id1"),
          ["1.1"],
          blake2b_224("cs1"),
        ),
      ],
    ),
    ls_cs,
    Transaction {
      ..mint_local_state_succeed_tx,
      inputs: [
        Input(
          input_100_utxo_ref,
          create_global_output(
            alias,
            GlobalStateDatum {
              alias,
              local_state_data: [
                Pair(
                  blake2b_224("id1"),
                  hash_local_state(
                    serialise_hash_list(["1.1"]),
                    blake2b_224("cs1"),
                  ),
                ),
                Pair(ls_id, hash_local_state(serialise_hash_list(["0"]), "")),
              ],
            },
          ),
        ),
      ],
      outputs: [
        mock_script_output(
          from_script(ls_cs),
          create_min_ada_token_value(ls_cs, alias, 1),
          InlineDatum(["0"]),
        ),
      ],
      redeemers: [Pair(Spend(input_100_utxo_ref), red)],
    },
  )
}

test simple_local_state_succeed_with_multiple_state() {
  let red: Data = MintLocalState(ls_id, 0, serialise_hash_list(["0"]), ls_cs)
  simple_local_state.simple_local_state.mint(
    global_cs,
    ls_id,
    [
      Pair(blake2b_224("id1"), ["1.1"]),
      Pair(blake2b_224("id2"), ["2.1", "2.2"]),
    ],
    simple_local_state.Mint(
      alias,
      ["0"],
      [
        simple_local_state.LocalStateData(
          blake2b_224("id1"),
          ["1.1"],
          blake2b_224("cs1"),
        ),
        simple_local_state.LocalStateData(
          blake2b_224("id2"),
          ["2.1", "2.2"],
          "",
        ),
      ],
    ),
    ls_cs,
    Transaction {
      ..mint_local_state_succeed_tx,
      inputs: [
        Input(
          input_100_utxo_ref,
          create_global_output(
            alias,
            GlobalStateDatum {
              alias,
              local_state_data: [
                Pair(
                  blake2b_224("id1"),
                  hash_local_state(
                    serialise_hash_list(["1.1"]),
                    blake2b_224("cs1"),
                  ),
                ),
                Pair(
                  blake2b_224("id2"),
                  hash_local_state(serialise_hash_list(["2.1", "2.2"]), ""),
                ),
                Pair(ls_id, hash_local_state(serialise_hash_list(["0"]), "")),
              ],
            },
          ),
        ),
      ],
      outputs: [
        mock_script_output(
          from_script(ls_cs),
          create_min_ada_token_value(ls_cs, alias, 1),
          InlineDatum(["0"]),
        ),
      ],
      redeemers: [Pair(Spend(input_100_utxo_ref), red)],
    },
  )
}

test simple_local_state_new_state_succeed() {
  simple_local_state.simple_local_state.spend(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    Some(["a", "b", "c"]),
    simple_local_state.Issue(alias, ["0", "1", "2"]),
    mock_utxo_ref("0", 0),
    Transaction {
      ..placeholder,
      inputs: [
        Input(
          mock_utxo_ref("0", 0),
          mock_script_output(
            from_script(ls_cs),
            create_min_ada_token_value(ls_cs, alias, 1),
            InlineDatum(["a", "b", "c"]),
          ),
        ),
      ],
      outputs: [
        mock_pub_key_output(
          mock_pub_key_address("owner"),
          create_min_ada_token_value(ls_id, "owner", 1),
        ),
        mock_script_output(
          from_script(ls_cs),
          create_min_ada_token_value(ls_cs, alias, 1),
          InlineDatum(["0", "1", "2"]),
        ),
      ],
    },
  )
}

test simple_local_state_burn_succeed() {
  let red: Data =
    BurnLocalState(
      ls_id,
      0,
      serialise_hash_list([]),
      ls_cs,
      serialise_hash_list(["1", "2", "3"]),
    )

  simple_local_state.simple_local_state.spend(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    Some(["1", "2", "3"]),
    simple_local_state.Burn(alias),
    mock_utxo_ref("0", 0),
    Transaction {
      ..placeholder,
      inputs: [
        Input(
          input_100_utxo_ref,
          create_global_output(alias, create_empty_gs_dat(alias)),
        ),
        Input(
          mock_utxo_ref("0", 0),
          mock_script_output(
            from_script(ls_cs),
            create_min_ada_token_value(ls_cs, alias, 1),
            InlineDatum(["1", "2", "3"]),
          ),
        ),
      ],
      mint: from_asset(ls_cs, alias, -1),
      redeemers: [Pair(Spend(input_100_utxo_ref), red)],
    },
  )
}
