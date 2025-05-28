use aiken/builtin.{blake2b_224}
use cardano/address.{Address, Script, VerificationKey}
use mocktail.{mock_script_address, mock_script_hash}

/// Get the script hash of an address. Address must have a script payment part. 
///Useful if a script is for spending and minting.
///```aiken
///let address = Address(Script("7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"), None)
///get_script_hash_from_address(addres) == "7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"
///```
pub fn get_script_hash_from_address(address: Address) -> ByteArray {
  expect Script(script_hash) = address.payment_credential
  script_hash
}

// ### testing
// Mock public key address, where payment part is hashed bytearray, no staking 
pub fn mock_pub_key_address(bytearray: ByteArray) -> Address {
  Address(VerificationKey(blake2b_224(bytearray)), None)
}

// ### test get_script_hash_from_address
test get_script_hash_from_address_succeed() {
  (get_script_hash_from_address(mock_script_address(0, None)) == mock_script_hash(
    0,
  ))?
}

test get_script_hash_from_address_fail() fail {
  (get_script_hash_from_address(mock_pub_key_address("0")) == blake2b_224("0"))?
}
