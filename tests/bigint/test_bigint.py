import pytest

# RSA-2048 (https://en.wikipedia.org/wiki/RSA_numbers#RSA-2048)
M = 25195908475657893494027183240048398571429282126204032027777137836043662020707595556264018525880784406918290641249515082189298559149176184502808489120072844992687392807287776735971418347270261896375014971824691165077613379859095700097330459748808428401797429100642458691817195118746121515172654632282216869987549182422433637259085141865462043576798423387184774447920739934236584823824281198163815010674810451660377306056201619676256133844143603833904414952634432190114657544454178424020924616515723350778707749817125772467962926386356373289912154831438167899885040445364023527381951378636564391212010397122822120720357
M_LIST_LENGTH = 8


def int_to_list(inp):
    """
    e.g. int_to_list(2**256) = [0, 0, 0, 0, 0, 0, 1, 0]
    """
    hex_str = format(inp, '0512x')
    return [int(hex_str[64 * i: 64 * (i + 1)], 16) for i in range(M_LIST_LENGTH)]


def list_to_int(inp):
    out = 0
    for i in range(M_LIST_LENGTH):
        out += 2 ** (256 * i) * inp[M_LIST_LENGTH - 1 - i]
    return out


M_LIST = int_to_list(M)


@pytest.fixture
def c(get_contract, w3):
    with open('../contracts/bigint/BigInt.vy') as f:
        code = f.read()
    c = get_contract(code)
    return c


@pytest.fixture
def c2(get_contract, w3):
    """
    BigInt.vy with modularAdd and modularSub
    """
    with open('../contracts/bigint/BigInt.vy') as f:
        code = f.read()

    EXP_CODE = """@public
def modularExp(_base: uint256[M_LIST_LENGTH], _e: uint256, _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    e: uint256[M_LIST_LENGTH]
    e[M_LIST_LENGTH - 1] = _e
    return self._bigModExp(_base, e, _m)


@public
def modularExpVariableLength(_base: uint256[M_LIST_LENGTH], _e: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    return self._bigModExp(_base, _e, _m)"""

    ADD_AND_SUB_CODE = """@public
@constant
def modularAdd(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    return self._modularAdd(_a, _b, _m)


@public
@constant
def modularSub(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    return self._modularSub(_a, _b, _m)"""
    code = code.replace(EXP_CODE, ADD_AND_SUB_CODE)
    c = get_contract(code)
    return c


# def test_modularSub(c2):
#     assert list_to_int(c2.modularSub(int_to_list(1), int_to_list(1), M_LIST)) == 0


# def test_modularAdd(c2):
#     assert list_to_int(c2.modularAdd(int_to_list(1), int_to_list(1), M_LIST)) == 1 + 1
