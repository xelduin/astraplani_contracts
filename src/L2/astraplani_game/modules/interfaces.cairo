%lang starknet

from starkware.cairo.common.uint256 import Uint256
from src.L2.utils.math import Vec2


@contract_interface
namespace IAuthorityModule {
    func get_anima_possesser(anima_id : Uint256) -> (possesser : felt){
    }
    func set_anima_possesser(address : felt, anima_id : Uint256){
    }
    func assert_address_possesses_anima(address : felt, anima_id : Uint256){
    }
}

@contract_interface
namespace ILocationModule {
    func get_position_of_anima(anima_id : Uint256) -> (position : Vec2){
    }
    func set_anima_position(anima_id : Uint256, coords : Vec2){
    }
}

@contract_interface
namespace IAttributeModule {
    func get_anima_attribute(anima_id : Uint256, attribute_id : Uint256) -> (value : Uint256){
    }
}

@contract_interface
namespace IElementalModule {
    func get_attribute_level(anima_id : Uint256, attribute_id : Uint256) -> (value : Uint256){
    }
    func init_anima(anima_id:Uint256){
    }
}