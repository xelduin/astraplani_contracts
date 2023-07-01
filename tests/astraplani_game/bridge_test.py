import pytest
import asyncio

from tests.astraplani_game.utils import get_anima_ids, pack_ids

L1_BRIDGE_ADDRESS = 0x1
ANIMA_IDS = [11,22,33,44,55,66,777]

##
##  Send message to L2
##
@pytest.mark.asyncio
async def test_bridging(
    starknet, 
    accounts, 
    signers,
    bridge_module, 
    authority_module,
):
    signer = signers['auth_user']
    admin = accounts.auth_user
    anima_id_payload = pack_ids(ANIMA_IDS)

    # MOCK L1 MESSAGING
    await starknet.send_message_to_l2(
        from_address=L1_BRIDGE_ADDRESS,
        to_address=bridge_module.contract_address,
        selector="bridge_from_l1",
        payload=[
            admin.contract_address,
            anima_id_payload
        ],
    )

    # CHECK L2 USER POSSESSES ONE OF THE ANIMA
    anima_id = (ANIMA_IDS[5],0)
    # execution_info = await authority_module.get_anima_possesser(anima_id).call()
    # assert str(execution_info.result.address) == str(user_1)

    execution_info = await signer.send_transaction(
        admin, 
        authority_module.contract_address, 'get_anima_possesser', [anima_id[0], 0],
    )
    assert str(execution_info.call_info.retdata[1]) == str(admin.contract_address)


    