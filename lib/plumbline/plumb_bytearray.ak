use aiken/builtin.{blake2b_256}
use aiken/cbor.{serialise}
use aiken/collection/list
use aiken/primitive/bytearray

/// Rotatory combine to bytearray lists to a single one.
/// First two are combined, last one should be empty.
pub fn merge_list(
  one: List<ByteArray>,
  two: List<ByteArray>,
  new: List<ByteArray>,
) -> List<ByteArray> {
  when (one, two) is {
    ([], []) -> new
    ([x, ..xs], [y, ..ys]) -> merge_list(xs, ys, list.concat(new, [x, y]))
    ([x, ..xs], []) -> merge_list(xs, [], list.concat(new, [x]))
    ([], [y, ..ys]) -> merge_list([], ys, list.concat(new, [y]))
  }
}

/// Combine bytearray list to a single bytearray
pub fn append_list(self: List<ByteArray>) -> ByteArray {
  when self is {
    [] -> ""
    [x, ..xs] -> bytearray.concat(x, append_list(xs))
  }
}

/// Serialise bytearray list and return BLAKE2b-256.
pub fn serialise_hash_list(self: List<ByteArray>) -> ByteArray {
  blake2b_256(serialise(self))
}
