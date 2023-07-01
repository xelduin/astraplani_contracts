%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.cairo.common.pow import pow

from starkware.cairo.common.uint256 import Uint256, assert_uint256_le, uint256_eq, uint256_add, uint256_sub, uint256_unsigned_div_rem

from openzeppelin.upgrades.library import Proxy


//
// STORAGE
//

@storage_var
func anima_metadata(anima_id:Uint256) -> (packed_data: felt) {
}

//
//  EXTERNAL
//

@external
func set_anima_metadata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, packed_data : felt
) {
    Proxy.assert_only_admin();
    _set_anima_metadata(anima_id, packed_data);
    return ();
}

// TESTED WELL WITH SETTING DATA FOR 50 IDS PER BATCH
@external
func batch_set_anima_metadata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    cur_anima_id : Uint256, anima_data_arr_len : felt, anima_data_arr : felt*
) {
    Proxy.assert_only_admin();
    if(anima_data_arr_len == 0) {
        return ();
    }

    _set_anima_metadata(cur_anima_id, [anima_data_arr]);

    let (next_anima_id, _) = uint256_add(cur_anima_id, Uint256(1,0));
    batch_set_anima_metadata(next_anima_id, anima_data_arr_len - 1, anima_data_arr + 1);

    return ();
}

@external
func get_anima_attribute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, attribute_id : Uint256
) -> (value:Uint256) {
    let (packed_data) = anima_metadata.read(anima_id);

    let attribute_location = attribute_id.low * 8;
    let (attribute_value) = _unpack_data(packed_data, attribute_location, 255);

    return (value=attribute_value);
}

//
//  INTERNAL
//

func _set_anima_metadata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, packed_data : felt
) {
    anima_metadata.write(anima_id, packed_data);
    return ();
}


func _unpack_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    packed_data: felt, index: felt, mask_size: felt
) -> (value: Uint256) {
    alloc_locals;

    // 1. Create a 8-bit mask at and to the left of the index
    // E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    // E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index);
    // 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
    let mask = mask_size * power;

    // 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, packed_data);

    // 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power);

    return (value=Uint256(result,0));
}

//
// PROXY METHODS
//
@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {
    Proxy.initializer(proxy_admin);
    return ();
}

@view
func get_admin_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) -> (admin : felt) {

    return Proxy.get_admin();
}

@external
func set_admin_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address : felt
) {
    Proxy.assert_only_admin();
    Proxy._set_admin(address);
    return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_implementation: felt
) {
    Proxy.assert_only_admin();
    Proxy._set_implementation_hash(new_implementation);
    return ();
}