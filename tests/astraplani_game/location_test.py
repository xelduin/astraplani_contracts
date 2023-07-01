import pytest
import asyncio

from starkware.starkware_utils.error_handling import StarkException
from tests.astraplani_game.utils import pack_ids

L1_BRIDGE_ADDRESS = 0x1

##
##  Set Star position
##
@pytest.mark.asyncio
async def test_set_position(
    starknet, 
    accounts, 
    signers,
    bridge_module, 
    location_module,
):
    signer_1 = signers["auth_user"]
    signer_2 = signers["user2"]
    user_1 = accounts.auth_user
    user_2 = accounts.user2
    anima_1 = (80,0)
    anima_2 = (777,0)
    coords_1 = ((234, 0),(231, 0))
    coords_2 = ((23948, 0),(999231, 0))

    # SET user_1 AUTHORITY FOR ANIMAS
    anima_payload = pack_ids([anima_1[0], anima_2[0]])
    await starknet.send_message_to_l2(
        from_address=L1_BRIDGE_ADDRESS,
        to_address=bridge_module.contract_address,
        selector="bridge_from_l1",
        payload=[
            user_1.contract_address,
            anima_payload
        ],
    )

    # SET anima_1 POSITION TO coords_1
    #await location_module.set_anima_position(anima_1,coords_1).execute(user_1)
    await signer_1.send_transactions(
        user_1,
        [
            (location_module.contract_address, 'set_anima_position', [*anima_1, *coords_1[0], *coords_1[1]]),
        ]
    )

    #
    ### anima_1 POSITION EXPECTED AS coords_1
    #
    #execution_info = await location_module.get_position_of_anima(anima_1).call()
    execution_info = await signer_1.send_transaction(
        user_1, 
        location_module.contract_address, 'get_position_of_anima', [*anima_1],
    )
    assert str(execution_info.call_info.retdata[1]) == str(coords_1[0][0])
    assert str(execution_info.call_info.retdata[3]) == str(coords_1[1][0])

    #
    ### EXPECT anima_1 ID AT coords_1
    #
    #execution_info = await location_module.get_anima_at_position(coords_1).call()
    execution_info = await signer_1.send_transaction(
        user_1, 
        location_module.contract_address, 'get_anima_at_position', [*coords_1[0], *coords_1[1]],
    )
    assert str(execution_info.call_info.retdata[1]) == str(anima_1[0])

    # CANT SET anima_1 POSITION ANYMORE
    with pytest.raises(StarkException) as err:
        #await location_module.set_anima_position(anima_1,coords_2).execute(user_1)
        await signer_1.send_transactions(
            user_1,
            [
                (location_module.contract_address, 'set_anima_position', [*anima_1, *coords_2[0], *coords_2[1]]),
            ]
    )
    assert "anima_position/already_positioned" in str(err.value) 

    # CANT POSITION ANOTHER ANIMA AT coords_1
    with pytest.raises(StarkException) as err:
        #await location_module.set_anima_position(anima_2,coords_1).execute(user_1)
        await signer_1.send_transactions(
            user_1,
            [
                (location_module.contract_address, 'set_anima_position', [*anima_2, *coords_1[0], *coords_1[1]]),
            ]
        )
    assert "anima_position/not_empty" in str(err.value) 

    # user_2 HAS NOT AUTHORITY OVER user_1's ANIMA 
    with pytest.raises(StarkException) as err:
        #await location_module.set_anima_position(anima_2,coords_2).execute(user_2)
        await signer_2.send_transactions(
            user_2,
            [
                (location_module.contract_address, 'set_anima_position', [*anima_2, *coords_2[0], *coords_2[1]]),
            ]
        )
    assert "anima_possession/no_permission" in str(err.value) 
