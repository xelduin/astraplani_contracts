%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_eq

struct Vec2 {
    x : Uint256,
    y : Uint256,
}

func vec2_add{range_check_ptr}(
    a : Vec2, b : Vec2
) -> (result: Vec2) {

    let x = uint256_add(a.x, b.x);
    let y = uint256_add(a.y, b.y);  

    let result = Vec2(x=x, y=y);

    return (result=result);
}

func vec2_is_zero{range_check_ptr}(
    a : Vec2
) -> (result: felt) {
    alloc_locals;
    let (local x_is_zero) = uint256_eq(a.x, Uint256(0,0));
    let (local y_is_zero) = uint256_eq(a.y, Uint256(0,0));

    if(x_is_zero + y_is_zero == 0){
        return (result=1);
    }

    return (result=0);
}
