use cardano/address.{Address, Script, VerificationKey}

/// Get the script hash of an address. Address must have a script payment part. 
/// Useful if a script is for spending and minting.
/// ```aiken
/// let address = Address(Script("7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"), None)
/// get_script_hash_from_address(addres) == "7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"
///```
pub fn get_script_hash_from_address(address: Address) -> ByteArray {
  expect Script(script_hash) = address.payment_credential
  script_hash
}

/// Get the public key hash of an address. Address must have a public key payment part. 
/// Useful to get public key hash of an address.
/// ```aiken
/// let address = Address(VerificationKey("7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"), None)
/// get_pub_key_hash_from_address(addres) == "7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"
///```
pub fn get_pub_key_hash_from_address(address: Address) -> ByteArray {
  expect VerificationKey(pub_key_hash) = address.payment_credential
  pub_key_hash
}
