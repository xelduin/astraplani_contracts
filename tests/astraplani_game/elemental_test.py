import pytest
import asyncio

from tests.astraplani_game.utils import pack_ids, set_block_timestamp, FIRE

L1_BRIDGE_ADDRESS = 0x1
START_TIMESTAMP = 1679521003

##
##  Test Elementa
##
@pytest.mark.asyncio
async def test_elementa(
    starknet,
    accounts,
    signers,
    bridge_module,
    location_module,
    elemental_module,
    elemental_tokens
):
    signer_1 = signers["auth_user"]
    user_1 = accounts.auth_user
    anima_1 = (80,0)
    coords_1 = ((234, 0),(231, 0))
    fire_token = elemental_tokens["fire_token"]
    token_id = (0, 0)
    level_one_cost = 100*10**18

    # SET INITIAL TIMESTAMP
    last_timestamp = START_TIMESTAMP
    set_block_timestamp(starknet.state, last_timestamp)

    # SET AUTHORITY OVER ANIMA AND DEPLOY
    anima_payload = pack_ids([anima_1[0]])
    await starknet.send_message_to_l2(
        from_address=L1_BRIDGE_ADDRESS,
        to_address=bridge_module.contract_address,
        selector="bridge_from_l1",
        payload=[
            user_1.contract_address,
            anima_payload
        ],
    )
    await signer_1.send_transactions(
        user_1,
        [
            (location_module.contract_address, 'set_anima_position', [*anima_1, *coords_1[0], *coords_1[1]]),
        ]
    )

    #
    # FASTFORWARD 30 DAY
    #
    last_timestamp = last_timestamp + 86400 * 30
    set_block_timestamp(starknet.state, last_timestamp)

    #
    # TRANSMUTE MANA TO TOKEN
    #
    execution_info = await signer_1.send_transaction(
        user_1,
        elemental_module.contract_address, "get_anima_mana", [*anima_1, *token_id]
    )
    last_mana = execution_info.call_info.retdata[1]

    mana_to_transmute = 2000
    await signer_1.send_transactions(
        user_1,
        [
            (elemental_module.contract_address, 'transmute_mana_to_token', [*anima_1, *token_id, mana_to_transmute, 0]),
        ]
    )
    execution_info = await signer_1.send_transaction(
        user_1,
        elemental_module.contract_address, "get_anima_mana", [*anima_1, *token_id]
    )
    assert execution_info.call_info.retdata[1] == last_mana - mana_to_transmute
    last_mana = execution_info.call_info.retdata[1] 

    execution_info = await fire_token.balanceOf(user_1.contract_address).call()
    assert execution_info.result.balance[0] == mana_to_transmute
    last_tokens = execution_info.result.balance[0]

    #
    # CHARGE MANA
    #
    tokens_to_transmute = 1000
    await fire_token.approve(elemental_module.contract_address, (tokens_to_transmute,0)).execute(user_1.contract_address)
    await signer_1.send_transactions(
        user_1,
        [
            (elemental_module.contract_address, 'transmute_token_to_mana', [*anima_1, *token_id, tokens_to_transmute, 0]),
        ]
    )

    execution_info = await signer_1.send_transaction(
        user_1,
        elemental_module.contract_address, "get_anima_mana", [*anima_1, *token_id]
    )
    assert execution_info.call_info.retdata[1] == last_mana + tokens_to_transmute
    pre_upgrade_mana = execution_info.call_info.retdata[1]
    
    execution_info = await fire_token.balanceOf(user_1.contract_address).call()
    assert execution_info.result.balance[0] == last_tokens - tokens_to_transmute
    last_tokens = execution_info.result.balance[0]

    # LEVEL UP FIRE
    ### LEVELLING UP DECREASES MANA
    await signer_1.send_transactions(
        user_1,
        [
            (elemental_module.contract_address, 'upgrade_elemental_level', [*anima_1, *token_id]),
        ]
    )

    execution_info = await signer_1.send_transaction(
        user_1,
        elemental_module.contract_address, "get_anima_mana", [*anima_1, *token_id]
    )
    assert execution_info.call_info.retdata[1] == pre_upgrade_mana - level_one_cost
    
    # FASTFORWARD 1 DAY
    last_timestamp = last_timestamp + 86400
    set_block_timestamp(starknet.state, last_timestamp)

    ### EXPECTED NEW MANA
    execution_info = await signer_1.send_transaction(
        user_1,
        elemental_module.contract_address, "get_anima_mana", [*anima_1, *token_id]
    )
    post_levelup_mana = execution_info.call_info.retdata[1]
    mana_delta = post_levelup_mana - (last_mana - level_one_cost)
    level_2_daily_yield = 46376811594202838400
    assert mana_delta == 234

    