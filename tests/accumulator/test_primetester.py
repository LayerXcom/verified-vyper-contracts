import pytest
from web3 import Web3

from eth_tester import PyEVMBackend, EthereumTester


N = [2,3,5,7] # primes less than 2**64

a = 2 # base for primality test

@pytest.fixture
def c(get_contract):
    with open('../contracts/accumulator/PrimeTester.vy') as f:
        code = f.read()
    # FIXME: eth.exceptions.OutOfGas: Contract code size exceeds EIP170 limit of 24577.
    c = get_contract(code, N)
    return c


def test_init_state(c):
    assert uint256_list_to_int(c.a) == a
    
def uint256_list_to_int(l):
    out = 0
    for i in range(len(l)):
        out += l[i] * 2 ** (32 * i)
    return out



"""
TODO: Set EVM Backend to increase its max_available_gas
"""
def test_prime(c):
    assert c.isPrime(2) is True
    
            
