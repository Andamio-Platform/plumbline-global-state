use aiken/builtin.{blake2b_224, head_list, snd_pair, tail_list}
use aiken/collection/dict.{empty, insert, size, to_pairs}
use aiken/collection/list.{all}
use aiken/primitive/bytearray.{concat}
use cardano/assets.{
  AssetName, PolicyId, Value, add, flatten, from_asset, from_lovelace,
  quantity_of, to_dict, tokens, without_lovelace, zero,
}

/// Check if only one token name with a specific policy id is an value with given amount.
/// Useful to check minting values.
pub fn single_name_of_policy_id(
  value: Value,
  cs: PolicyId,
  tn: AssetName,
  am: Int,
) -> Bool {
  insert(empty, tn, am) == tokens(value, cs)
}

/// Check there are exactly 2 tokens in a value.
/// Useful to check there is only ada and one native token in a value.
pub fn two_token_value(value: Value) -> Bool {
  when
    value
      |> without_lovelace
      |> to_dict
      |> to_pairs
  is {
    [tnams] ->
      (
        tnams
          |> snd_pair
          |> size
      ) == 1
    _ -> False
  }
}

/// Create a `ByteArray` with 222 as prefix.
/// Useful for CIP68 tokens.
pub fn create_222(alias: ByteArray) -> ByteArray {
  concat(#"323232", alias)
}

/// Create a `ByteArray` with 100 as prefix.
/// Useful for CIP68 tokens.
pub fn create_100(alias: ByteArray) -> ByteArray {
  concat(#"313030", alias)
}

/// Check there exists a policy id and token name with amount 1 in a value.
pub fn quantity_is_one(value: Value, cs: PolicyId, tn: AssetName) -> Bool {
  quantity_of(value, cs, tn) == 1
}

/// Check first value is greater or equal to second one.
pub fn geq_value(
  value: Value,
  flat_val: List<(PolicyId, AssetName, Int)>,
) -> Bool {
  all(flat_val, fn((cs, tn, am)) { quantity_of(value, cs, tn) >= am })
}

/// Substract first from second value.
pub fn substract_value(
  value: Value,
  flat_val: List<(PolicyId, AssetName, Int)>,
) -> Value {
  if flat_val == [] {
    zero
  } else {
    let (cs, tn, am) = head_list(flat_val)
    add(
      substract_value(value, tail_list(flat_val)),
      cs,
      tn,
      am - quantity_of(value, cs, tn),
    )
  }
}

/// Flatten Value to use as datum/redeemer.
pub type FlatValue {
  policy_id: PolicyId,
  token_name: AssetName,
  amount: Int,
}

/// Validate if a `FlatValue` exists in a `Value`.
pub fn flat_val_paid(flat_val: List<FlatValue>, value: Value) -> Bool {
  all(
    flat_val,
    fn(flat_val) {
      quantity_of(value, flat_val.policy_id, flat_val.token_name) >= flat_val.amount
    },
  )
}

/// Create a `Value` out of a `FlatValue`.
pub fn flat_val_to_value(flat_val: List<FlatValue>, value: Value) -> Value {
  if flat_val == [] {
    value
  } else {
    let flat_v = head_list(flat_val)
    flat_val_to_value(
      tail_list(flat_val),
      add(value, flat_v.policy_id, flat_v.token_name, flat_v.amount),
    )
  }
}

// ### testing
// Create output where bytearray is tn and hashed as policy id.
// 2 Ada + token
pub fn create_min_ada_token_value(bytearray: ByteArray, am: Int) -> Value {
  add(from_lovelace(2_000_000), blake2b_224(bytearray), bytearray, am)
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
  let value = create_min_ada_token_value("cs1", 2)
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
  let value1 = create_min_ada_token_value("cs1", 5)
  let value2 = create_min_ada_token_value("cs1", 6)
  geq_value(value2, flatten(value1))
}

test geq_value_fail1() fail {
  let value1 = create_min_ada_token_value("cs1", 5)
  let value2 = create_min_ada_token_value("cs1", 6)
  geq_value(value1, flatten(value2))
}

test geq_value_fail2() fail {
  let value1 = create_min_ada_token_value("cs1", 5)
  let value2 = from_lovelace(5)
  geq_value(value2, flatten(value1))
}

test substract_value_succeed1() {
  substract_value(from_lovelace(5), flatten(from_lovelace(10))) == from_lovelace(
    5,
  )
}

test substract_value_succeed2() {
  substract_value(
    add(from_lovelace(10), "cs1", "tn1", 5),
    flatten(add(from_lovelace(5), "cs1", "tn1", 5)),
  ) == add(from_lovelace(-5), "cs1", "tn1", 0)
}
