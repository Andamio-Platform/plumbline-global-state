use aiken/builtin.{fst_pair, head_list}
use aiken/collection/dict.{empty, insert, to_pairs}
use aiken/collection/list.{all, any}
use aiken/primitive/bytearray.{concat}
use cardano/assets.{
  AssetName, PolicyId, Value, add, flatten, policies, quantity_of, tokens, zero,
}
use plumbline/types/flat_value.{FlatValue}

pub fn token_present_in_value_lazy(
  value: Value,
  policy_id: PolicyId,
  tn: AssetName,
) -> Bool {
  tokens(value, policy_id)
    |> to_pairs
    |> any(fn(n) { fst_pair(n) == tn })
}

pub fn token_present_in_value_head(
  value: Value,
  policy_id: PolicyId,
  tn: AssetName,
) -> Bool {
  tokens(value, policy_id)
    |> to_pairs
    |> head_list
    |> fn(n) { fst_pair(n) == tn }
}

/// Check if a policy id is present in an output
pub fn policy_id_present_in_value(value: Value, policy_id: PolicyId) -> Bool {
  value
    |> policies
    |> any(fn(n) { n == policy_id })
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
    fn(FlatValue { policy_id, token_name, amount }) {
      quantity_of(value, policy_id, token_name) >= amount
    },
  )
}

/// Create a `Value` out of a `FlatValue`.
pub fn flat_val_to_value(flat_val: List<FlatValue>, value: Value) -> Value {
  when flat_val is {
    [] -> value
    [FlatValue { policy_id, token_name, amount }, ..xs] ->
      flat_val_to_value(xs, add(value, policy_id, token_name, amount))
  }
}
