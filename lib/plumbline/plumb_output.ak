use aiken/builtin.{head_list, tail_list}
use aiken/collection/list.{any, find}
use cardano/address.{Address}
use cardano/assets.{AssetName, PolicyId, Value, merge, policies, zero}
use cardano/transaction.{Output}
use plumbline/plumb_value.{quantity_is_one}

/// Check if a policy id is present in an output
pub fn policy_id_present_in_output(output: Output, policy_id: PolicyId) -> Bool {
  output.value
    |> policies
    |> any(fn(n) { n == policy_id })
}

/// Check if a policy id is present in a list of outputs
pub fn policy_id_present_in_outputs(
  outputs: List<Output>,
  policy_id: PolicyId,
) -> Bool {
  any(outputs, fn(output) { policy_id_present_in_output(output, policy_id) })
}

/// Find an output which has a token with quantity one attached.
/// Fails if quantity > 1 or there is no utxo with that token attached.
pub fn find_output_with_single_token(
  outputs: List<Output>,
  policy: PolicyId,
  name: AssetName,
) -> Output {
  when
    find(outputs, fn(output) { quantity_is_one(output.value, policy, name) })
  is {
    Some(out) -> out
    _ -> fail @"no output with that token"
  }
}

/// Find an output with specific address.
/// Fails if no output with that address.
pub fn find_output_with_addr(outputs: List<Output>, addr: Address) -> Output {
  when find(outputs, fn(output) { output.address == addr }) is {
    Some(out) -> out
    _ -> fail @"no output with that address"
  }
}

/// Merge all values from a list of outputs.
pub fn merge_values_output(outputs: List<Output>) -> Value {
  if outputs == [] {
    zero
  } else {
    let head_out = head_list(outputs)
    merge(head_out.value, merge_values_output(tail_list(outputs)))
  }
}
