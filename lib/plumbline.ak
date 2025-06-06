//// Plumbline provides on chain utility functions. Specifically used for development of the andamio protocol.

use plumbline/plumb_address
use plumbline/plumb_global_state
use plumbline/plumb_input
use plumbline/plumb_output
use plumbline/plumb_value

// Address
/// See: [`plumb_address`](./plumbline/plumb_address.html)
pub const get_script_hash_from_address =
  plumb_address.get_script_hash_from_address

// Input
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

// Global State
/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const hash_local_state = plumb_global_state.hash_local_state

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const at_validate = plumb_global_state.at_validate

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const create_new_gs_dat_mint = plumb_global_state.create_new_gs_dat_mint

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const create_new_gs_dat_burn = plumb_global_state.create_new_gs_dat_burn

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const create_new_gs_dat_delete = plumb_global_state.create_new_gs_dat_delete

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const validate_global_state_mint_ls =
  plumb_global_state.validate_global_state_mint_ls

/// See: [`plumb_global_state`](./plumbline/plumb_global_state.html)
pub const validate_global_state_burn_ls =
  plumb_global_state.validate_global_state_burn_ls
