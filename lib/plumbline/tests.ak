use aiken/builtin.{blake2b_224, integer_to_bytearray}
use aiken/collection/list
use aiken/fuzz
use aiken/primitive/bytearray
use cardano/assets.{PolicyId, add, from_asset, from_lovelace, zero}
use cardano/transaction.{Input, Output}
use plumbline/plumb_address.{get_script_hash_from_address}
use plumbline/plumb_global_state.{create_new_gs_dat_delete, hash_local_state}
use plumbline/plumb_input.{
  find_input_with_single_token, in_out_token_address_same, merge_value_inputs,
}
use plumbline/plumb_output.{
  find_output_with_addr, find_output_with_single_token, merge_values_output,
  policy_id_present_in_outputs,
}
use plumbline/plumb_value.{
  flat_val_paid, flat_val_to_value, geq_value, quantity_is_one,
  single_name_of_policy_id, substract_value, two_token_value,
}
use plumbline/types/flat_value.{FlatValue}
use plumbline/types/global_state.{GlobalStateDatum}
use plumbproof.{
  create_min_ada_token_value, mock_input, mock_pub_key_address,
  mock_pub_key_output, mock_pub_key_token_output_by_bytearray,
  mock_script_address, mock_utxo_ref,
}

// Address
// test get_script_hash_from_address
test get_script_hash_from_address_succeed() {
  (get_script_hash_from_address(mock_script_address("0")) == blake2b_224("0"))?
}

test get_script_hash_from_address_fail() fail {
  (get_script_hash_from_address(mock_pub_key_address("0")) == blake2b_224("0"))?
}

// input

// ### testing

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

// output

// tests

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

test find_output_with_test_true() {
  let outs =
    [
      mock_pub_key_token_output_by_bytearray("cs1"),
      mock_pub_key_token_output_by_bytearray("cs2"),
    ]
  find_output_with_single_token(outs, blake2b_224("cs2"), "cs2") == mock_pub_key_token_output_by_bytearray(
    "cs2",
  )
}

test find_output_with_test_fail() fail {
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

// value

// tests

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

const some_value =
  zero
    |> add("cs1", "tn1", 1)
    |> add("cs2", "tn2", 1)
    |> add("cs3", "tn3", 1)

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

test quantity_is_one_test_success() {
  let value1 = add(from_asset("cs2", "tn1", 1), "cs2", "tn2", 2)
  quantity_is_one(value1, "cs2", "tn1")
}

test quantity_is_one_test_fail() fail {
  let value1 = add(from_asset("cs2", "tn1", 1), "cs2", "tn2", 2)
  quantity_is_one(value1, "cs2", "tn2")
}

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

test substract_value_succeed1() {
  substract_value(from_lovelace(5), from_lovelace(10)) == from_lovelace(5)
}

test substract_value_succeed2() {
  substract_value(
    add(from_lovelace(10), "cs1", "tn1", 5),
    add(from_lovelace(5), "cs1", "tn1", 5),
  ) == add(from_lovelace(-5), "cs1", "tn1", 0)
}

// global state

// ### bench and testing 

fn get_list_len(int: Int) -> Int {
  int + 30
}

fn create_sort_my_list(
  self: Fuzzer<List<(ByteArray, ByteArray, ByteArray)>>,
) -> Fuzzer<List<(ByteArray, ByteArray, ByteArray)>> {
  let list <- fuzz.and_then(self)
  fuzz.constant(
    list.sort(list, fn((a, _, _), (a1, _, _)) { bytearray.compare(a, a1) }),
  )
}

fn create_pair_ls_not_minted() -> Fuzzer<(ByteArray, ByteArray, ByteArray)> {
  let key <- fuzz.and_then(fuzz.bytearray_fixed(28))
  let ls_data <- fuzz.and_then(fuzz.bytearray_fixed(32))
  fuzz.constant((key, ls_data, ""))
}

fn pick_pairs_ls_not_minted(
  int: Int,
) -> Fuzzer<
  (Pairs<ByteArray, ByteArray>, (Int, (ByteArray, ByteArray, ByteArray))),
> {
  let list <-
    fuzz.and_then(
      create_sort_my_list(
        fuzz.list_between(
          create_pair_ls_not_minted(),
          get_list_len(int),
          get_list_len(int),
        ),
      ),
    )
  let elem <- fuzz.and_then(fuzz.pick(list))
  fuzz.constant(
    (
      list.map(
        list,
        fn((key, data, cs)) { Pair(key, hash_local_state(data, cs)) },
      ),
      elem,
    ),
  )
}

fn create_ls_not_minted_index(
  int: Int,
) -> Fuzzer<(GlobalStateDatum, (PolicyId, ByteArray, Int))> {
  let (gs, (index, (key, data, _cs))) <-
    fuzz.and_then(pick_pairs_ls_not_minted(int))
  fuzz.both(
    fuzz.constant(GlobalStateDatum("", gs)),
    fuzz.constant((key, data, index)),
  )
}

bench bench_gs_dat_delete(
  (gs, (ls_id, ls_data, ls_index)) via create_ls_not_minted_index,
) {
  create_new_gs_dat_delete(gs, ls_id, ls_data, ls_index)
}

const local_state_a = Pair("a", hash_local_state("data a", ""))

const local_state_b = Pair("b", hash_local_state("data b", ""))

const local_state_c_empty = Pair("c", hash_local_state("data c", ""))

const local_state_d = Pair("d", hash_local_state("data d", ""))

// succeed: local state delete if not minted
test create_new_gs_dat_delete_succeed() {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a, local_state_b, local_state_c_empty, local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [local_state_b, local_state_a, local_state_d],
    }
  create_new_gs_dat_delete(gs_dat_start, "c", "data c", 2) == gs_dat_end
}

// fail: local state delete, local state minted
test create_new_gs_dat_delete_fail1() fail {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "cs")),
        local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [local_state_a, local_state_b, local_state_d],
    }
  create_new_gs_dat_delete(gs_dat_start, "c", "data c", 2) == gs_dat_end
}
