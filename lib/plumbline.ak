//// Plumbline provides on chain utility functions. Specifically used for development of the andamio protocol.

use plumbline/plumb_address
use plumbline/plumb_bytearray
use plumbline/plumb_global_state
use plumbline/plumb_input
use plumbline/plumb_output
use plumbline/plumb_redeemers
use plumbline/plumb_value

// Address
/// See: [`plumb_address`](./plumbline/plumb_address.html)
pub const get_script_hash_from_address =
  plumb_address.get_script_hash_from_address

/// See: [`plumb_address`](./plumbline/plumb_address.html)
pub const get_pub_key_hash_from_address =
  plumb_address.get_pub_key_hash_from_address

// ByteArray
/// See: [`plumb_bytearray`](./plumbline/plumb_bytearray.html)
pub const merge_list = plumb_bytearray.merge_list

/// See: [`plumb_bytearray`](./plumbline/plumb_bytearray.html)
pub const append_list = plumb_bytearray.append_list

/// See: [`plumb_bytearray`](./plumbline/plumb_bytearray.html)
pub const serialise_hash_list = plumb_bytearray.serialise_hash_list

// Global State
/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const hash_local_state = plumb_global_state.hash_local_state

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const at_validate = plumb_global_state.at_validate

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const get_ls_id_gs_red = plumb_global_state.get_ls_id_gs_red

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const get_ls_state_index_gs_red =
  plumb_global_state.get_ls_state_index_gs_red

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const get_ls_state_gs_red = plumb_global_state.get_ls_state_gs_red

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const get_ls_cs_gs_red = plumb_global_state.get_ls_cs_gs_red

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const get_ls_new_state_gs_red = plumb_global_state.get_ls_new_state_gs_red

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const validate_global_state_mint_ls_no_prereqs =
  plumb_global_state.validate_global_state_mint_ls_no_prereqs

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const get_local_state_data = plumb_global_state.get_local_state_data

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const validate_global_state_mint_ls_with_prereqs =
  plumb_global_state.validate_global_state_mint_ls_with_prereqs

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const validate_global_state_burn_ls =
  plumb_global_state.validate_global_state_burn_ls

// Input
/// See: [`plumb_input`](./plumbline/plumb_input.html)
pub const find_input = plumb_input.find_input

/// See: [`plumb_input`](./plumbline/plumb_input.html)
pub const find_input_with_policy = plumb_input.find_input_with_policy

/// See: [`plumb_input`](./plumbline/plumb_input.html)
pub const find_input_with_single_token =
  plumb_input.find_input_with_single_token

/// See: [`plumb_input`](./plumbline/plumb_input.html)
pub const in_out_token_address_same = plumb_input.in_out_token_address_same

/// See: [`plumb_input`](./plumbline/plumb_input.html)
pub const merge_value_inputs = plumb_input.merge_value_inputs

// Output
/// See: [`plumb_output`](./plumbline/plumb_output.html)
pub const policy_id_present_in_output = plumb_output.policy_id_present_in_output

/// See: [`plumb_output`](./plumbline/plumb_output.html)
pub const policy_id_present_in_outputs =
  plumb_output.policy_id_present_in_outputs

/// See: [`plumb_output`](./plumbline/plumb_output.html)
pub const find_output_with_single_token =
  plumb_output.find_output_with_single_token

/// See: [`plumb_output`](./plumbline/plumb_output.html)
pub const find_output_with_addr = plumb_output.find_output_with_addr

/// See: [`plumb_output`](./plumbline/plumb_output.html)
pub const merge_values_output = plumb_output.merge_values_output

// Redeemers
/// See: [`plumb_redeemers`](./plumbline/plumb_redeemers.html)
pub const get_single_token_spend_redeemer =
  plumb_redeemers.get_single_token_spend_redeemer

/// See: [`plumb_redeemers`](./plumbline/plumb_redeemers.html)
pub const get_single_token_spend_redeemer_by_constructor =
  plumb_redeemers.get_single_token_spend_redeemer_by_constructor

// Value
/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const single_name_of_policy_id = plumb_value.single_name_of_policy_id

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const two_token_value = plumb_value.two_token_value

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const create_222 = plumb_value.create_222

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const create_100 = plumb_value.create_100

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const quantity_is_one = plumb_value.quantity_is_one

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const geq_value = plumb_value.geq_value

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const substract_value = plumb_value.substract_value

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const flat_val_paid = plumb_value.flat_val_paid

/// See: [`plumb_value`](./plumbline/plumb_value.html)
pub const flat_val_to_value = plumb_value.flat_val_to_value
