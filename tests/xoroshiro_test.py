import os
import pytest

from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/L2/xoroshiro128_starstar.cairo")


STATE = (0, 0)
SEED = 457365765    
U64 = 2**64-1

10444195510023404247
4067893592253325718
14091943852402403153
9828888747926526404

def splitmix64(x):
    U64 = 2**64-1

    z = x + 0x9e3779b97f4a7c15
    z &= U64
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9
    z &= U64
    z = (z ^ (z >> 27)) * 0x94d049bb133111eb
    z &= U64
    return (z ^ (z >> 31)) & U64


@pytest.mark.asyncio
async def test_next():
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
        constructor_calldata=[SEED]
    )


    s0 = splitmix64(SEED)
    s1 = splitmix64(s0)
    global STATE
    STATE = (s0, s1)

    def rotl(x, k):
        return (x << k) | (x >> (64 - k))

    def next():
        global STATE
        s0, s1 = STATE
        result = (rotl(s0 * 5, 7) * 9) & U64

        s1 ^= s0
        new_s0 = (rotl(s0, 24) ^ s1 ^ (s1 << 16)) & U64
        new_s1 = (rotl(s1, 37)) & U64
        STATE = (new_s0, new_s1)
        return result

    for r in range(1):
        tx = await contract.next().execute()
        r = next()
        assert tx.result.rnd == 0
