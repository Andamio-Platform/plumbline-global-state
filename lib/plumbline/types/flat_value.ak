use cardano/assets.{AssetName, PolicyId}

/// Flatten Value to use in datum/redeemer.
pub type FlatValue {
  policy_id: PolicyId,
  token_name: AssetName,
  amount: Int,
}
