use aiken/builtin.{unconstr_fields, unconstr_index}
use aiken/collection/pairs.{get_first}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{Input, Redeemer, ScriptPurpose, Spend}
use plumbline/plumb_input.{find_input_with_single_token}

/// Get the redeemer used for an interaction with the global state.
/// Return type Data to directly downcast it to the needed GlobalStateAction contructor.
pub fn get_single_token_spend_redeemer(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  policy_id: PolicyId,
  tn: AssetName,
) -> Data {
  expect Some(global_state_redeemer) =
    get_first(
      redeemers,
      Spend(
        find_input_with_single_token(inputs, policy_id, tn).output_reference,
      ),
    )
  global_state_redeemer
}

/// Get the redeemer fields used for an interaction with the global state.
/// Return type List<Data> cheaper than downcasting the whole contructor.
/// constr = either 0 for minting or 1 for burning a local state.
/// Especially true if not each field needed.
pub fn get_single_token_spend_redeemer_by_constructor(
  inputs: List<Input>,
  redeemers: Pairs<ScriptPurpose, Redeemer>,
  constr: Int,
  global_cs: PolicyId,
  alias: AssetName,
) -> List<Data> {
  let red = get_single_token_spend_redeemer(inputs, redeemers, global_cs, alias)

  if unconstr_index(red) == constr {
    unconstr_fields(red)
  } else {
    fail @"redemeemer: wrong contructor"
  }
}
