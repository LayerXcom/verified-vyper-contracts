# Modified from OpenZeppelin's work:
# https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/test/cryptography/ECDSA.test.js

import pytest
from web3 import Web3

TEST_MESSAGE = Web3.sha3(text='OpenZeppelin')
WRONG_MESSAGE = Web3.sha3(text='Nope')
ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'


@pytest.fixture
def c(get_contract):
    with open('../contracts/ecdsa/ECDSA.vy') as f:
        code = f.read()
    c = get_contract(code)
    return c


def recover_with_version(c, sig_without_version, version, message):
    signature = sig_without_version + version
    return c.ecrecoverSig(message, signature)


def test_v0_signature(c):
    signer = '0x2cc1166f6212628a0deef2b33befb2187d35b86c'
    sig_without_version = '0x5d99b6f7f6d1f73d1a26497f2b1c89b24c0993913f86e9a2d02cd69887d9c94f3c880358579d811b21dd1b7fd9bb01c1d81d10e69f0384e675c32b39643be892'

    # with 00 as version value
    assert recover_with_version(c, sig_without_version, '00', TEST_MESSAGE).lower() == signer

    # with 27 as version value (27 = 1b)
    assert recover_with_version(c, sig_without_version, '1b', TEST_MESSAGE).lower() == signer

    # with wrong version
    assert not recover_with_version(c, sig_without_version, '02', TEST_MESSAGE)


def test_v1_signature(c):
    signer = '0x1e318623ab09fe6de3c9b8672098464aeda9100e'
    sig_without_version = '0x331fe75a821c982f9127538858900d87d3ec1f9f737338ad67cad133fa48feff48e6fa0c18abc62e42820f05943e47af3e9fbe306ce74d64094bdf1691ee53e0'

    # with v1 signature
    assert recover_with_version(c, sig_without_version, '01', TEST_MESSAGE).lower() == signer

    # with 28 signature (28 = 1c)
    assert recover_with_version(c, sig_without_version, '1c', TEST_MESSAGE).lower() == signer

    # with 02 signature
    assert not recover_with_version(c, sig_without_version, '02', TEST_MESSAGE)
