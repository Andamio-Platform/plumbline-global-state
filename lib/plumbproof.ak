use aiken/builtin.{blake2b_224, blake2b_256}
use cardano/address.{Address, Inline, Script, VerificationKey}
use cardano/assets.{Value, add, from_lovelace}
use cardano/transaction.{
  Datum, InlineDatum, Input, NoDatum, Output, OutputReference,
}
use plumbline/plumb_value.{create_global_tn, create_user_tn}
use plumbline/types/global_state.{GlobalStateDatum}

// ### Address
/// Mock public key address, where payment part is hashed bytearray, no staking 
pub fn mock_pub_key_address(bytearray: ByteArray) -> Address {
  Address(VerificationKey(blake2b_224(bytearray)), None)
}

/// Mock script address, where payment part is hashed bytearray, no staking 
pub fn mock_script_address(bytearray: ByteArray) -> Address {
  Address(Script(blake2b_224(bytearray)), None)
}

// ### Value

// Create value with token and 2 Ada.
pub fn create_min_ada_token_value(
  policy_id: ByteArray,
  token_name: ByteArray,
  am: Int,
) -> Value {
  add(from_lovelace(2_000_000), policy_id, token_name, am)
}

// ### Output
/// Create an output with address, value and datum.
pub fn mock_script_output(
  address: Address,
  value: Value,
  datum: Datum,
) -> Output {
  Output { address, value, datum, reference_script: None }
}

/// Create an output with just address and value.
pub fn mock_pub_key_output(address: Address, value: Value) -> Output {
  mock_script_output(address, value, NoDatum)
}

/// Create an output which has a public key address and a value consisting of a token and 2 Ada.
pub fn mock_pub_key_token_output_by_bytearray(bytearray: ByteArray) -> Output {
  mock_pub_key_output(
    mock_pub_key_address(bytearray),
    create_min_ada_token_value(blake2b_224(bytearray), bytearray, 1),
  )
}

/// Create an output which has a public key address and a global state `u` token (with policy id `global_cs`) + ada.
pub fn output_user_token(alias: ByteArray) -> Output {
  mock_pub_key_output(
    mock_pub_key_address(alias),
    create_min_ada_token_value(global_cs, create_user_tn(alias), 1),
  )
}

// ### OutputReference
/// Creates an output reference where id is hashed and ix is the index.
pub fn mock_utxo_ref(id: ByteArray, ix: Int) -> OutputReference {
  OutputReference { transaction_id: blake2b_256(id), output_index: ix }
}

// ### Input
/// Create an output which has a public key address and a value consisting of a token and 2 Ada.
/// Uses `mock_pub_key_token_output_by_bytearray`.
pub fn mock_input(some: ByteArray) -> Input {
  Input(mock_utxo_ref("0", 0), mock_pub_key_token_output_by_bytearray(some))
}

/// Create an input which has a public key address and a global state user token + ada.
/// Uses `output_user_token`.
pub fn input_user_token(alias: ByteArray) -> Input {
  Input(mock_utxo_ref("5", 5), output_user_token(alias))
}

// ### Global State

/// Just some stake credentials derived by hashing "stake_cred".
pub const stake_cred = Inline(Script(blake2b_224("stake_cred")))

/// A script address where some bytearray is hashed and used used as payment part.
/// Staking part is `stake_cred`.
pub fn script_address_stake_cred(bytearray: ByteArray) -> Address {
  Address(Script(blake2b_224(bytearray)), Some(stake_cred))
}

/// Just a hash of "global_cs".
pub const global_cs = blake2b_224("global_cs")

/// Token name of all local state policy reference tokens.
pub const state_token_name = "LocalStateToken"

/// Address where all `g `global_cs` tokens are locked.
pub const global_state_addr =
  Address(Script("global_state_addr"), Some(stake_cred))

/// An empty `GlobalStateDatum` with a provided user alias.
pub fn create_empty_gs_dat(alias: ByteArray) -> GlobalStateDatum {
  GlobalStateDatum { alias, local_state_data: [] }
}

/// Create a global state output. 
/// address = `global_state_addr`.
/// value = 2 Ada + `g` `global_cs`.
/// datum as provided.
pub fn create_global_output(alias: ByteArray, dat: GlobalStateDatum) -> Output {
  Output {
    address: global_state_addr,
    value: create_min_ada_token_value(global_cs, create_global_tn(alias), 1),
    datum: InlineDatum(dat),
    reference_script: None,
  }
}
