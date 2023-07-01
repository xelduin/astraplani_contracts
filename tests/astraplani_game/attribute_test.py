import pytest
import asyncio

from scripts.deploy_metadata import get_anima_attribute
from tests.astraplani_game.utils import CHAOS

##
##  Test Metadata
##
@pytest.mark.asyncio
async def test_metadata(
    attribute_module,
    signers,
    accounts
):
    signer = signers['auth_user']
    admin = accounts.auth_user
    anima_id = (80,0)
    attribute_id = (CHAOS,0)

    anima_attribute_value = get_anima_attribute(anima_id[0], attribute_id[0])

    execution_info = await signer.send_transaction(
        admin, 
        attribute_module.contract_address, 'get_anima_attribute', [anima_id[0], 0, attribute_id[0], 0],
    )
    assert str(execution_info.call_info.retdata[1]) == str(anima_attribute_value)


    #execution_info = await attribute_module.get_anima_attribute(anima_id, attribute_id).call()
    #assert execution_info.result.value.low == anima_attribute_value
