%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address, get_block_number
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256,  uint256_eq

from openzeppelin.upgrades.library import Proxy

//
//  EVENTS
//

@event
func anima_possessed(
    anima_id : Uint256, address : felt
){
}

//
// STORAGE
//

@storage_var
func bridge_module_address() -> (address : felt) {
}

@storage_var
func anima_possesser(anima_id : Uint256) -> (address : felt) {
}

//
//  PROXY INTERFACE
//

//
//  VIEW
//

@view
func get_anima_possesser{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256
) -> (address : felt) {
    let (address) = anima_possesser.read(anima_id);

    return (address=address);
}

//
// EXTERNALS
//

@external
func set_bridge_module_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address : felt
) {
    Proxy.assert_only_admin();
    bridge_module_address.write(address);

    return ();
}

@external
func set_anima_possesser{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address : felt, anima_id : Uint256
) {
    let (caller_address) = get_caller_address();

    assert_address_possesses_anima(caller_address, anima_id);
    
    anima_possesser.write(anima_id, address);

    return ();
}

//
//  ASSERTIONS
//

@view
func assert_address_possesses_anima{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address : felt, anima_id : Uint256
) {
    alloc_locals;
    let (local possesser_address) = anima_possesser.read(anima_id);
    // let (is_possesser_zero) = uint256_eq(possesser_address, Uint256(0,0));
    
    with_attr error_message("anima_possession/no_permission") {
        if(possesser_address == 0){
            let (local _bridge_module_address) = bridge_module_address.read();
            assert address = _bridge_module_address;
            return ();
        }


        assert possesser_address = address;
    }

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