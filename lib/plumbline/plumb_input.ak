use aiken/collection/list.{find}
use cardano/assets.{AssetName, PolicyId, Value, merge, zero}
use cardano/transaction.{Input, Output, OutputReference}
use plumbline/plumb_output.{find_output_with_token, policy_id_present_in_output}
use plumbline/plumb_value.{token_present_in_value_lazy}

/// Find an input which has a specific output reference.
/// Fails if no input found.
pub fn find_input(
  inputs: List<Input>,
  output_reference: OutputReference,
) -> Input {
  when
    find(inputs, fn(input) { input.output_reference == output_reference })
  is {
    Some(input) -> input
    None -> fail @"no input with that output_reference"
  }
}

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

/// Find an input which has a token attached.
/// Fails if no utxo with that token attached.
pub fn find_input_with_token(
  inputs: List<Input>,
  policy: PolicyId,
  name: AssetName,
) -> Input {
  when
    find(
      inputs,
      fn(input) {
        token_present_in_value_lazy(input.output.value, policy, name)
      },
    )
  is {
    Some(out) -> out
    _ -> fail @"no input with that token"
  }
}

/// Checks if a token has the same input and output address. 
/// Useful to check if a user token `u` token is send back to the sender.
/// Uses `find_input_with_token` under the hood.
pub fn in_out_token_address_same(
  inputs: List<Input>,
  outputs: List<Output>,
  cs: PolicyId,
  tn: AssetName,
) -> Bool {
  (find_output_with_token(outputs, cs, tn).address == find_input_with_token(
    inputs,
    cs,
    tn,
  ).output.address)?
}

/// Uses `find_input_with_single_token` under the hood therefore must be a token with quantity one.
/// Merge all values from a list of inputs.
pub fn merge_value_inputs(inputs: List<Input>) -> Value {
  when inputs is {
    [x, ..xs] -> merge(x.output.value, merge_value_inputs(xs))
    [] -> zero
  }
}
