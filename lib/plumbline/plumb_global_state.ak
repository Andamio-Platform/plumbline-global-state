use aiken/builtin.{blake2b_256, fst_pair, snd_pair}
use aiken/collection/list
use aiken/fuzz
use aiken/primitive/bytearray
use cardano/assets.{PolicyId}
use plumbline/types/global_state.{GlobalStateDatum, LocalStateInformation}

/// Returns a BLAKE2b-256 hash of the local state by combining the state data hash
/// and the local state token policy ID. Useful for uniquely identifying a specific contract state.
/// If no local state minted, ls_cs is an empty bytestring.
pub fn hash_local_state(
  local_state_data_hash: ByteArray,
  ls_cs: PolicyId,
) -> ByteArray {
  blake2b_256(bytearray.concat(local_state_data_hash, ls_cs))
}

/// Validates that the pair at the given index matches the expected local state id and data derived by `hash_local_state`.
/// Return pairs without validated pair.
pub fn at_validate(
  self: Pairs<ByteArray, ByteArray>,
  new: Pairs<ByteArray, ByteArray>,
  id: PolicyId,
  data: ByteArray,
  index: Int,
) -> Pairs<ByteArray, ByteArray> {
  when self is {
    [] -> fail
    [x, ..xs] ->
      if index == 0 {
        if id == fst_pair(x) {
          if data == snd_pair(x) {
            list.concat(new, xs)
          } else {
            fail
          }
        } else {
          fail
        }
      } else {
        at_validate(xs, list.push(new, x), id, data, index - 1)
      }
  }
}

/// Create a new global state datum with local state token minted. 
pub fn create_new_gs_dat_mint(
  gs_dat: GlobalStateDatum,
  ls_info: LocalStateInformation,
) -> GlobalStateDatum {
  GlobalStateDatum {
    ..gs_dat,
    local_state_data: if ls_info.local_state_index > -1 {
      list.push(
        at_validate(
          gs_dat.local_state_data,
          [],
          ls_info.local_state_id,
          hash_local_state(ls_info.local_state_data_hash, ""),
          ls_info.local_state_index,
        ),
        Pair(
          ls_info.local_state_id,
          hash_local_state(
            ls_info.local_state_data_hash,
            ls_info.local_state_cs,
          ),
        ),
      )
    } else {
      list.push(
        gs_dat.local_state_data,
        Pair(
          ls_info.local_state_id,
          hash_local_state("", ls_info.local_state_cs),
        ),
      )
    },
  }
}

/// Updates global state datum with new data hash for a local state. 
pub fn create_new_gs_dat_burn(
  gs_dat: GlobalStateDatum,
  ls_info: LocalStateInformation,
  new_data: ByteArray,
) -> GlobalStateDatum {
  GlobalStateDatum {
    ..gs_dat,
    local_state_data: list.push(
      at_validate(
        gs_dat.local_state_data,
        [],
        ls_info.local_state_id,
        hash_local_state(ls_info.local_state_data_hash, ls_info.local_state_cs),
        ls_info.local_state_index,
      ),
      Pair(ls_info.local_state_id, hash_local_state(new_data, "")),
    ),
  }
}

/// Deletes local state if not minted from global state datum.
pub fn create_new_gs_dat_delete(
  gs_dat: GlobalStateDatum,
  policy_id: PolicyId,
  data_hash: ByteArray,
  index: Int,
) -> GlobalStateDatum {
  GlobalStateDatum {
    ..gs_dat,
    local_state_data: at_validate(
      gs_dat.local_state_data,
      [],
      policy_id,
      hash_local_state(data_hash, ""),
      index,
    ),
  }
}

// ### bench and testing 
fn create_pair_ls_minted() -> Fuzzer<(ByteArray, ByteArray, ByteArray)> {
  let key <- fuzz.and_then(fuzz.bytearray_fixed(28))
  let ls_data <- fuzz.and_then(fuzz.bytearray_fixed(32))
  let ls_cs <- fuzz.and_then(fuzz.bytearray_fixed(28))
  fuzz.constant((key, ls_data, ls_cs))
}

fn get_list_len(int: Int) -> Int {
  int + 30
}

fn create_sort_my_list(
  self: Fuzzer<List<(ByteArray, ByteArray, ByteArray)>>,
) -> Fuzzer<List<(ByteArray, ByteArray, ByteArray)>> {
  let list <- fuzz.and_then(self)
  fuzz.constant(
    list.sort(list, fn((a, _, _), (a1, _, _)) { bytearray.compare(a, a1) }),
  )
}

fn create_pair_ls_not_minted() -> Fuzzer<(ByteArray, ByteArray, ByteArray)> {
  let key <- fuzz.and_then(fuzz.bytearray_fixed(28))
  let ls_data <- fuzz.and_then(fuzz.bytearray_fixed(32))
  fuzz.constant((key, ls_data, ""))
}

fn pick_pairs_ls_not_minted(
  int: Int,
) -> Fuzzer<
  (Pairs<ByteArray, ByteArray>, (Int, (ByteArray, ByteArray, ByteArray))),
> {
  let list <-
    fuzz.and_then(
      create_sort_my_list(
        fuzz.list_between(
          create_pair_ls_not_minted(),
          get_list_len(int),
          get_list_len(int),
        ),
      ),
    )
  let elem <- fuzz.and_then(fuzz.pick(list))
  fuzz.constant(
    (
      list.map(
        list,
        fn((key, data, cs)) { Pair(key, hash_local_state(data, cs)) },
      ),
      elem,
    ),
  )
}

fn create_ls_not_minted_index(
  int: Int,
) -> Fuzzer<(GlobalStateDatum, LocalStateInformation)> {
  let (gs, (index, (key, data, cs))) <-
    fuzz.and_then(pick_pairs_ls_not_minted(int))
  fuzz.both(
    fuzz.constant(GlobalStateDatum("", gs)),
    fuzz.constant(
      LocalStateInformation {
        local_state_id: key,
        local_state_index: index,
        local_state_data_hash: data,
        local_state_cs: cs,
      },
    ),
  )
}

fn pick_pairs_ls_minted(
  int: Int,
) -> Fuzzer<
  (Pairs<ByteArray, ByteArray>, (Int, (ByteArray, ByteArray, ByteArray))),
> {
  let list <-
    fuzz.and_then(
      create_sort_my_list(
        fuzz.list_between(
          create_pair_ls_minted(),
          get_list_len(int),
          get_list_len(int),
        ),
      ),
    )
  let elem <- fuzz.and_then(fuzz.pick(list))
  fuzz.constant(
    (
      list.sort(
        list.map(
          list,
          fn((key, data, cs)) { Pair(key, hash_local_state(data, cs)) },
        ),
        fn(Pair(a, _), Pair(a1, _)) { bytearray.compare(a, a1) },
      ),
      elem,
    ),
  )
}

fn pick_pairs_ls_not_minted_maybe_present(
  int: Int,
) -> Fuzzer<
  (Pairs<ByteArray, ByteArray>, (Int, (ByteArray, ByteArray, ByteArray))),
> {
  let list <-
    fuzz.and_then(
      create_sort_my_list(
        fuzz.list_between(
          create_pair_ls_not_minted(),
          get_list_len(int),
          get_list_len(int),
        ),
      ),
    )
  let is_present <- fuzz.and_then(fuzz.bool())
  let elem <-
    fuzz.and_then(
      if is_present {
        let elem <- fuzz.and_then(fuzz.pick(list))
        fuzz.constant(elem)
      } else {
        let key <- fuzz.and_then(fuzz.bytearray_fixed(28))
        let cs <- fuzz.and_then(fuzz.bytearray_fixed(28))
        fuzz.constant((-1, (key, "", cs)))
      },
    )
  fuzz.constant(
    (
      list.sort(
        list.map(
          list,
          fn((key, data, cs)) { Pair(key, hash_local_state(data, cs)) },
        ),
        fn(Pair(a, _), Pair(a1, _)) { bytearray.compare(a, a1) },
      ),
      elem,
    ),
  )
}

fn create_ls_minted_maybe_present_index(
  int: Int,
) -> Fuzzer<(GlobalStateDatum, LocalStateInformation)> {
  let (gs, (index, (key, data, cs))) <-
    fuzz.and_then(pick_pairs_ls_not_minted_maybe_present(int))
  fuzz.both(
    fuzz.constant(GlobalStateDatum("", gs)),
    fuzz.constant(
      LocalStateInformation {
        local_state_id: key,
        local_state_index: index,
        local_state_data_hash: data,
        local_state_cs: cs,
      },
    ),
  )
}

bench bench_gs_dat_mint((gs, ls) via create_ls_minted_maybe_present_index) {
  create_new_gs_dat_mint(gs, ls)
}

fn create_ls_minted_index(
  int: Int,
) -> Fuzzer<(GlobalStateDatum, LocalStateInformation)> {
  let (gs, (index, (key, data, cs))) <- fuzz.and_then(pick_pairs_ls_minted(int))
  fuzz.both(
    fuzz.constant(GlobalStateDatum("", gs)),
    fuzz.constant(
      LocalStateInformation {
        local_state_id: key,
        local_state_index: index,
        local_state_data_hash: data,
        local_state_cs: cs,
      },
    ),
  )
}

bench bench_gs_dat_burn((gs, ls) via create_ls_minted_index) {
  create_new_gs_dat_burn(gs, ls, "")
}

bench bench_gs_dat_delete((gs, ls) via create_ls_not_minted_index) {
  create_new_gs_dat_delete(
    gs,
    ls.local_state_id,
    ls.local_state_data_hash,
    ls.local_state_index,
  )
}

const local_state_a = Pair("a", hash_local_state("data a", ""))

const local_state_b = Pair("b", hash_local_state("data b", ""))

const local_state_c_empty = Pair("c", hash_local_state("data c", ""))

const local_state_d = Pair("d", hash_local_state("data d", ""))

// succeed: local state change when minting where local state id does not exist
test create_new_gs_dat_mint_key_false() {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [local_state_a, local_state_b, local_state_d],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        Pair("c", hash_local_state("", "cs")),
        local_state_a,
        local_state_b,
        local_state_d,
      ],
    }
  let ls_info =
    LocalStateInformation {
      local_state_id: "c",
      local_state_index: -1,
      local_state_data_hash: "",
      local_state_cs: "cs",
    }
  create_new_gs_dat_mint(gs_dat_start, ls_info) == gs_dat_end
}

// succeed: local state change when minting where local state id does exist
test create_new_gs_dat_mint_key_true() {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a, local_state_b, local_state_c_empty, local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        Pair("c", hash_local_state("data c", "cs")),
        local_state_b,
        local_state_a,
        local_state_d,
      ],
    }
  let ls_info =
    LocalStateInformation {
      local_state_id: "c",
      local_state_index: 2,
      local_state_data_hash: "data c",
      local_state_cs: "cs",
    }
  create_new_gs_dat_mint(gs_dat_start, ls_info) == gs_dat_end
}

// fail: local state change when minting where data wrong
test create_new_gs_dat_mint_key_fail1() fail {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a, local_state_b, local_state_c_empty, local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "cs")),
        local_state_d,
      ],
    }
  let ls_info =
    LocalStateInformation {
      local_state_id: "c",
      local_state_index: 2,
      local_state_data_hash: "data b",
      local_state_cs: "cs",
    }
  create_new_gs_dat_mint(gs_dat_start, ls_info) == gs_dat_end
}

// fail: local state change when minting where local state already minted
test create_new_gs_dat_mint_key_fail2() fail {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "cs")),
        local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "cs1")),
        local_state_d,
      ],
    }
  let ls_info =
    LocalStateInformation {
      local_state_id: "c",
      local_state_index: 2,
      local_state_data_hash: "data c",
      local_state_cs: "cs1",
    }
  create_new_gs_dat_mint(gs_dat_start, ls_info) == gs_dat_end
}

// succeed: local state change when burning and update data
test create_new_gs_dat_burn_succeed() {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "cs")),
        local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        Pair("c", hash_local_state("data c1", "")),
        local_state_b,
        local_state_a,
        local_state_d,
      ],
    }
  let ls_info =
    LocalStateInformation {
      local_state_id: "c",
      local_state_index: 2,
      local_state_data_hash: "data c",
      local_state_cs: "cs",
    }
  create_new_gs_dat_burn(gs_dat_start, ls_info, "data c1") == gs_dat_end
}

// fail: local state change when burning, no state minted
test create_new_gs_dat_burn_fail1() fail {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "")),
        local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "")),
        local_state_d,
      ],
    }
  let ls_info =
    LocalStateInformation {
      local_state_id: "c",
      local_state_index: 2,
      local_state_data_hash: "data c",
      local_state_cs: "cs",
    }
  create_new_gs_dat_burn(gs_dat_start, ls_info, "data c1") == gs_dat_end
}

// fail: local state change when burning, no local state id
test create_new_gs_dat_burn_fail2() fail {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [local_state_a, local_state_b, local_state_d],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "")),
        local_state_d,
      ],
    }
  let ls_info =
    LocalStateInformation {
      local_state_id: "c",
      local_state_index: 2,
      local_state_data_hash: "data c",
      local_state_cs: "cs",
    }
  create_new_gs_dat_burn(gs_dat_start, ls_info, "data c1") == gs_dat_end
}

// succeed: local state delete if not minted
test create_new_gs_dat_delete_succeed() {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a, local_state_b, local_state_c_empty, local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [local_state_b, local_state_a, local_state_d],
    }
  create_new_gs_dat_delete(gs_dat_start, "c", "data c", 2) == gs_dat_end
}

// fail: local state delete, local state minted
test create_new_gs_dat_delete_fail1() fail {
  let gs_dat_start =
    GlobalStateDatum {
      alias: "",
      local_state_data: [
        local_state_a,
        local_state_b,
        Pair("c", hash_local_state("data c", "cs")),
        local_state_d,
      ],
    }
  let gs_dat_end =
    GlobalStateDatum {
      alias: "",
      local_state_data: [local_state_a, local_state_b, local_state_d],
    }
  create_new_gs_dat_delete(gs_dat_start, "c", "data c", 2) == gs_dat_end
}
