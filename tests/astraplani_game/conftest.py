import asyncio
import os

import pytest
from starkware.starknet.public.abi import get_selector_from_name
from starkware.starknet.services.api.contract_class import ContractClass
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from types import SimpleNamespace

from scripts.deploy_metadata import batch_pack_anima
from ..Signer import MockSigner

L2_CONTRACTS_DIR = os.path.join(os.getcwd(), "src/L2")

LOCATION_MODULE_FILE = os.path.join(L2_CONTRACTS_DIR, "astraplani_game/modules/LocationModule.cairo")
AUTHORITY_MODULE_FILE = os.path.join(L2_CONTRACTS_DIR, "astraplani_game/modules/AuthorityModule.cairo")
ATTRIBUTE_MODULE_FILE = os.path.join(L2_CONTRACTS_DIR, "astraplani_game/modules/AttributeModule.cairo")
ELEMENTAL_MODULE_FILE = os.path.join(L2_CONTRACTS_DIR, "astraplani_game/modules/ElementalModule.cairo")
BRIDGE_MODULE_FILE = os.path.join(L2_CONTRACTS_DIR, "astraplani_game/modules/BridgeModule.cairo")

ERC20_ELEMENT_FILE = os.path.join(L2_CONTRACTS_DIR, "astraplani_game/tokens/ERC20_Element.cairo")
GAME_CONTRACT = os.path.join(L2_CONTRACTS_DIR, "astraplani_game/game.cairo")
ACCOUNT_FILE = os.path.join(L2_CONTRACTS_DIR, "Account.cairo")
PROXY_FILE = os.path.join(L2_CONTRACTS_DIR, 'proxy.cairo')

async def deploy_account(starknet, signer, source):
    return await starknet.deploy(
        source=source,
        constructor_calldata=[signer.public_key],
    )

async def deploy_proxy(starknet, admin, source):
    class_decl = await starknet.declare(source=source)
    selector = get_selector_from_name('initializer')
    params = [
        admin.contract_address,
    ]
    contract = await starknet.deploy(
        source=PROXY_FILE,
        constructor_calldata=[
            class_decl.class_hash,
            selector,
            len(params),
            *params
        ]
    )
    return contract

MAX_LEN_FELT = 31
def str_to_felt(text):
    if len(text) > MAX_LEN_FELT:
        raise Exception("Text length too long to convert to felt.")

    return int.from_bytes(text.encode(), "big")


@pytest.fixture(scope="session")
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="session")
async def starknet() -> Starknet:
    starknet = await Starknet.empty()
    return starknet

@pytest.fixture(scope="module")
async def signers():
    return dict(
        user1=MockSigner(23904852345),
        user2=MockSigner(23904852345),
        user3=MockSigner(23904852345),
        auth_user=MockSigner(83745982347),
    )

@pytest.fixture(scope="module")
async def accounts(starknet, signers):
    # Maps from name -> account contract
    accounts = SimpleNamespace(
        **{
            name: (await deploy_account(starknet, signer, ACCOUNT_FILE))
            for name, signer in signers.items()
        }
    )

    return accounts

@pytest.fixture(scope="module")
async def game(starknet, accounts) -> StarknetContract:
    admin = accounts.auth_user
    return await deploy_proxy(starknet, admin, GAME_CONTRACT)

@pytest.fixture(scope="module")
async def bridge_module(starknet, accounts) -> StarknetContract:
    admin = accounts.auth_user
    return await deploy_proxy(starknet, admin, BRIDGE_MODULE_FILE)

@pytest.fixture(scope="module")
async def authority_module(starknet, bridge_module, accounts, signers) -> StarknetContract:
    signer = signers['auth_user']
    admin = accounts.auth_user
    authority_module = await deploy_proxy(starknet, admin, AUTHORITY_MODULE_FILE)

    await signer.send_transactions(
        admin,
        [
            (bridge_module.contract_address, 'set_authority_module_address', [authority_module.contract_address]),
            (authority_module.contract_address, 'set_bridge_module_address', [bridge_module.contract_address]),
        ]
    )

    return authority_module

@pytest.fixture(scope="module")
async def attribute_module(starknet, signers, accounts) -> StarknetContract:
    signer = signers['auth_user']
    admin = accounts.auth_user
    attribute_module = await deploy_proxy(starknet, admin, ATTRIBUTE_MODULE_FILE)

    for i in range(0,16):
        cur_id = i*50+1
        anima_data = batch_pack_anima(cur_id)
        #await attribute_module.batch_set_anima_metadata((cur_id,0), anima_data).execute()

        await signer.send_transactions(
            admin,
            [
                (attribute_module.contract_address, 'batch_set_anima_metadata', [cur_id, 0, len(anima_data), *anima_data]),
            ]
        )


    return attribute_module

@pytest.fixture(scope="module")
async def elemental_module(starknet, signers, accounts, authority_module) -> StarknetContract:
    signer = signers['auth_user']
    admin = accounts.auth_user
    elemental_module = await deploy_proxy(starknet, admin, ELEMENTAL_MODULE_FILE)

    await signer.send_transactions(
        admin,
        [
            (elemental_module.contract_address, 'set_authority_module_address', [authority_module.contract_address]),
        ]
    )

    return elemental_module

@pytest.fixture(scope="module")
async def location_module(starknet, signers, accounts, authority_module, elemental_module) -> StarknetContract:
    signer = signers['auth_user']
    admin = accounts.auth_user
    location_module = await deploy_proxy(starknet, admin, LOCATION_MODULE_FILE)

    await signer.send_transactions(
        admin,
        [
            (location_module.contract_address, 'set_authority_module_address', [authority_module.contract_address]),
            (location_module.contract_address, 'set_elemental_module_address', [elemental_module.contract_address]),
            (elemental_module.contract_address, 'set_location_module_address', [location_module.contract_address])
        ]
    )

    return location_module

elements = [
    "Fire",
    "Water",
    "Earth",
    "Air"
]
@pytest.fixture(scope="module")
async def elemental_tokens(starknet, elemental_module, signers, accounts) -> StarknetContract:    
    signer = signers['auth_user']
    admin = accounts.auth_user
    tokens = dict()
    for i, el_name in enumerate(elements):
        token = await starknet.deploy(
            source=ERC20_ELEMENT_FILE,
            constructor_calldata=[
                str_to_felt(el_name+"Essence"), #name
                str_to_felt(el_name.upper()), #symbol,
                18, #decimals
                elemental_module.contract_address
            ]
        )
    
        await signer.send_transactions(
            admin,
            [
                (elemental_module.contract_address, 'set_erc20_elementa_address', [i, 0, token.contract_address]),
            ]
        )
        
        tokens[el_name.lower() + "_token"] = token

    return tokens
