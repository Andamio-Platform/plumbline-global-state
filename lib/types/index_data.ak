//// @hidden

use cardano/address.{Address}
use plumbline/plumb_value.{FlatValue}

// Type present at index referene utxo.

pub type IndexData {
  /// Protocol treasury where minting global state token and staking of validators go.
  treasury_address: Address,
  /// Protocol treasury datum as builtin data. `Datum`
  treasury_datum: Data,
  /// Fee to mint a global state token.
  mint_access_token_value: List<FlatValue>,
  /// List of observers to initialise or move a global state.
  init_gs_obs_sh_list: List<Data>,
}
