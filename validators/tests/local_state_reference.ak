use aiken/builtin.{blake2b_224, head_list}
use aiken/collection/list.{length, map, push}
use cardano/assets.{from_asset, merge, negate, zero}
use cardano/transaction.{InlineDatum, Input, Output, Transaction, placeholder}
use global/local_state_reference as ls_ref
use mocktail.{mock_pub_key_address, mock_pub_key_output, mock_utxo_ref}
use tests/utils.{
  create_min_ada_token_value, local_state_ref_addr, local_state_ref_cs,
  stake_cred, state_token_name,
}
use types/local_state_reference_data.{LocalStateReferenceData}

// call minting
fn local_state_reference_mint(red: LocalStateReferenceData, tx: Transaction) {
  ls_ref.local_state_reference.mint(
    stake_cred,
    state_token_name,
    red,
    local_state_ref_cs,
    tx,
  )
}

// call spending
fn local_state_reference_spend(dat: ByteArray, tx: Transaction) {
  ls_ref.local_state_reference.spend(
    stake_cred,
    state_token_name,
    Some(dat),
    "",
    mock_utxo_ref(0, 0),
    tx,
  )
}

// create different local state output list differentiateed by reference script
fn create_local_state_reference_output(
  variants: List<ByteArray>,
) -> List<Output> {
  map(
    variants,
    fn(variant) {
      Output {
        address: local_state_ref_addr,
        value: create_min_ada_token_value(local_state_ref_cs, state_token_name),
        datum: InlineDatum(blake2b_224("local_state_id")),
        reference_script: Some(blake2b_224(variant)),
      }
    },
  )
}

// create wallet output with local state id token
fn create_instance_id_output(ls_id: ByteArray) -> Output {
  mock_pub_key_output(
    mock_pub_key_address(0, None),
    create_min_ada_token_value(blake2b_224(ls_id), "local_state_id"),
  )
}

// minting local state reference succeed transaction
fn local_state_reference_mint_mint_succeed_tx(
  variants: List<ByteArray>,
  ls_id: ByteArray,
) {
  Transaction {
    ..placeholder,
    outputs: push(
      create_local_state_reference_output(variants),
      create_instance_id_output(ls_id),
    ),
    mint: from_asset(local_state_ref_cs, state_token_name, length(variants)),
  }
}

// minting local state reference succeed test
test local_state_reference_mint_mint_succeed() {
  let variants = ["1", "2", "3"]
  let local_state_id = "local_state_id"
  local_state_reference_mint(
    LocalStateReferenceData(
      blake2b_224(local_state_id),
      map(variants, fn(variant) { blake2b_224(variant) }),
    ),
    local_state_reference_mint_mint_succeed_tx(variants, local_state_id),
  )
}

// minting local state reference fail test
// missing local state id token
test local_state_reference_mint_mint_fail1_nft() fail {
  let variants = ["1", "2", "3"]
  let local_state_id = "local_state_id"
  local_state_reference_mint(
    LocalStateReferenceData(
      blake2b_224(local_state_id),
      map(variants, fn(variant) { blake2b_224(variant) }),
    ),
    local_state_reference_mint_mint_succeed_tx(variants, "wrong"),
  )
}

// minting local state reference fail test
// local state reference scrits not unique
test local_state_reference_mint_mint_fail2_uniqueness() fail {
  let variants = ["1", "2", "3", "1"]
  let local_state_id = "local_state_id"
  local_state_reference_mint(
    LocalStateReferenceData(
      blake2b_224(local_state_id),
      map(variants, fn(variant) { blake2b_224(variant) }),
    ),
    local_state_reference_mint_mint_succeed_tx(variants, local_state_id),
  )
}

// minting local state reference fail test
// miss match redeemer and actual minted
test local_state_reference_mint_mint_fail3_redeemer() fail {
  let variants = ["1", "2", "3"]
  let local_state_id = "local_state_id"
  local_state_reference_mint(
    LocalStateReferenceData(
      blake2b_224(local_state_id),
      map(["1", "2", "3", "4"], fn(variant) { blake2b_224(variant) }),
    ),
    local_state_reference_mint_mint_succeed_tx(variants, local_state_id),
  )
}

// minting local state reference fail test
// wrong token name minted
test local_state_reference_mint_mint_fail4_wrong_tn() fail {
  let variants = ["1", "2", "3"]
  let local_state_id = "local_state_id"
  let tx = local_state_reference_mint_mint_succeed_tx(variants, local_state_id)
  local_state_reference_mint(
    LocalStateReferenceData(
      blake2b_224(local_state_id),
      map(["1", "2", "3", "4"], fn(variant) { blake2b_224(variant) }),
    ),
    Transaction {
      ..tx,
      mint: merge(tx.mint, from_asset(local_state_ref_cs, "wrong", 1)),
    },
  )
}

// burning local state reference succeed transaction
fn local_state_reference_spend_burn_succeed_tx(variant: ByteArray) {
  Transaction {
    ..placeholder,
    inputs: [
      Input(
        mock_utxo_ref(0, 0),
        head_list(create_local_state_reference_output([variant])),
      ),
    ],
    outputs: [create_instance_id_output("local_state_id")],
    mint: from_asset(local_state_ref_cs, state_token_name, -1),
  }
}

// spending and burning local state reference succeed transaction
test local_state_reference_burn_succeed() {
  let tx = local_state_reference_spend_burn_succeed_tx("1")
  local_state_reference_spend(blake2b_224("local_state_id"), tx) && local_state_reference_mint(
    LocalStateReferenceData("", [""]),
    tx,
  )
}

// just spending local state reference succeed transaction
test local_state_reference_burn_spend_succeed() {
  let tx =
    Transaction {
      ..local_state_reference_spend_burn_succeed_tx("1"),
      mint: zero,
    }
  local_state_reference_spend(blake2b_224("local_state_id"), tx)
}

// just burning local state reference succeed transaction
test local_state_reference_burn_mint_succeed() {
  let tx =
    Transaction {
      ..local_state_reference_spend_burn_succeed_tx("1"),
      inputs: [],
      outputs: [],
    }
  local_state_reference_mint(LocalStateReferenceData("", [""]), tx)
}

// just burning local state reference fail transaction
// positive minting value
test local_state_reference_burn_mint_negate() fail {
  let tx =
    Transaction {
      ..local_state_reference_spend_burn_succeed_tx("1"),
      inputs: [],
      outputs: [],
    }
  local_state_reference_mint(
    LocalStateReferenceData("", [""]),
    Transaction { ..tx, mint: negate(tx.mint) },
  )
}

// spending and burning local state reference fail transaction
// missing local state id token
test local_state_reference_burn_fail1_nft() fail {
  let tx = local_state_reference_spend_burn_succeed_tx("1")
  local_state_reference_spend(blake2b_224("local_state_id1"), tx) && local_state_reference_mint(
    LocalStateReferenceData("", [""]),
    tx,
  )
}

// spending and burning local state reference fail transaction
// token still in output
test local_state_reference_burn_fail2_output() fail {
  let tx =
    Transaction {
      ..local_state_reference_spend_burn_succeed_tx("1"),
      outputs: create_local_state_reference_output(["2"]),
    }
  local_state_reference_spend(blake2b_224("local_state_id1"), tx) && local_state_reference_mint(
    LocalStateReferenceData("", [""]),
    tx,
  )
}
