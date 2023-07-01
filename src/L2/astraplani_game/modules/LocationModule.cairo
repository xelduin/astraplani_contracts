%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_le, unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256, assert_uint256_eq, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy

from src.L2.astraplani_game.modules.interfaces import IAuthorityModule, IElementalModule

from src.L2.utils.math import Vec2, vec2_is_zero

//
// EVENTS
//

@event
func anima_manifested(
    anima_id : Uint256, pos : Vec2
){
}

//
// STORAGE
//

@storage_var
func authority_module_address() -> (address : felt) {
}

@storage_var
func elemental_module_address() -> (address : felt) {
}

@storage_var
func position_of_anima(anima_id : Uint256) -> (pos : Vec2) {
}

@storage_var
func anima_at_position(pos : Vec2) -> (anima_id : Uint256) {
}

//
// VIEW
//

@view
func get_anima_at_position{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    position : Vec2
) -> (anima_id : Uint256) {

    let (anima_id) = anima_at_position.read(position); 

    return (anima_id=anima_id);
}

@view
func get_position_of_anima{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256
) -> (position : Vec2) {

    let (position) = position_of_anima.read(anima_id); 

    return (position=position);
}

//
// EXTERNAL
//

@external
func set_anima_position{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, position : Vec2
) {
    alloc_locals;

    let (caller_address) = get_caller_address();
    let ( _authority_module_address ) = authority_module_address.read();
    IAuthorityModule.assert_address_possesses_anima(_authority_module_address, caller_address, anima_id);
    
    let ( anima_position ) = position_of_anima.read(anima_id);

    with_attr error_message("anima_position/already_positioned") {
        let ( is_zero_pos ) = check_if_coords_zero(anima_position);
        assert is_zero_pos = TRUE;
    }

    with_attr error_message("anima_position/not_empty") {
        let ( is_empty ) = check_empty_position(position);
        assert is_empty = TRUE;
    }


    position_of_anima.write(anima_id, position);
    anima_at_position.write(position, anima_id);

    let (_elemental_module_address) = elemental_module_address.read();
    IElementalModule.init_anima(_elemental_module_address, anima_id);

    return ();
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
func set_elemental_module_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address: felt
) {
    Proxy.assert_only_admin();
    elemental_module_address.write(address);
    return ();
}

//
//  Checks
//

@view
func check_if_coords_zero{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    coords: Vec2
) -> (result : felt) {
    alloc_locals;

    let (x_is_zero) = uint256_eq(coords.x, Uint256(0,0));
    let (y_is_zero) = uint256_eq(coords.y, Uint256(0,0));

    if(x_is_zero + y_is_zero == 2){
        return (result=TRUE);
    }

    return (result=FALSE);
}

@view
func check_empty_position{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    coords: Vec2
) -> (result : felt) {
    alloc_locals;

    let (anima_at_position) = get_anima_at_position(coords);

    let (is_empty) = uint256_eq(anima_at_position, Uint256(0,0));

    if(is_empty == TRUE) {
        return (result=TRUE);
    }

    return (result=FALSE);
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