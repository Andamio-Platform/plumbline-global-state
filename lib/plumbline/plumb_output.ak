use aiken/builtin.{blake2b_224, head_list, tail_list}
use aiken/collection/list.{any, find}
use cardano/address.{Address}
use cardano/assets.{
  AssetName, PolicyId, Value, add, from_lovelace, merge, policies, zero,
}
use cardano/transaction.{Output}
use mocktail as mocktail
use plumbline/plumb_address.{mock_pub_key_address}
use plumbline/plumb_value.{create_min_ada_token_value, quantity_is_one}

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

// ### testing
// Create output which has min ada value and token.
pub fn mock_output(bytearray: ByteArray) -> Output {
  mocktail.mock_pub_key_output(
    mock_pub_key_address(bytearray),
    create_min_ada_token_value(bytearray, 1),
  )
}

test cs_present_in_outputs_test_true() {
  let outs = [mock_output("cs0"), mock_output("cs1")]
  policy_id_present_in_outputs(outs, blake2b_224("cs1"))
}

test cs_present_in_outputs_test_fail() fail {
  let outs = [mock_output("cs1")]
  policy_id_present_in_outputs(outs, blake2b_224("cs2"))
}

test find_output_with_test_true() {
  let outs = [mock_output("cs1"), mock_output("cs2")]
  find_output_with_single_token(outs, blake2b_224("cs2"), "cs2") == mock_output(
    "cs2",
  )
}

test find_output_with_test_fail() fail {
  let outs = [mock_output("cs1"), mock_output("cs2")]
  find_output_with_single_token(outs, blake2b_224("cs3"), "cs3") == mock_output(
    "cs2",
  )
}

/// Create output with just ada.
pub fn mock_key_token_output_simple(int: Int) -> Output {
  mocktail.mock_pub_key_output(
    mocktail.mock_pub_key_address(int, None),
    from_lovelace(int),
  )
}

test find_output_with_addr_succeed() {
  let outputs = [mock_output("0"), mock_output("1"), mock_output("2")]
  find_output_with_addr(outputs, mock_pub_key_address("1")) == mock_output("1")
}

test find_output_with_addr_fail1() fail {
  let outputs = [mock_output("0"), mock_output("1"), mock_output("2")]
  find_output_with_addr(outputs, mock_pub_key_address("3")) == mock_output("2")
}

test merge_values_output_succeed_ada() {
  let outputs =
    [
      mocktail.mock_pub_key_output(mock_pub_key_address("0"), from_lovelace(5)),
      mocktail.mock_pub_key_output(mock_pub_key_address("1"), from_lovelace(10)),
      mocktail.mock_pub_key_output(mock_pub_key_address("2"), from_lovelace(20)),
    ]
  merge_values_output(outputs) == from_lovelace(35)
}

test merge_values_output_succeed_native() {
  let outputs =
    [
      mocktail.mock_pub_key_output(
        mock_pub_key_address("0"),
        add(from_lovelace(5), "cs1", "tn1", 10),
      ),
      mocktail.mock_pub_key_output(
        mock_pub_key_address("1"),
        add(from_lovelace(10), "cs1", "tn1", 112),
      ),
      mocktail.mock_pub_key_output(mock_pub_key_address("2"), from_lovelace(20)),
    ]
  merge_values_output(outputs) == add(from_lovelace(35), "cs1", "tn1", 122)
}
