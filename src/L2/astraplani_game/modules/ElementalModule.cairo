%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address, get_block_timestamp
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.math import assert_le, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.pow import pow

from starkware.cairo.common.uint256 import Uint256, assert_uint256_le, uint256_eq, uint256_add, uint256_sub, uint256_unsigned_div_rem, uint256_mul
from starkware.cairo.common.bool import TRUE, FALSE

from openzeppelin.upgrades.library import Proxy

from src.L2.astraplani_game.modules.interfaces import IAuthorityModule, ILocationModule
from src.L2.astraplani_game.tokens.IERC20 import IERC20

const HOUR = 3600;

//
// EVENTS
//

@event
func elemental_transmutation(
    element_id : Uint256, element_amount : Uint256,
){
}

//
// STORAGE
//

@storage_var
func erc20_elementa_address(element_id : Uint256) -> (address : felt) {
}

@storage_var
func authority_module_address() -> (address : felt) {
}

@storage_var
func location_module_address() -> (address: felt) {
}


// last_mana = (last_timestamp, amount)
@storage_var
func last_anima_mana(anima_id : Uint256, element_id : Uint256) -> (last_mana : (felt, Uint256)) {
}

@storage_var
func anima_elemental_level(anima_id : Uint256, element_id : Uint256) -> (level : Uint256) {
}

//
// VIEW
//

@view
func get_erc20_elementa_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (address : felt) {
    let (token_address) = erc20_elementa_address.read(token_id);

    return (address=token_address);
}

@view
func get_elemental_level{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, element_id : Uint256
) -> (level : Uint256) {

    let (current_level) = anima_elemental_level.read(anima_id, element_id); 

    return (level=current_level);
}

@view
func get_anima_mana{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, element_id : Uint256
) -> (mana : Uint256) {
    alloc_locals;
    // MOVE TO CONSTANTS
    let growth_cap = Uint256(400, 0);
    let growth_constant = Uint256(8,0);

    let (last_mana) = last_anima_mana.read(anima_id, element_id); 
    let last_timestamp = last_mana[0];
    let last_mana_amount = last_mana[1];
    assert_not_zero(last_timestamp);

    let (level) = get_elemental_level(anima_id, element_id);
    let (is_level_0) = uint256_eq(level, Uint256(0,0)); 
    // Return 0 if attribute is 0
    if(is_level_0 == TRUE){
        return(mana=Uint256(0,0));
    }

    // GET RATE
    let (growth_constant_level, _) = uint256_mul(growth_constant, level);
    let (growth_cap_level) = uint256_sub(growth_cap, level);

    

    let (growth_op, _) = uint256_add(growth_constant_level, growth_cap_level);

    let (base18) = pow(10,18);
    let (level_base18, _) = uint256_mul(level, Uint256(base18,0));
    let (div_result, _) = uint256_unsigned_div_rem(level_base18, growth_op);

    let (hourly_mana, _) = uint256_mul(growth_cap, div_result);
    //// mana per second
    let (mana_rate, _) = uint256_unsigned_div_rem(hourly_mana, Uint256(HOUR,0));

    //// GET AVAILABLE
    let (block_timestamp) = get_block_timestamp();
    let (time_elapsed) = uint256_sub(Uint256(block_timestamp,0), Uint256(last_timestamp,0));
    let (new_mana, _) = uint256_mul(time_elapsed, mana_rate); 
    let (mana, _) = uint256_add(new_mana, last_mana_amount);
    return (mana=mana);
}

@view
func get_elemental_upgrade_cost{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, element_id : Uint256
) -> (cost : Uint256) {
    // MOVE TO CONSTANT 
    let base_cost = 100;
    let (base18) = pow(10, 18);
    let (full_cost, _) = uint256_mul(Uint256(base_cost,0), Uint256(base18,0));

    let (current_level) = anima_elemental_level.read(anima_id, element_id); 

    let (last_mana) = last_anima_mana.read(anima_id, element_id); 
    let last_timestamp = last_mana[0];
    let last_mana_amount = last_mana[1];
    assert_not_zero(last_timestamp);

    let (upgrade_cost, _) = uint256_mul(current_level, full_cost);

    return (cost=upgrade_cost);
}

//
// EXTERNAL
//

@external
func set_erc20_elementa_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    token_id : Uint256, address: felt
) {
    Proxy.assert_only_admin();
    erc20_elementa_address.write(token_id, address);
    return ();
}

@external
func set_authority_module_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address : felt
) {
    Proxy.assert_only_admin();
    authority_module_address.write(address);

    return ();
}

@external
func set_location_module_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address : felt
) {
    Proxy.assert_only_admin();
    location_module_address.write(address);

    return ();
}

@external
func init_anima{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256
) {
    
    let (caller_address) = get_caller_address();
    
    assert_is_location_module(caller_address);

    let (block_timestamp) = get_block_timestamp();
    
    last_anima_mana.write(anima_id, Uint256(0,0), (block_timestamp, Uint256(0,0)));
    last_anima_mana.write(anima_id, Uint256(1,0), (block_timestamp, Uint256(0,0)));
    last_anima_mana.write(anima_id, Uint256(2,0), (block_timestamp, Uint256(0,0)));
    last_anima_mana.write(anima_id, Uint256(3,0), (block_timestamp, Uint256(0,0)));

    anima_elemental_level.write(anima_id, Uint256(0,0), Uint256(1,0));
    anima_elemental_level.write(anima_id, Uint256(1,0), Uint256(1,0));
    anima_elemental_level.write(anima_id, Uint256(2,0), Uint256(1,0));
    anima_elemental_level.write(anima_id, Uint256(3,0), Uint256(1,0));
    return ();
}

@external
func upgrade_elemental_level{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, element_id: Uint256
) {
    alloc_locals;
    
    let (caller_address) = get_caller_address();
    let (_authority_module_address) = authority_module_address.read();
    IAuthorityModule.assert_address_possesses_anima(_authority_module_address, caller_address, anima_id);

    let (level) = get_elemental_level(anima_id, element_id);
    let (upgrade_cost) = get_elemental_upgrade_cost(anima_id, element_id);

    let (last_mana) = last_anima_mana.read(anima_id, element_id); 
    let last_timestamp = last_mana[0];
    let last_mana_amount = last_mana[1];
    
    assert_not_zero(last_timestamp);

    let (mana) = get_anima_mana(anima_id, element_id);
    assert_uint256_le(upgrade_cost, mana);

    // DICREASE MANA
    let (block_timestamp) = get_block_timestamp();
    let (mana_change) = uint256_sub(mana, upgrade_cost); 
    last_anima_mana.write(anima_id, element_id, (block_timestamp, mana_change));

    // UPGRADE
    let (level_change, _) = uint256_add(level, Uint256(1,0));
    anima_elemental_level.write(anima_id, element_id, level_change);

    return ();
}

@external
func transmute_mana_to_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, element_id : Uint256, amount : Uint256
) {
    alloc_locals;

    let (caller_address) = get_caller_address();
    let (_authority_module_address) = authority_module_address.read();
    IAuthorityModule.assert_address_possesses_anima(_authority_module_address, caller_address, anima_id);

    let (contract_address) = get_contract_address();
    let (token_address) = erc20_elementa_address.read(element_id);
    
    let (mana) = get_anima_mana(anima_id, element_id);
    assert_uint256_le(amount, mana);
    
    // DICREASE MANA
    let (block_timestamp) = get_block_timestamp();
    let (mana_change) = uint256_sub(mana, amount); 
    last_anima_mana.write(anima_id, element_id, (block_timestamp, mana_change));

    // MINT TOKENS
    IERC20.mint(token_address, caller_address, amount);

    return ();
}

@external
func transmute_token_to_mana{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    anima_id : Uint256, element_id : Uint256, amount : Uint256
) {
    alloc_locals;
    
    let (caller_address) = get_caller_address();
    let (_authority_module_address) = authority_module_address.read();
    IAuthorityModule.assert_address_possesses_anima(_authority_module_address, caller_address, anima_id);

    let (contract_address) = get_contract_address();
    let (token_address) = erc20_elementa_address.read(element_id);
    
    let (mana) = get_anima_mana(anima_id, element_id);
    assert_uint256_le(amount, mana);
    
    let (allowance) = IERC20.allowance(token_address, caller_address, contract_address);
    assert_uint256_le(amount, allowance);

    let (token_balance) = IERC20.balanceOf(token_address, caller_address);
    assert_uint256_le(amount, token_balance);

    // INCREASE MANA
    let (block_timestamp) = get_block_timestamp();
    let (mana_change, _) = uint256_add(mana, amount); 
    last_anima_mana.write(anima_id, element_id, (block_timestamp, mana_change));

    // BURN TOKENS
    IERC20.burnFrom(token_address, caller_address, amount);

    return ();
}

//
// ASSERTIONS
//

@view
func assert_is_location_module{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(
    address : felt
) {
    alloc_locals;

    with_attr error_message("elemental/no_permission") {
        let (local _location_module) = location_module_address.read();
        assert address = _location_module;
        return ();
        
    }

    //return ();
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