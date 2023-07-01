import os
import pytest
import asyncio

from types import SimpleNamespace
from scripts.deploy_metadata import batch_pack_anima, get_anima_attribute

L1_USER_ADDRESS = 0x1

L2_CONTRACTS_DIR = os.path.join(os.getcwd(), "contracts/L2")

IDS_FROM_L1 = []

@pytest.mark.asyncio
async def test_admin(
    accounts, 
    signers,
    game
):
    signer = signers['auth_user']
    admin = accounts.auth_user
    new_admin = accounts.user1

    execution_info = await signer.send_transaction(
        admin, 
        game.contract_address, 'get_admin_address', [],
    )
    assert str(execution_info.call_info.retdata[1]) == str(admin.contract_address)

    await signer.send_transactions(
        admin,
        [
            (game.contract_address, 'set_admin_address', [new_admin.contract_address]),
        ]
    )
    execution_info = await signer.send_transaction(
        admin, 
        game.contract_address, 'get_admin_address', [],
    )
    assert str(execution_info.call_info.retdata[1]) == str(new_admin.contract_address)


    