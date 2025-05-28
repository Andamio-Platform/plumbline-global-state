use aiken/crypto.{blake2b_224}
use cardano/address.{Address, Inline, Script}
use cardano/assets.{AssetName, PolicyId, Value, add, from_lovelace}
use cardano/transaction.{InlineDatum, Input, Output}
use mocktail.{mock_pub_key_address, mock_pub_key_output, mock_utxo_ref}
use plumbline.{create_100, create_222}
use plumbline/types/global_state.{GlobalStateDatum}

// general
pub const stake_cred = Inline(Script(blake2b_224("stake_cred")))

// index
pub const index_ref_cs = blake2b_224("index_ref_cs")

pub const index_scripts_tn = "IndexScripts"

// global state
pub const local_state_reference_cs = blake2b_224("local_state_reference_cs")

pub const state_token_name = "LocalStateToken"

pub const local_state_id = blake2b_224("local_state_id")

pub const local_state_cs = blake2b_224("local_state_cs")

pub const init_global_obs_sh = blake2b_224("init_obs_sh")

pub const global_cs = blake2b_224("global_cs")

pub const global_state_addr =
  Address(Script("global_state_addr"), Some(stake_cred))

pub const global_state_addr_v1 =
  Address(Script("global_state_addr_v1"), Some(stake_cred))

pub const local_state_ref_cs = blake2b_224("local_state_ref_cs")

pub const local_state_ref_addr =
  Address(Script(local_state_ref_cs), Some(stake_cred))

pub fn create_min_ada_token_value(policy_id: PolicyId, tn: AssetName) -> Value {
  add(from_lovelace(2_000_000), policy_id, tn, 1)
}

pub fn output_222(alias: ByteArray) -> Output {
  mock_pub_key_output(
    mock_pub_key_address(0, None),
    create_min_ada_token_value(global_cs, create_222(alias)),
  )
}

pub fn input_222(alias: ByteArray) -> Input {
  Input(mock_utxo_ref(5, 5), output_222(alias))
}

pub fn create_empty_gs_dat(alias: ByteArray) -> GlobalStateDatum {
  GlobalStateDatum { alias, local_state_data: [] }
}

pub fn create_global_output(alias: ByteArray, dat: GlobalStateDatum) -> Output {
  Output {
    address: global_state_addr,
    value: create_min_ada_token_value(global_cs, create_100(alias)),
    datum: InlineDatum(dat),
    reference_script: None,
  }
}
