import pytest

FIRST_TOKEN_ID = 1
SECOND_TOKEN_ID = 2
INVALID_TOKEN_ID = 3
ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
ERC165_INTERFACE_ID = '0x0000000000000000000000000000000000000000000000000000000001ffc9a7'
ERC721_INTERFACE_ID = '0x0000000000000000000000000000000000000000000000000000000080ac58cd'
INVALID_INTERFACE_ID = '0x0000000000000000000000000000000000000000000000000000000012345678'


@pytest.fixture
def c(get_contract, w3):
    with open('./erc721/ERC721.vy') as f:
        code = f.read()
    c = get_contract(code)
    owner, operator, someone = w3.eth.accounts[:3]
    c.mint(someone, FIRST_TOKEN_ID, transact={'from': owner})
    return c


def test_supportsInterface(c, assert_tx_failed):
    assert c.supportsInterface(ERC165_INTERFACE_ID) == True
    assert c.supportsInterface(ERC721_INTERFACE_ID) == True
    assert c.supportsInterface(INVALID_INTERFACE_ID) == False


def test_balanceOf(c, w3, assert_tx_failed):
    owner, operator, someone = w3.eth.accounts[:3]
    assert c.balanceOf(someone) == 1
    assert_tx_failed(lambda: c.balanceOf(ZERO_ADDRESS))


def test_ownerOf(c, w3, assert_tx_failed):
    owner, operator, someone = w3.eth.accounts[:3]
    assert c.ownerOf(FIRST_TOKEN_ID) == someone
    assert_tx_failed(lambda: c.ownerOf(INVALID_TOKEN_ID))


def test_getApproved(c, w3, assert_tx_failed):
    owner, operator, someone = w3.eth.accounts[:3]

    # getApproved of token not existing
    assert_tx_failed(lambda: c.approve(
        operator, INVALID_TOKEN_ID, transact={'from': someone}))

    assert c.getApproved(FIRST_TOKEN_ID) is None

    c.approve(operator, FIRST_TOKEN_ID, transact={'from': someone})

    assert c.getApproved(FIRST_TOKEN_ID) == operator


def test_isApprovedForAll(c, w3):
    owner, operator, someone = w3.eth.accounts[:3]

    assert c.isApprovedForAll(someone, operator) == False

    c.setApprovalForAll(operator, True,  transact={'from': someone})

    assert c.isApprovedForAll(someone, operator) == True


def test_transferFrom(c, w3, assert_tx_failed, get_logs):
    owner, operator, someone = w3.eth.accounts[:3]

    # transfer from zero address
    assert_tx_failed(lambda: c.transferFrom(
        ZERO_ADDRESS, operator, FIRST_TOKEN_ID, transact={'from': someone}))

    # transfer to zero address
    assert_tx_failed(lambda: c.transferFrom(
        someone, ZERO_ADDRESS, FIRST_TOKEN_ID, transact={'from': someone}))

    # transfer token without ownership
    assert_tx_failed(lambda: c.transferFrom(
        someone, operator, SECOND_TOKEN_ID, transact={'from': someone}))

    tx_hash = c.transferFrom(
        someone, operator, FIRST_TOKEN_ID, transact={'from': someone})

    logs = get_logs(tx_hash, c, 'Transfer')

    assert len(logs) > 0
    assert logs[0]['args']['_from'] == someone
    assert logs[0]['args']['_to'] == operator
    assert logs[0]['args']['_tokenId'] == FIRST_TOKEN_ID

    assert c.balanceOf(someone) == 0
    assert c.balanceOf(operator) == 1


def test_approve(c, w3, assert_tx_failed, get_logs):
    owner, operator, someone = w3.eth.accounts[:3]

    # approve myself
    assert_tx_failed(lambda: c.approve(
        someone, FIRST_TOKEN_ID, transact={'from': someone}))

    # approve token without ownership
    assert_tx_failed(lambda: c.approve(
        operator, SECOND_TOKEN_ID, transact={'from': someone}))

    tx_hash = c.approve(operator, FIRST_TOKEN_ID, transact={'from': someone})
    logs = get_logs(tx_hash, c, 'Approval')

    assert len(logs) > 0
    assert logs[0]['args']['_owner'] == someone
    assert logs[0]['args']['_approved'] == operator
    assert logs[0]['args']['_tokenId'] == FIRST_TOKEN_ID


def test_setApprovalForAll(c, w3, assert_tx_failed, get_logs):
    owner, operator, someone = w3.eth.accounts[:3]
    approved = True

    # setApprovalForAll to zero address
    assert_tx_failed(lambda: c.setApprovalForAll(
        ZERO_ADDRESS, approved, transact={'from': someone}))

    tx_hash = c.setApprovalForAll(operator, True, transact={'from': someone})
    logs = get_logs(tx_hash, c, 'ApprovalForAll')

    assert len(logs) > 0
    assert logs[0]['args']['_owner'] == someone
    assert logs[0]['args']['_operator'] == operator
    assert logs[0]['args']['_approved'] == approved


def test_mint(c, w3, assert_tx_failed, get_logs):
    owner, operator, someone = w3.eth.accounts[:3]

    # mint by non-owner
    assert_tx_failed(lambda: c.mint(
        someone, FIRST_TOKEN_ID, transact={'from': someone}))

    # mint to zero address
    assert_tx_failed(lambda: c.mint(
        ZERO_ADDRESS, FIRST_TOKEN_ID, transact={'from': owner}))

    tx_hash = c.mint(someone, SECOND_TOKEN_ID, transact={'from': owner})
    logs = get_logs(tx_hash, c, 'Transfer')

    assert c.balanceOf(someone) == 2
    assert len(logs) > 0
    assert logs[0]['args']['_from'] == ZERO_ADDRESS
    assert logs[0]['args']['_to'] == someone
    assert logs[0]['args']['_tokenId'] == SECOND_TOKEN_ID


def test_burn(c, w3, assert_tx_failed, get_logs):
    owner, operator, someone = w3.eth.accounts[:3]

    # burn token without ownership
    assert_tx_failed(lambda: c.burn(FIRST_TOKEN_ID, transact={'from': owner}))

    tx_hash = c.burn(FIRST_TOKEN_ID, transact={'from': someone})
    logs = get_logs(tx_hash, c, 'Transfer')

    assert c.balanceOf(someone) == 0
    assert len(logs) > 0
    assert logs[0]['args']['_from'] == someone
    assert logs[0]['args']['_to'] == ZERO_ADDRESS
    assert logs[0]['args']['_tokenId'] == FIRST_TOKEN_ID
