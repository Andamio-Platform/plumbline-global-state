use aiken/builtin.{
  b_data, blake2b_224, head_list, integer_to_bytearray, un_b_data,
}
use cardano/assets.{add, from_asset, from_lovelace, zero}
use cardano/transaction.{InlineDatum, Input, Output, Spend}
use plumbline/plumb_global_state.{
  at_validate, get_local_state_data, validate_global_state_burn_ls,
  validate_global_state_mint_ls_no_prereqs,
  validate_global_state_mint_ls_with_prereqs,
}
use plumbline/plumb_input.{
  find_input, find_input_with_policy, find_input_with_single_token,
  in_out_token_address_same, merge_value_inputs,
}
use plumbline/plumb_output.{
  find_output_with_addr, find_output_with_single_token, merge_values_output,
  policy_id_present_in_outputs,
}
use plumbline/plumb_redeemers.{
  get_single_token_spend_redeemer,
  get_single_token_spend_redeemer_by_constructor,
}
use plumbline/plumb_value.{
  create_global_tn, flat_val_paid, flat_val_to_value, geq_value, quantity_is_one,
  single_name_of_policy_id, substract_value, two_token_value,
}
use plumbline/types/flat_value.{FlatValue}
use plumbline/types/global_state.{
  BurnLocalState, GlobalStateDatum, MintLocalState,
}
use plumbproof.{
  create_min_ada_token_value, input_user_token, mock_input, mock_pub_key_address,
  mock_pub_key_output, mock_pub_key_token_output_by_bytearray,
  mock_script_output, mock_utxo_ref, output_user_token,
}

// Global State

const existing = [Pair("a", "da"), Pair("b", "db"), Pair("c", "dc")]

const new_pairs = [Pair("a", "da"), Pair("c", "dc")]

// at_validate
test at_validate_succeed() {
  at_validate(existing, [], "b", "db", 1) == new_pairs
}

test at_validate_fail1_overflow_index() fail {
  at_validate(existing, [], "b", "db", 3) == new_pairs
}

test at_validate_fail2_wrong_key() fail {
  at_validate(existing, [], "a", "db", 1) == new_pairs
}

test at_validate_fail3_value() fail {
  at_validate(existing, [], "b", "bb", 1) == new_pairs
}

test at_validate_fail4_wrong_index() fail {
  at_validate(existing, [], "b", "db", 2) == new_pairs
}

const global_global_token_input =
  Input(
    mock_utxo_ref("0", 0),
    mock_script_output(
      mock_pub_key_address("a"),
      create_min_ada_token_value(
        blake2b_224("global_cs"),
        create_global_tn("alias"),
        1,
      ),
      InlineDatum(
        GlobalStateDatum(
          "alias",
          [
            Pair("ls_id1", "ls_data1"), Pair("ls_id2", "ls_data2"),
            Pair("ls_id3", "ls_data3"),
          ],
        ),
      ),
    ),
  )

const redeemer_global_token =
  MintLocalState("ls_id", 0, "ls_data_hash", "ls_cs")

// validate_global_state_mint_ls_no_prereqs
test validate_global_state_mint_ls_no_prereqs_succeed() {
  let inputs = [global_global_token_input]
  let redeemer: Data = redeemer_global_token
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_mint_ls_no_prereqs(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    "ls_id",
    "ls_data_hash",
    "ls_cs",
  )
}

test validate_global_state_mint_ls_no_prereqs_fail1_ls_id() fail {
  let inputs = [global_global_token_input]
  let redeemer: Data = redeemer_global_token
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_mint_ls_no_prereqs(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    "ls_id1",
    "ls_data_hash",
    "ls_cs",
  )
}

test validate_global_state_mint_ls_no_prereqs_fail2_ls_data() fail {
  let inputs = [global_global_token_input]
  let redeemer: Data = redeemer_global_token
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_mint_ls_no_prereqs(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    "ls_id",
    "ls_data_hash1",
    "ls_cs",
  )
}

test validate_global_state_mint_ls_no_prereqs_fail3_ls_cs() fail {
  let inputs = [global_global_token_input]
  let redeemer: Data = redeemer_global_token
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_mint_ls_no_prereqs(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    "ls_id",
    "ls_data_hash",
    "ls_cs1",
  )
}

// get_local_state_data
test get_local_state_data_succeed() {
  let inputs = [global_global_token_input]
  get_local_state_data(inputs, blake2b_224("global_cs"), "alias") == [
    Pair("ls_id1", "ls_data1"), Pair("ls_id2", "ls_data2"),
    Pair("ls_id3", "ls_data3"),
  ]
}

// validate_global_state_mint_ls_with_prereqs
test validate_global_state_mint_ls_with_prereqs_succeed() {
  let inputs = [global_global_token_input]
  let redeemer: Data = redeemer_global_token
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_mint_ls_with_prereqs(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    [Pair("ls_id3", "ls_data3")],
    "ls_id",
    "ls_data_hash",
    "ls_cs",
  )
}

test validate_global_state_mint_ls_with_prereqs_fail1_missing_prereqs() fail {
  let inputs = [global_global_token_input]
  let redeemer: Data = redeemer_global_token
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_mint_ls_with_prereqs(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    [Pair("ls_id4", "ls_data4")],
    "ls_id",
    "ls_data_hash",
    "ls_cs",
  )
}

// validate_global_state_burn_ls
test validate_global_state_burn_ls_succeed() {
  let inputs = [global_global_token_input]
  let redeemer: Data =
    BurnLocalState("ls_id", 0, "ls_data_hash", "ls_cs", "ls_new_data_hash")
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_burn_ls(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    "ls_id",
    "ls_cs",
    "ls_new_data_hash",
  )
}

test validate_global_state_burn_ls_fail1_wrong_new_data() fail {
  let inputs = [global_global_token_input]
  let redeemer: Data =
    BurnLocalState("ls_id", 0, "ls_data_hash", "ls_cs", "ls_new_data_hash")
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  validate_global_state_burn_ls(
    inputs,
    redeemers,
    blake2b_224("global_cs"),
    "alias",
    "ls_id",
    "ls_cs",
    "ls_new_data_hash_wrong",
  )
}

// Input

// find_input
test find_input_succeed() {
  let inputs =
    [
      Input(mock_utxo_ref("2", 2), output_user_token("A")),
      mock_input("a"),
      input_user_token("a"),
    ]
  find_input(inputs, mock_utxo_ref("0", 0)) == mock_input("a")
}

test find_input_fail1_no_ref() fail {
  let inputs =
    [
      Input(mock_utxo_ref("2", 2), output_user_token("A")),
      mock_input("a"),
      input_user_token("a"),
    ]
  find_input(inputs, mock_utxo_ref("10", 0)) == mock_input("a")
}

// find_input_with_policy
test find_input_with_policy_succeed() {
  let inputs = [mock_input("cs1"), mock_input("cs2"), mock_input("cs3")]
  find_input_with_policy(inputs, blake2b_224("cs3")) == mock_input("cs3")
}

test find_input_with_policy_fail1_cs() fail {
  let inputs = [mock_input("cs1"), mock_input("cs2"), mock_input("cs3")]
  find_input_with_policy(inputs, blake2b_224("cs4")) == mock_input("cs3")
}

// find_input_with_single_token
test find_input_with_single_token_test_true() {
  let outs = [mock_input("cs1"), mock_input("cs2")]
  find_input_with_single_token(outs, blake2b_224("cs2"), "cs2") == mock_input(
    "cs2",
  )
}

test find_input_with_single_token_test_fail() fail {
  let outs = [mock_input("cs1"), mock_input("cs2")]
  find_input_with_single_token(outs, blake2b_224("cs3"), "cs3") == mock_input(
    "cs2",
  )
}

// in_out_token_address_same
test in_out_token_address_same_success() {
  let inputs = [mock_input("a"), mock_input("c"), mock_input("d")]
  let outputs =
    [
      mock_pub_key_token_output_by_bytearray("a"),
      mock_pub_key_token_output_by_bytearray("c"),
      mock_pub_key_token_output_by_bytearray("d"),
    ]
  in_out_token_address_same(inputs, outputs, blake2b_224("a"), "a")
}

test in_out_token_address_same_fail_() fail {
  let inputs = [mock_input("a"), mock_input("c"), mock_input("d")]
  let outputs =
    [
      Output {
        ..mock_pub_key_token_output_by_bytearray("a"),
        address: mock_pub_key_address("b"),
      },
      mock_pub_key_token_output_by_bytearray("c"),
      mock_pub_key_token_output_by_bytearray("d"),
    ]
  in_out_token_address_same(inputs, outputs, blake2b_224("a"), "a")?
}

// merge_value_inputs
test merge_value_inputs_succeed_ada() {
  let inputs =
    [
      Input(mock_utxo_ref("0", 0), mock_key_token_output_simple(5)),
      Input(mock_utxo_ref("0", 0), mock_key_token_output_simple(10)),
      Input(mock_utxo_ref("0", 0), mock_key_token_output_simple(20)),
    ]
  merge_value_inputs(inputs) == from_lovelace(35)
}

test merge_value_inputs_succeed_native() {
  let inputs =
    [
      Input(
        mock_utxo_ref("0", 0),
        mock_pub_key_output(
          mock_pub_key_address("0"),
          add(from_lovelace(5), "cs1", "tn1", 10),
        ),
      ),
      Input(
        mock_utxo_ref("0", 0),
        mock_pub_key_output(
          mock_pub_key_address("1"),
          add(from_lovelace(10), "cs1", "tn1", 112),
        ),
      ),
      Input(mock_utxo_ref("0", 0), mock_key_token_output_simple(20)),
    ]
  merge_value_inputs(inputs) == add(from_lovelace(35), "cs1", "tn1", 122)
}

// Output

// policy_id_present_in_outputs
test policy_id_present_in_outputs_test_true() {
  let outs =
    [
      mock_pub_key_token_output_by_bytearray("cs0"),
      mock_pub_key_token_output_by_bytearray("cs1"),
    ]
  policy_id_present_in_outputs(outs, blake2b_224("cs1"))
}

test policy_id_present_in_outputs_test_fail() fail {
  let outs = [mock_pub_key_token_output_by_bytearray("cs1")]
  policy_id_present_in_outputs(outs, blake2b_224("cs2"))
}

// find_output_with_single_token
test find_output_with_single_token_test_true() {
  let outs =
    [
      mock_pub_key_token_output_by_bytearray("cs1"),
      mock_pub_key_token_output_by_bytearray("cs2"),
    ]
  find_output_with_single_token(outs, blake2b_224("cs2"), "cs2") == mock_pub_key_token_output_by_bytearray(
    "cs2",
  )
}

test find_output_with_single_token_fail() fail {
  let outs =
    [
      mock_pub_key_token_output_by_bytearray("cs1"),
      mock_pub_key_token_output_by_bytearray("cs2"),
    ]
  find_output_with_single_token(outs, blake2b_224("cs3"), "cs3") == mock_pub_key_token_output_by_bytearray(
    "cs2",
  )
}

/// Create output with just ada.
fn mock_key_token_output_simple(variant: Int) -> Output {
  mock_pub_key_output(
    mock_pub_key_address(integer_to_bytearray(True, 0, variant)),
    from_lovelace(variant),
  )
}

// find_output_with_addr
test find_output_with_addr_succeed() {
  let outputs =
    [
      mock_pub_key_token_output_by_bytearray("0"),
      mock_pub_key_token_output_by_bytearray("1"),
      mock_pub_key_token_output_by_bytearray("2"),
    ]
  find_output_with_addr(outputs, mock_pub_key_address("1")) == mock_pub_key_token_output_by_bytearray(
    "1",
  )
}

test find_output_with_addr_fail1() fail {
  let outputs =
    [
      mock_pub_key_token_output_by_bytearray("0"),
      mock_pub_key_token_output_by_bytearray("1"),
      mock_pub_key_token_output_by_bytearray("2"),
    ]
  find_output_with_addr(outputs, mock_pub_key_address("3")) == mock_pub_key_token_output_by_bytearray(
    "2",
  )
}

// merge_values_output
test merge_values_output_succeed_ada() {
  let outputs =
    [
      mock_pub_key_output(mock_pub_key_address("0"), from_lovelace(5)),
      mock_pub_key_output(mock_pub_key_address("1"), from_lovelace(10)),
      mock_pub_key_output(mock_pub_key_address("2"), from_lovelace(20)),
    ]
  merge_values_output(outputs) == from_lovelace(35)
}

test merge_values_output_succeed_native() {
  let outputs =
    [
      mock_pub_key_output(
        mock_pub_key_address("0"),
        add(from_lovelace(5), "cs1", "tn1", 10),
      ),
      mock_pub_key_output(
        mock_pub_key_address("1"),
        add(from_lovelace(10), "cs1", "tn1", 112),
      ),
      mock_pub_key_output(mock_pub_key_address("2"), from_lovelace(20)),
    ]
  merge_values_output(outputs) == add(from_lovelace(35), "cs1", "tn1", 122)
}

// Redeemers

// get_single_token_spend_redeemer
test get_single_token_spend_redeemer_succeed() {
  let inputs =
    [
      Input(
        mock_utxo_ref("0", 0),
        mock_pub_key_output(
          mock_pub_key_address("a"),
          create_min_ada_token_value(blake2b_224("a"), "a", 1),
        ),
      ),
    ]
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), b_data("b"))]
  get_single_token_spend_redeemer(inputs, redeemers, blake2b_224("a"), "a") == b_data(
    "b",
  )
}

test get_single_token_spend_redeemer_fail1_ref() fail {
  let inputs =
    [
      Input(
        mock_utxo_ref("0", 0),
        mock_pub_key_output(
          mock_pub_key_address("a"),
          create_min_ada_token_value(blake2b_224("a"), "a", 1),
        ),
      ),
    ]
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 1)), b_data("b"))]
  get_single_token_spend_redeemer(inputs, redeemers, blake2b_224("a"), "a") == b_data(
    "b",
  )
}

type MyRedeemer {
  One(ByteArray)
  Two(ByteArray)
}

// get_single_token_spend_redeemer_by_constructor
test get_single_token_spend_redeemer_by_constructor_succeed() {
  let inputs =
    [
      Input(
        mock_utxo_ref("0", 0),
        mock_pub_key_output(
          mock_pub_key_address("a"),
          create_min_ada_token_value(blake2b_224("a"), "a", 1),
        ),
      ),
    ]
  let redeemer: Data = One("b")
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  un_b_data(
    head_list(
      get_single_token_spend_redeemer_by_constructor(
        inputs,
        redeemers,
        0,
        blake2b_224("a"),
        "a",
      ),
    ),
  ) == "b"
}

test get_single_token_spend_redeemer_by_constructor_fail1_constructor() fail {
  let inputs =
    [
      Input(
        mock_utxo_ref("0", 0),
        mock_pub_key_output(
          mock_pub_key_address("a"),
          create_min_ada_token_value(blake2b_224("a"), "a", 1),
        ),
      ),
    ]
  let redeemer: Data = Two("b")
  let redeemers = [Pair(Spend(mock_utxo_ref("0", 0)), redeemer)]
  un_b_data(
    head_list(
      get_single_token_spend_redeemer_by_constructor(
        inputs,
        redeemers,
        0,
        blake2b_224("a"),
        "a",
      ),
    ),
  ) == "b"
}

// Value

const some_value =
  zero
    |> add("cs1", "tn1", 1)
    |> add("cs2", "tn2", 1)
    |> add("cs3", "tn3", 1)

// single_name_of_policy_id
test single_name_of_policy_id_succed() {
  single_name_of_policy_id(some_value, "cs2", "tn2", 1)?
}

test single_name_of_policy_id_fail_amount() fail {
  single_name_of_policy_id(add(some_value, "cs2", "tn2", 1), "cs2", "tn2", 1)?
}

test single_name_of_policy_id_fail_size() fail {
  let some_value =
    zero
      |> add("cs1", "tn1", 1)
      |> add("cs2", "tn2", 1)
      |> add("cs2", "tn3", 1)
  single_name_of_policy_id(some_value, "cs2", "tn2", 1)?
}

test single_name_of_policy_id_fail_cs() fail {
  let some_value =
    zero
      |> add("cs1", "tn1", 1)
      |> add("cs4", "tn2", 1)
      |> add("cs3", "tn3", 1)
  single_name_of_policy_id(some_value, "cs2", "tn2", 1)?
}

// two_token_value
test two_token_value_test_true() {
  let value = create_min_ada_token_value(blake2b_224("cs1"), "cs1", 2)
  two_token_value(value)?
}

test two_token_value_test_fail1() fail {
  let value = add(from_asset("cs2", "tn1", 1), "cs2", "tn2", 2)
  two_token_value(value)?
}

test two_token_value_test_fail2() fail {
  let value =
    add(add(from_asset("cs2", "tn1", 1), "cs2", "tn2", 2), "cs3", "tn3", 3)
  two_token_value(value)?
}

// quantity_is_one
test quantity_is_one_test_success() {
  let value1 = add(from_asset("cs2", "tn1", 1), "cs2", "tn2", 2)
  quantity_is_one(value1, "cs2", "tn1")
}

test quantity_is_one_test_fail() fail {
  let value1 = add(from_asset("cs2", "tn1", 1), "cs2", "tn2", 2)
  quantity_is_one(value1, "cs2", "tn2")
}

// geq_value
test geq_value_succeed() {
  let value1 = create_min_ada_token_value(blake2b_224("cs1"), "cs1", 5)
  let value2 = create_min_ada_token_value(blake2b_224("cs1"), "cs1", 6)
  geq_value(value2, value1)
}

test geq_value_fail1() fail {
  let value1 = create_min_ada_token_value(blake2b_224("cs1"), "cs1", 5)
  let value2 = create_min_ada_token_value(blake2b_224("cs1"), "cs1", 6)
  geq_value(value1, value2)
}

test geq_value_fail2() fail {
  let value1 = create_min_ada_token_value(blake2b_224("cs1"), "cs1", 5)
  let value2 = from_lovelace(5)
  geq_value(value2, value1)
}

// substract_value
test substract_value_succeed1() {
  substract_value(from_lovelace(5), from_lovelace(10)) == from_lovelace(5)
}

test substract_value_succeed2() {
  substract_value(
    add(from_lovelace(10), "cs1", "tn1", 5),
    add(from_lovelace(5), "cs1", "tn1", 5),
  ) == add(from_lovelace(-5), "cs1", "tn1", 0)
}

const sample_value =
  zero
    |> add("cs1", "tn1", 43)
    |> add("cs2", "tn2", 34)
    |> add("cs3", "tn3", 98)
    |> add("cs4", "tn4", 3)

const flat_v_true =
  [
    FlatValue("cs1", "tn1", 43),
    FlatValue("cs2", "tn2", 34),
    FlatValue("cs3", "tn3", 98),
    FlatValue("cs4", "tn4", 3),
  ]

const flat_v_false =
  [
    FlatValue("cs1", "tn1", 43),
    FlatValue("cs2", "tn2", 34),
    FlatValue("cs3", "tn3", 98),
    FlatValue("cs4", "tn4", 5),
  ]

// flat_val_paid
test flat_val_paid_succeed() {
  flat_val_paid(flat_v_true, sample_value)
}

test flat_val_paid_fail() fail {
  flat_val_paid(flat_v_false, sample_value)
}

test flat_val_to_value_succeed() {
  flat_val_to_value(flat_v_true, zero) == sample_value
}

test flat_val_to_value_fail1() fail {
  flat_val_to_value(flat_v_false, zero) == sample_value
}
