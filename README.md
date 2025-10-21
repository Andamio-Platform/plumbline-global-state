# plumbline-global-state

## global-state
A Cardano validator written in Aiken for managing user state data on the blockchain. This validator provides a structured system for users to maintain multiple local states within a global state container. It utilizes reference NFTs where `u` tokens are used to prove ownership of a global state attached to a `g` token.

### Overview
The Global State Validator allows users to:

- Create and manage multiple local state entries
- Update existing state data
- Delete state entries permanently
- Migrate to new validator versions

Each user has a global state that acts as a container for their individual local states, providing a clean separation of concerns and efficient state management.

### Datum
```aiken
/// Global state of a user always attached to the global state token.
pub type GlobalStateDatum {
  /// Alias to identify user, no prefix.
  alias: ByteArray,
  /// Each pair represents one local state. 
  /// `PolicyId` to identify local state.
  /// `ByteArray` data + local state token as blake2b_256 hash
  local_state_data: Pairs<PolicyId, ByteArray>,
}
```

### Operations
#### 1. Mint Local State
Creates a new local state entry within the user's global state or re-mints an earlier used local state.

**Requirements:**

- Local state tokens must be minted (positive quantity)
- Local state is registered
- State ID must not already exist or must not be minted

**Redeemer:**
```aiken
  MintLocalState {
    /// identifier of a local state (nft policy id)
    local_state_id: PolicyId,
    /// index where to find local state in global state pairs
    local_state_index: Int,
    /// hashed data from local state
    local_state_data_hash: ByteArray,
    /// policy id of the state token in a local state (empty if not minted)
    local_state_cs: PolicyId,
  }
```

#### 2. Burn Local State
Updates an existing local state entry with new data.

**Requirements:**

- Local state tokens must be burned (negative quantity)
- Existing local state must be validated
- New data hash must be provided

**Redeemer:**
```aiken
  /// Burn a local state token and change data.
  BurnLocalState {
    /// identifier of a local state (nft policy id)
    local_state_id: PolicyId,
    /// index where to find local state in global state pairs
    local_state_index: Int,
    /// hashed data from local state
    local_state_data_hash: ByteArray,
    /// policy id of the state token in a local state (empty if not minted)
    local_state_cs: PolicyId,
    /// new local state data hash
    new_data_hash: ByteArray,
  }
```

#### 3. Delete State
Permanently removes a local state entry from the global state.

**Requirements:**

- State must exist and be validated
- State not minted
- No token minting/burning required

**Redeemer:**
```aiken
  /// Delete a local state from global state. Not possible if minted.
  DeleteState {
    /// identifier of a local state (recommended: nft policy id)
    local_state_id: PolicyId,
    /// hashed data from local state
    local_state_data_hash: ByteArray,
    /// index where to find local state in global state pairs
    local_state_index: Int,
  }
```

#### 4. Move State
Migrates the global state to a new validator version.

**Requirements:**

- Zero withdraw observer must be present
- New state observer must be authorized
- Token consistency must be maintained

**Redeemer:**
```aiken
  /// Move global state to a new validator.
  MoveState {
    /// 0-withdraw script from index ref observing
    new_state_obs: ScriptHash,
  }
```

## init-global-state-obs
A Cardano validator written in Aiken that serves as a migration and initialization validator for a Global State. This observer uses zero withdrawal mechanics to validate critical state transitions and initialization.

### Overview

The Zero Withdrawal Observer handles two primary functions:

- New User Initialization: Creates empty global states for first-time users
- V1 to V2 Migration: Upgrades existing users from Global State V1 to V2

This validator acts as a "watcher" that ensures proper state transitions.

### Operations
#### 1. New User Initialization
Creates a fresh global state for users joining the system.

**Flow:**
```User mints Token `g` → Zero withdrawal triggered → Empty global state created```

**Requirements:**

- Global state token (Token `g`) must be minted
- Output must go to global state address
- Datum must contain empty local state data

**Redeemer:**
```
// token name without prefix
alias: ByteArray
```

#### 2. V1 to V2 Migration
Upgrades existing V1 datum to the new V2 datum type.

**Flow:**
```V1 user initiates migration → Zero withdrawal triggered → Data converted to V2 format```

**Requirements:**

- No token minting (Token `g` from global state v1)
- All local states must be in unminted state
- V1 input must be found with existing token

**Redeemer:**
```
// token name without prefix
alias: ByteArray
```

**DataMigration:**
```aiken
pub type LocalStateInformationV1 {
  local_state_id: PolicyId,
  local_state_data: List<ByteArray>,
  minted: Bool,
}

pub type GlobalStateDatumV1 {
  global_cs: PolicyId,
  user_name: ByteArray,
  local_state_infos: List<LocalStateInformationV1>,
  user_info: Data,
}
```
- v1 currently attached to Token `g` at global state v1 validator
```
Pair(local_state_id, blake2b_256(serialise_data(local_state_data, "")))
```
- if minted == False, serialize and hash local_state_data and make it a pair
```
/// Global state of a user always attached to the global state token.
pub type GlobalStateDatum {
  /// Alias to identify user, no prefix.
  alias: ByteArray,
  /// Each pair represents one local state. 
  /// `PolicyId` to identify local state.
  /// `ByteArray` data + local state token as blake2b_256 hash
  local_state_data: Pairs<PolicyId, ByteArray>,
}
```
- new global state datum: same data, different representation

## local-state-registration
A Cardano validator written in Aiken that manages local state reference scripts for the Global State system. This validator creates and manages reference UTXOs that store local state scripts, enabling efficient discovery of local states.

### Overview
The Local State Registration Validator provides:

- Storage for local state reference scripts
- Token-based identification of local states
- Validation of reference script creation and removal
- Integration with the Global State

Each local state registration token represents a specific local state, identified by a policy ID in the datum, making it easy to locate and reference the appropriate scripts.

### Datum
```aiken
local_state_id: ByteArray
```

### Operations
#### 1. Mint Local State References
Creates new local state registration tokens and stores their scripts.

**Requirements:**

- Must provide list of LocalStateRegistrationData
- Each reference must have unique local state ID
- Outputs must contain reference scripts
- Local state tokens must be present in outputs

**Redeemer:**
```aiken
pub type LocalStateRegistrationData {
  /// identifier of a local state (nft policy id) 
  ls_id: ByteArray,
  /// local state token script hash
  ls_reference_script_hash: ScriptHash,
}

redeemer: [LocalStateRegistrationData]
```

## plumbline
Aiken utility library providing different functions. Among other things, utilities to interact and verify global state actions.

Documentation can be built with:
```sh
aiken docs
```

## Building

```sh
aiken build
```

## Testing

```sh
aiken check
```

Tests can be found in `validators/tests/`, `lib/plumbline/tests.ak` or `validators/example/tests.ak`
To run only tests matching the string `global_state`, do:

```sh
aiken check -m global_state
```