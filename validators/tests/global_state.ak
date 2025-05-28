use aiken/collection/list.{drop, push, take}
use cardano/address.{Script}
use cardano/assets.{PolicyId, from_asset, zero}
use cardano/transaction.{InlineDatum, Input, Output, Transaction, placeholder}
use global/global_state as gs
use plumbline/plumb_global_state.{hash_local_state}
use mocktail.{mock_script_address, mock_script_output, mock_utxo_ref}
use plumbline/plumb_value.{create_100}
use tests/utils.{
  create_empty_gs_dat, create_global_output, create_min_ada_token_value,
  global_cs, global_state_addr, global_state_addr_v1, index_ref_cs,
  index_scripts_tn, init_global_obs_sh, input_222, local_state_cs,
  local_state_id, local_state_reference_cs, output_222, stake_cred,
  state_token_name,
}
use plumbline/types/global_state.{
  BurnLocalState, DeleteState, GlobalStateAction, GlobalStateDatum,
  LocalStateInformation, MintLocalState, MoveState,
}
use types/index_data.{IndexData}

// create global state input
fn create_global_input(alias: ByteArray, dat: GlobalStateDatum) -> Input {
  Input {
    output_reference: mock_utxo_ref(0, 0),
    output: create_global_output(alias, dat),
  }
}

// create input and output to succeed validate_input_and_output
fn validate_input_and_output_succeed_lists(
  user_name: ByteArray,
) -> Pair<List<Input>, List<Output>> {
  let inputs =
    [
      input_222(user_name),
      create_global_input(user_name, create_empty_gs_dat(user_name)),
    ]
  let outputs =
    [
      create_global_output(
        user_name,
        create_gs_dat(
          create_empty_gs_dat(user_name),
          local_state_id,
          hash_local_state("", local_state_cs),
        ),
      ),
      output_222(user_name),
    ]
  Pair(inputs, outputs)
}

// validate_input_and_output succees test
test validate_input_and_output_succeed() {
  let user_name = "user_name"
  let Pair(inputs, outputs) = validate_input_and_output_succeed_lists(user_name)
  gs.validate_input_and_output(
    inputs,
    mock_utxo_ref(0, 0),
    outputs,
    global_cs,
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
  )
}

// validate_input_and_output fail test
// missing token from input
test validate_input_and_output_fail1_input() fail {
  let user_name = "user_name"
  let Pair(inputs, outputs) = validate_input_and_output_succeed_lists(user_name)
  gs.validate_input_and_output(
    push(
      take(inputs, 1),
      create_global_input("user_name1", create_empty_gs_dat(user_name)),
    ),
    mock_utxo_ref(0, 0),
    outputs,
    global_cs,
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
  )
}

// validate_input_and_output fail test
// wrong 222 token
test validate_input_and_output_fail2_222() fail {
  let user_name = "user_name"
  let Pair(inputs, outputs) = validate_input_and_output_succeed_lists(user_name)
  gs.validate_input_and_output(
    push(drop(inputs, 1), input_222("user_name1")),
    mock_utxo_ref(0, 0),
    push(take(outputs, 1), output_222("user_name1")),
    global_cs,
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
  )
}

// validate_input_and_output fail test
// wrong output address
test validate_input_and_output_fail3_output_addr() fail {
  let user_name = "user_name"
  let Pair(inputs, outputs) = validate_input_and_output_succeed_lists(user_name)
  gs.validate_input_and_output(
    inputs,
    mock_utxo_ref(0, 0),
    push(
      drop(outputs, 1),
      Output {
        address: global_state_addr_v1,
        value: create_min_ada_token_value(global_cs, create_100(user_name)),
        datum: InlineDatum(
          create_gs_dat(
            create_empty_gs_dat(user_name),
            local_state_id,
            hash_local_state("", local_state_cs),
          ),
        ),
        reference_script: None,
      },
    ),
    global_cs,
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
  )
}

// validate_input_and_output fail test
// wrong output datum
test validate_input_and_output_fail4_output_datum() fail {
  let user_name = "user_name"
  let Pair(inputs, outputs) = validate_input_and_output_succeed_lists(user_name)
  gs.validate_input_and_output(
    inputs,
    mock_utxo_ref(0, 0),
    push(
      drop(outputs, 1),
      Output {
        address: global_state_addr,
        value: create_min_ada_token_value(global_cs, create_100(user_name)),
        datum: InlineDatum(create_empty_gs_dat(user_name)),
        reference_script: None,
      },
    ),
    global_cs,
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
  )
}

// validate_input_and_output fail test
// wrong output value
test validate_input_and_output_fail5_output_value() fail {
  let user_name = "user_name"
  let Pair(inputs, outputs) = validate_input_and_output_succeed_lists(user_name)
  gs.validate_input_and_output(
    inputs,
    mock_utxo_ref(0, 0),
    push(
      drop(outputs, 1),
      Output {
        address: global_state_addr,
        value: create_min_ada_token_value(global_cs, user_name),
        datum: InlineDatum(
          create_gs_dat(
            create_empty_gs_dat(user_name),
            local_state_id,
            hash_local_state("", local_state_cs),
          ),
        ),
        reference_script: None,
      },
    ),
    global_cs,
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
  )
}

// add local state to global state datum
fn create_gs_dat(
  gs_dat: GlobalStateDatum,
  ls_id: PolicyId,
  creds: ByteArray,
) -> GlobalStateDatum {
  let gs_datum =
    GlobalStateDatum {
      ..gs_dat,
      local_state_data: push(gs_dat.local_state_data, Pair(ls_id, creds)),
    }
  gs_datum
}

// call spending
fn global_state_spend(
  dat: GlobalStateDatum,
  red: GlobalStateAction,
  tx: Transaction,
) {
  gs.global_state_validator.spend(
    global_cs,
    index_ref_cs,
    local_state_reference_cs,
    Some(dat),
    red,
    mock_utxo_ref(0, 0),
    tx,
  )
}

// global state mint local state succeed transaction
fn global_state_spend_mint_success_tx(user_name: ByteArray) -> Transaction {
  let Pair(inputs, outputs) = validate_input_and_output_succeed_lists(user_name)
  Transaction {
    ..placeholder,
    inputs: inputs,
    reference_inputs: [
      Input(
        mock_utxo_ref(8, 9),
        Output {
          address: mock_script_address(8, None),
          value: create_min_ada_token_value(
            local_state_reference_cs,
            state_token_name,
          ),
          datum: InlineDatum(local_state_id),
          reference_script: Some(local_state_cs),
        },
      ),
    ],
    outputs: outputs,
    mint: from_asset(local_state_cs, user_name, 1),
  }
}

// global state mint succeed
test global_state_spend_mint_success1_empty() {
  let user_name = "user_name"
  global_state_spend(
    create_empty_gs_dat(user_name),
    MintLocalState(
      LocalStateInformation(local_state_id, -1, "", local_state_cs),
    ),
    global_state_spend_mint_success_tx(user_name),
  )
}

// global state mint fail
// no local state minting
test global_state_spend_mint_fail1_minting() fail {
  let user_name = "user_name"
  global_state_spend(
    create_empty_gs_dat(user_name),
    MintLocalState(
      LocalStateInformation(local_state_id, -1, "", local_state_cs),
    ),
    Transaction { ..global_state_spend_mint_success_tx(user_name), mint: zero },
  )
}

// global state mint fail
// no reference script
test global_state_spend_mint_fail2_reference() fail {
  let user_name = "user_name"
  global_state_spend(
    create_empty_gs_dat(user_name),
    MintLocalState(
      LocalStateInformation(local_state_id, -1, "", local_state_cs),
    ),
    Transaction {
      ..global_state_spend_mint_success_tx(user_name),
      reference_inputs: [],
    },
  )
}

// global state burn local state succeed transaction
fn global_state_spend_burn_success_tx(user_name: ByteArray) -> Transaction {
  Transaction {
    ..placeholder,
    inputs: [
      input_222(user_name),
      create_global_input(
        user_name,
        create_gs_dat(
          create_empty_gs_dat(user_name),
          local_state_id,
          hash_local_state("", local_state_cs),
        ),
      ),
    ],
    outputs: [
      create_global_output(
        user_name,
        create_gs_dat(
          create_empty_gs_dat(user_name),
          local_state_id,
          hash_local_state("", ""),
        ),
      ),
      output_222(user_name),
    ],
    mint: from_asset(local_state_cs, user_name, -1),
  }
}

// global state burn local state succeed test
test global_state_spend_burn_success1_empty() {
  let user_name = "user_name"

  global_state_spend(
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
    BurnLocalState(
      LocalStateInformation(local_state_id, 0, "", local_state_cs),
      "",
    ),
    global_state_spend_burn_success_tx(user_name),
  )
}

// global state burn local state fail test
// no burning of local state token
test global_state_spend_burn_fail1_minting() fail {
  let user_name = "user_name"

  global_state_spend(
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
    BurnLocalState(
      LocalStateInformation(local_state_id, -1, "", local_state_cs),
      "",
    ),
    Transaction { ..global_state_spend_burn_success_tx(user_name), mint: zero },
  )
}

// global state delete local state succeed transaction
fn global_state_spend_delete_success_tx(user_name: ByteArray) -> Transaction {
  Transaction {
    ..placeholder,
    inputs: [
      input_222(user_name),
      create_global_input(
        user_name,
        create_gs_dat(
          create_empty_gs_dat(user_name),
          local_state_id,
          hash_local_state("", ""),
        ),
      ),
    ],
    outputs: [
      create_global_output(user_name, create_empty_gs_dat(user_name)),
      output_222(user_name),
    ],
  }
}

// global state delete local state succeed test
test global_state_spend_delete_success1_empty() {
  let user_name = "user_name"

  global_state_spend(
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", ""),
    ),
    DeleteState(local_state_id, "", 0),
    global_state_spend_delete_success_tx(user_name),
  )
}

fn global_state_spend_move_success_tx(user_name: ByteArray) -> Transaction {
  let init_global_obs_data: Data = Script(init_global_obs_sh)
  Transaction {
    ..placeholder,
    inputs: [
      input_222(user_name),
      create_global_input(
        user_name,
        create_gs_dat(
          create_empty_gs_dat(user_name),
          local_state_id,
          hash_local_state("", local_state_cs),
        ),
      ),
    ],
    reference_inputs: [
      Input(
        mock_utxo_ref(11, 7),
        mock_script_output(
          mock_script_address(11, None),
          create_min_ada_token_value(index_ref_cs, index_scripts_tn),
          InlineDatum(
            IndexData(
              mock_script_address(13, Some(stake_cred)),
              "",
              [],
              [init_global_obs_data],
            ),
          ),
        ),
      ),
    ],
    outputs: [output_222(user_name)],
    withdrawals: [Pair(Script(init_global_obs_sh), 0)],
  }
}

test global_state_spend_move_success1_empty() {
  let user_name = "user_name"

  global_state_spend(
    create_gs_dat(
      create_empty_gs_dat(user_name),
      local_state_id,
      hash_local_state("", local_state_cs),
    ),
    MoveState(init_global_obs_sh),
    global_state_spend_move_success_tx(user_name),
  )
}
