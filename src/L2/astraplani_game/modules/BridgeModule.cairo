%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256, assert_uint256_le, uint256_eq, uint256_add, uint256_sub, uint256_unsigned_div_rem

from openzeppelin.upgrades.library import Proxy

from src.L2.astraplani_game.modules.interfaces import IAuthorityModule

@storage_var
func authority_module_address() -> (address: felt) {
}


@l1_handler
func bridge_from_l1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    from_address: felt, l2_user: felt, anima_ids: felt
) {
    // Checking if the user has send the message
    _recurse_write_possesser(l2_user, anima_ids, 0);
    return ();
}

func _recurse_write_possesser{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(user: felt, anima_ids: felt, index: felt) -> felt {
    if (index == 7) {
        return 0;
    }

    let (anima_id) = _unpack_data(anima_ids, index * 16, 65535);
    //  anima_possesser.write(777, anima_id);

    if(anima_id == 0) {
        return 0;
    }   

    let (_authority_module_address) = authority_module_address.read();
    IAuthorityModule.set_anima_possesser(_authority_module_address, user, Uint256(anima_id,0));
    
    _recurse_write_possesser(user, anima_ids, index + 1);
    return 0;
}

func _unpack_data{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    data: felt, index: felt, mask_size: felt
) -> (anima_id: felt) {
    alloc_locals;

    // 1. Create a 16-bit mask at and to the left of the index
    // E.g., 000111100 = 2**2 + 2**3 + 2**4 + 2**5
    // E.g.,  2**(i) + 2**(i+1) + 2**(i+2) + 2**(i+3) = (2**i)(15)
    let (power) = pow(2, index);
    // 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512 + 1024 + 2048 = 15
    let mask = mask_size * power;

    // 2. Apply mask using bitwise operation: mask AND data.
    let (masked) = bitwise_and(mask, data);

    // 3. Shift element right by dividing by the order of the mask.
    let (result, _) = unsigned_div_rem(masked, power);

    return (anima_id=result);
}

@external
func set_authority_module_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address: felt
) {
    Proxy.assert_only_admin();
    authority_module_address.write(address);
    return ();
}

@external
func mock_bridge_from_l1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    from_address: felt, l2_user: felt, l1_user: felt, anima_ids: felt
) {
    // Checking if the user has send the message
    _recurse_write_possesser(l2_user, anima_ids, 0);
    return ();
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