use aiken/builtin.{head_list, snd_pair, tail_list}
use aiken/collection/dict.{empty, insert, size, to_pairs}
use aiken/collection/list.{all}
use aiken/primitive/bytearray.{concat}
use cardano/assets.{
  AssetName, PolicyId, Value, add, quantity_of, to_dict, tokens,
  without_lovelace, zero,
}
use plumbline/types/flat_value.{FlatValue}

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
