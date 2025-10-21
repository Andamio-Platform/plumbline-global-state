use aiken/collection/dict.{empty, insert, size, to_pairs}
use aiken/collection/list.{all}
use aiken/primitive/bytearray.{concat}
use cardano/assets.{
  AssetName, PolicyId, Value, add, flatten, quantity_of, to_dict, tokens,
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
    [Pair(_cs, tn_ams)] -> size(tn_ams) == 1
    _ -> False
  }
}

/// Create a `ByteArray` with `u` as prefix.
/// Useed for user tokens.
pub fn create_user_tn(alias: ByteArray) -> ByteArray {
  concat(#"75", alias)
}

/// Create a `ByteArray` with `g` as prefix.
/// Useful for reference tokens.
pub fn create_global_tn(alias: ByteArray) -> ByteArray {
  concat(#"67", alias)
}

/// Check there exists a policy id and token name with amount 1 in a value.
pub fn quantity_is_one(value: Value, cs: PolicyId, tn: AssetName) -> Bool {
  quantity_of(value, cs, tn) == 1
}

/// Check first value is greater or equal to second one.
pub fn geq_value(gr_value: Value, l_value: Value) -> Bool {
  all(
    flatten(l_value),
    fn((cs, tn, am)) { quantity_of(gr_value, cs, tn) >= am },
  )
}

/// Substract first from second value.
pub fn substract_value(value: Value, flat_val: Value) -> Value {
  substract_value_helper(value, flatten(flat_val))
}

fn substract_value_helper(
  value: Value,
  flat_val: List<(PolicyId, AssetName, Int)>,
) -> Value {
  when flat_val is {
    [] -> zero
    [(cs, tn, am), ..xs] ->
      add(
        substract_value_helper(value, xs),
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
  when flat_val is {
    [] -> value
    [x, ..xs] ->
      flat_val_to_value(xs, add(value, x.policy_id, x.token_name, x.amount))
  }
}
