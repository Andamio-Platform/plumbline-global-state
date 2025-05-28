use aiken/builtin.{head_list, tail_list}
use aiken/collection/list.{find}
use cardano/assets.{AssetName, PolicyId, Value, merge, zero}
use cardano/transaction.{Input, Output}
use plumbline/plumb_output.{
  find_output_with_single_token, policy_id_present_in_output,
}
use plumbline/plumb_value.{quantity_is_one}

/// Find an input which has a specific policy id in his value.
/// Fails if no input found.
pub fn find_input_with_policy(inputs: List<Input>, policy_id: PolicyId) -> Input {
  when
    find(
      inputs,
      fn(input) { policy_id_present_in_output(input.output, policy_id) },
    )
  is {
    Some(input) -> input
    _ -> fail @"no input with that policy id"
  }
}

/// Find an input which has a token with quantity one attached.
/// Fails if quantity > 1 or no utxo with that token attached.
pub fn find_input_with_single_token(
  inputs: List<Input>,
  policy: PolicyId,
  name: AssetName,
) -> Input {
  when
    find(
      inputs,
      fn(input) { quantity_is_one(input.output.value, policy, name) },
    )
  is {
    Some(out) -> out
    _ -> fail @"no input with that token"
  }
}

/// Checks if a token has the same input and output address. 
/// Useful to check if a CIP68 222 token is send back to the sender.
/// Uses `find_input_with_single_token` under the hood therefore must be a token with quantity one.
pub fn in_out_token_address_same(
  inputs: List<Input>,
  outputs: List<Output>,
  cs: PolicyId,
  tn: AssetName,
) -> Bool {
  (find_output_with_single_token(outputs, cs, tn).address == find_input_with_single_token(
    inputs,
    cs,
    tn,
  ).output.address)?
}

/// Merge all values from a list of inputs.
pub fn merge_value_inputs(inputs: List<Input>) -> Value {
  if inputs == [] {
    zero
  } else {
    let head_out = head_list(inputs)
    merge(head_out.output.value, merge_value_inputs(tail_list(inputs)))
  }
}
