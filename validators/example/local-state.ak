//// @hidden
//// NOT FOR PRODUCTION !!!

use aiken/builtin.{fst_pair, snd_pair}
use aiken/cbor.{serialise}
use aiken/collection/list
use aiken/crypto.{blake2b_224, blake2b_256}
use cardano/address.{from_script}
use cardano/assets.{PolicyId, from_asset}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Spend, Transaction, find_input,
  placeholder,
}
use plumbline.{
  get_script_hash_from_address, hash_local_state, policy_id_present_in_outputs,
  quantity_is_one, single_name_of_policy_id, validate_global_state_burn_ls,
  validate_global_state_mint_ls,
}
use plumbline/types/global_state.{
  BurnLocalState, GlobalStateDatum, LocalStateInformation, MintLocalState,
}
use plumbproof.{
  create_empty_gs_dat, create_global_output, create_min_ada_token_value,
  global_cs, mock_pub_key_address, mock_pub_key_output, mock_script_output,
  mock_utxo_ref,
}

pub type LocalStateData {
  local_state_id: PolicyId,
  local_state_data_clear: List<ByteArray>,
  local_state_cs: PolicyId,
}

pub type LocalStateAction {
  Mint(ByteArray, List<ByteArray>, Int, List<LocalStateData>)
  Issue(ByteArray, List<ByteArray>)
  Burn(ByteArray)
}

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
        expect Some(own_input) = find_input(inputs, output_reference)
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
        expect Some(own_input) = find_input(inputs, output_reference)
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
          blake2b_256(serialise(state)),
        )
      }
      _ -> fail
    }
  }

  mint(redeemer: LocalStateAction, policy_id: PolicyId, tx: Transaction) {
    when redeemer is {
      Mint(alias, state, ls_index, local_state_data) -> {
        let Transaction { inputs, outputs, mint, redeemers, .. } = tx
        let global_state_data_to_check =
          list.map(
            local_state_data,
            fn(lsd) {
              Pair(
                lsd.local_state_id,
                hash_local_state(
                  blake2b_256(serialise(lsd.local_state_data_clear)),
                  lsd.local_state_cs,
                ),
              )
            },
          )

        validate_global_state_mint_ls(
          inputs,
          redeemers,
          global_cs,
          alias,
          global_state_data_to_check,
          LocalStateInformation(
            local_state_id,
            ls_index,
            if state == [] {
              ""
            } else {
              blake2b_256(serialise(state))
            },
            policy_id,
          ),
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
      Burn(_alias) ->
        (policy_id_present_in_outputs(tx.outputs, policy_id) == False)?
      _ -> fail
    }
  }

  else(_) {
    fail
  }
}

const ls_id = blake2b_224("local_state_id")

const ls_cs = blake2b_224("loal_state_cs")

const alias = "user_name"

const input_100_utxo_ref = mock_utxo_ref("0", 1)

const mint_local_state_succeed_tx =
  Transaction { ..placeholder, mint: from_asset(ls_cs, alias, 1) }

test simple_local_state_mint_succeed_empty() {
  let red: Data = MintLocalState(LocalStateInformation(ls_id, -1, "", ls_cs))
  simple_local_state.mint(
    global_cs,
    ls_id,
    [],
    Mint(alias, [], -1, []),
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
  let red: Data = MintLocalState(LocalStateInformation(ls_id, 0, "", ls_cs))
  simple_local_state.mint(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    Mint(
      alias,
      [],
      0,
      [LocalStateData(blake2b_224("id1"), ["1.1"], blake2b_224("cs1"))],
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
                    blake2b_256(serialise(["1.1"])),
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
  let red: Data =
    MintLocalState(
      LocalStateInformation(ls_id, 0, blake2b_256(serialise(["0"])), ls_cs),
    )
  simple_local_state.mint(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    Mint(
      alias,
      ["0"],
      0,
      [LocalStateData(blake2b_224("id1"), ["1.1"], blake2b_224("cs1"))],
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
                    blake2b_256(serialise(["1.1"])),
                    blake2b_224("cs1"),
                  ),
                ),
                Pair(ls_id, hash_local_state(blake2b_256(serialise(["0"])), "")),
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
  let red: Data =
    MintLocalState(
      LocalStateInformation(ls_id, 0, blake2b_256(serialise(["0"])), ls_cs),
    )
  simple_local_state.mint(
    global_cs,
    ls_id,
    [
      Pair(blake2b_224("id1"), ["1.1"]),
      Pair(blake2b_224("id2"), ["2.1", "2.2"]),
    ],
    Mint(
      alias,
      ["0"],
      0,
      [
        LocalStateData(blake2b_224("id1"), ["1.1"], blake2b_224("cs1")),
        LocalStateData(blake2b_224("id2"), ["2.1", "2.2"], ""),
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
                    blake2b_256(serialise(["1.1"])),
                    blake2b_224("cs1"),
                  ),
                ),
                Pair(
                  blake2b_224("id2"),
                  hash_local_state(blake2b_256(serialise(["2.1", "2.2"])), ""),
                ),
                Pair(ls_id, hash_local_state(blake2b_256(serialise(["0"])), "")),
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
  simple_local_state.spend(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    Some(["a", "b", "c"]),
    Issue(alias, ["0", "1", "2"]),
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
      LocalStateInformation(ls_id, 0, blake2b_256(serialise([])), ls_cs),
      blake2b_256(serialise(["1", "2", "3"])),
    )

  simple_local_state.spend(
    global_cs,
    ls_id,
    [Pair(blake2b_224("id1"), ["1.1"])],
    Some(["1", "2", "3"]),
    Burn(alias),
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
