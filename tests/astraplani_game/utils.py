from types import SimpleNamespace
from starkware.starknet.business_logic.state.state import BlockInfo

def get_block_timestamp(starknet_state):
    return starknet_state.state.block_info.block_timestamp


def set_block_timestamp(starknet_state, timestamp):
    starknet_state.state.block_info = BlockInfo(
        starknet_state.state.block_info.block_number, timestamp, 100,
        starknet_state.state.block_info.sequencer_address,
        starknet_state.state.block_info.starknet_version
    )

def pack_ids(_array):
    result = 0
    for idx, id in enumerate(_array):
        result = (id << (idx * 16)) | result

    return result

def get_anima_ids(_array):
    anima_ids = dict()
    for i, id in enumerate(_array):
        name = "anima{}".format(i+1)
        uint256_id = ((id,0)) 
        anima_ids[name] = uint256_id

    return SimpleNamespace(
        **{
            name : id
            for name, id in anima_ids.items()
        }
    )


PRESCIENCE = 0
SENSE = 1
INTUITION = 2
FORTUNE = 3
ORDER = 4
CHAOS = 5
LIGHT = 6
DARK = 7
FIRE = 8
WATER = 9
EARTH = 10
AIR = 11
