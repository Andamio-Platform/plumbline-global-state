use aiken/builtin.{blake2b_224, head_list, tail_list}
use aiken/collection/list.{find}
use cardano/assets.{AssetName, PolicyId, Value, add, from_lovelace, merge, zero}
use cardano/transaction.{Input, Output}
use mocktail.{mock_pub_key_address, mock_pub_key_output, mock_utxo_ref}
use plumbline/plumb_output.{
  find_output_with_single_token, mock_key_token_output_simple, mock_output,
  policy_id_present_in_output,
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

// ### testing
// Create input which has min ada value and token.
pub fn mock_input(some: ByteArray) -> Input {
  Input(mock_utxo_ref(0, 0), mock_output(some))
}

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
  let outputs = [mock_output("a"), mock_output("c"), mock_output("d")]
  in_out_token_address_same(inputs, outputs, blake2b_224("a"), "a")
}

test in_out_token_address_same_fail_() fail {
  let inputs = [mock_input("a"), mock_input("c"), mock_input("d")]
  let outputs =
    [
      Output { ..mock_output("a"), address: mock_pub_key_address(1, None) },
      mock_output("c"),
      mock_output("d"),
    ]
  in_out_token_address_same(inputs, outputs, blake2b_224("a"), "a")?
}

test merge_value_inputs_succeed_ada() {
  let inputs =
    [
      Input(mock_utxo_ref(0, 0), mock_key_token_output_simple(5)),
      Input(mock_utxo_ref(0, 0), mock_key_token_output_simple(10)),
      Input(mock_utxo_ref(0, 0), mock_key_token_output_simple(20)),
    ]
  merge_value_inputs(inputs) == from_lovelace(35)
}

test merge_value_inputs_succeed_native() {
  let inputs =
    [
      Input(
        mock_utxo_ref(0, 0),
        mock_pub_key_output(
          mock_pub_key_address(0, None),
          add(from_lovelace(5), "cs1", "tn1", 10),
        ),
      ),
      Input(
        mock_utxo_ref(0, 0),
        mock_pub_key_output(
          mock_pub_key_address(1, None),
          add(from_lovelace(10), "cs1", "tn1", 112),
        ),
      ),
      Input(mock_utxo_ref(0, 0), mock_key_token_output_simple(20)),
    ]
  merge_value_inputs(inputs) == add(from_lovelace(35), "cs1", "tn1", 122)
}
