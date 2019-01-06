# @dev RSA Accumulator
# @author Ryuya Nakamura (@nrryuya)
# Based on The Matter team's work:
# https://github.com/matterinc/RSAAccumulator/blob/master/contracts/RSAAccumulator.sol

### CONSTANTS ###
# FIXME: The sizes of arrays in this file should be replaced with these constants:
#        https://github.com/ethereum/vyper/issues/1167

N_LIMBS_LENGTH: constant(int128) = 8
G: constant(uint256) = 3

M_LIST_LENGTH: constant(int128) = N_LIMBS_LENGTH
M_BYTE_COUNT: constant(int128) = 32 * M_LIST_LENGTH
M_BYTE_COUNT_BYTES32: constant(bytes32) = convert(M_BYTE_COUNT, bytes32)
# For now, the same lengths are used for the simplicity of impelementation.
BASE_BYTE_COUNT_BYTES32: constant(bytes32) = M_BYTE_COUNT_BYTES32
E_BYTE_COUNT_BYTES32: constant(bytes32) = M_BYTE_COUNT_BYTES32

PRECOMPILED_BIGMODEXP: constant(address) = 0x0000000000000000000000000000000000000005


### STORAGE VARIABLES ###

g: public(uint256[8]) # Never modified once set in constructor
accumulator: public(uint256[8]) # try to store as static array for now; In BE
N: public(uint256[8])


### BIG INTEGER ARITHMETIC FUNCTIONS ###

# this assumes that exponent in never larger than 256 bits
@public
def _modularExp(_base: uint256[8], _e: uint256, _m: uint256[8]) -> uint256[8]:
    e: uint256[8]
    e[M_LIST_LENGTH - 1] = _e

    tmp: bytes32[8]
    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_base[i], bytes32)
    base: bytes[256] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(e[i], bytes32)
    exponent: bytes[256] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_m[i], bytes32)
    modulus: bytes[256] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])
    # ref. https://eips.ethereum.org/EIPS/eip-198
    # 864 = 32 * 3 + <length_of_BASE> + <length_of_EXPONENT> + <length_of_MODULUS>
    data: bytes[864] = concat(BASE_BYTE_COUNT_BYTES32, E_BYTE_COUNT_BYTES32, M_BYTE_COUNT_BYTES32,
                    base, exponent, modulus)
    # NOTE: raw_call doesn't support static call for now.
    res: bytes[256] = raw_call(PRECOMPILED_BIGMODEXP, data, outsize=256, gas=2000)
    
    out: uint256[8]
    for i in range(M_LIST_LENGTH):
        out[i] = convert(extract32(res, i * 32, type=bytes32), uint256)
    return out


@public
def _modularExpVariableLength(_base: uint256[8], _e: uint256[8], _m: uint256[8]) -> uint256[8]:
    tmp: bytes32[8]
    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_base[i], bytes32)
    base: bytes[256] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_e[i], bytes32)
    exponent: bytes[256] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_m[i], bytes32)
    modulus: bytes[256] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])
    # ref. https://eips.ethereum.org/EIPS/eip-198
    # 864 = 32 * 3 + <length_of_BASE> + <length_of_EXPONENT> + <length_of_MODULUS>
    data: bytes[864] = concat(BASE_BYTE_COUNT_BYTES32, E_BYTE_COUNT_BYTES32, M_BYTE_COUNT_BYTES32,
                    base, exponent, modulus)
    # NOTE: raw_call doesn't support static call for now.
    res: bytes[256] = raw_call(PRECOMPILED_BIGMODEXP, data, outsize=256, gas=2000)
    
    out: uint256[8]
    for i in range(M_LIST_LENGTH):
        out[i] = convert(extract32(res, i * 32, type=bytes32), uint256)
    return out


@private
@constant
def _wrappingSub(_a: uint256[8], _b: uint256[8]) -> uint256[8]:
    borrow: bool = False
    limb: uint256 = 0
    o: uint256[8]
    for i in range(M_LIST_LENGTH):
        j: int128 = M_LIST_LENGTH - i
        limb = _a[j]
        if borrow:
            if limb == 0:
                borrow = True
                limb -= 1
                o[j] = limb - _b[j]
            else:
                limb -= 1
                if limb >= _b[j]:
                    borrow = False
                o[j] = limb - _b[j]
        else:
            if limb < _b[j]:
                borrow = True
            o[j] = limb - _b[j]
    return o

@private
@constant
def _wrappingAdd(_a: uint256[8], _b: uint256[8]) -> uint256[8]:
    carry: bool = False
    limb: uint256 = 0
    subaddition: uint256 = 0
    o: uint256[8]
    for i in range(M_LIST_LENGTH):
        j: int128 = M_LIST_LENGTH - i
        limb = _a[j]
        if carry:
            if limb == 0:
                carry = True
                o[j] = _b[j]
            else:
                limb += 1
                subaddition = limb + _b[j]
                if subaddition >= limb:
                    carry = False
                o[j] = subaddition
        else:
            subaddition = limb + _b[j]
            if subaddition < limb:
                carry = True
            o[j] = subaddition
    return o

@public
@constant
def _modularSub(_a: uint256[8], _b: uint256[8], _m: uint256[8]) -> uint256[8]:
    o: uint256[8]

    # comparison: int128 = self._compare(_a, _b)
    comparison: int128 = 0
    for i in range(M_LIST_LENGTH):
        if _a[i] > _b[i]:
            comparison = 1
        elif _a[i] < _b[i]:
            comparison = -1

    if comparison == 0:
        return o
    elif comparison == 1:
        return self._wrappingSub(_a, _b)
    else:
        tmp: uint256[8] = self._wrappingSub(_b, _a)
        return self._wrappingSub(_m, tmp)

@public
@constant
def _modularAdd(_a: uint256[8], _b: uint256[8], _m: uint256[8]) -> uint256[8]:
    space: uint256[8] = self._wrappingSub(_m, _a)
    o: uint256[8]

    # comparison: int128 = self._compare(_a, _b)
    comparison: int128 = 0
    for i in range(M_LIST_LENGTH):
        if _a[i] > _b[i]:
            comparison = 1
        elif _a[i] < _b[i]:
            comparison = -1

    if comparison == 0:
        return o
    elif comparison == 1:
        return self._wrappingAdd(_a, _b)
    else:
        return self._wrappingSub(_b, space)

# NOTE: Removing _modularMul4 increases the code size.
@private
def _modularMul4(_a: uint256[8], _b: uint256[8], _m: uint256[8]) -> uint256[8]:
    aPlusB: uint256[8] = self._modularExp(self._modularAdd(_a, _b, _m), 2, _m)
    aMinusB: uint256[8] = self._modularExp(self._modularSub(_a, _b, _m), 2, _m)
    return self._modularSub(aPlusB, aMinusB, _m)

# NOTE: Removing _modularMulBy4 increases the code size.
# cheat and just do two additions
@private
@constant
def _modularMulBy4(_a: uint256[8], _m: uint256[8]) -> uint256[8]:
    t: uint256[8] = self._modularAdd(_a, _a, _m)
    return self._modularAdd(t, t, _m)


### ACCUMULATOR FUNCTIONS ###

@public
def __init__(_N: uint256[8]):
    self.N = _N
    initialAccumulator: uint256[8]
    initialAccumulator[N_LIMBS_LENGTH - 1] = G
    self.g = initialAccumulator
    self.accumulator = initialAccumulator

@public
def updateAccumulator(_value: uint256):
    self.accumulator = self._modularExp(self.accumulator, _value, self.N)

@public
def updateAccumulatorMultiple(_limbs: uint256[8]):
    self.accumulator = self._modularExpVariableLength(self.accumulator, _limbs, self.N)

@private
@constant
def _isPrime(_num: uint256) -> bool:
    assert _num < 2 ** 64
    # TODO: Implementation!
    return True

# check that (g^w)^x = A
@public
def checkInclusionProof(_prime: uint256, _witnessLimbs: uint256[8]) -> bool:
    assert self._isPrime(_prime)
    Nread: uint256[8] = self.N
    lhs: uint256[8] = self._modularExpVariableLength(self.g, _witnessLimbs, Nread)
    lhs = self._modularExp(lhs, _prime, Nread)

    comparison: int128 = 0
    for i in range(M_LIST_LENGTH):
        if lhs[i] > self.accumulator[i]:
            comparison = 1
        elif lhs[i] < self.accumulator[i]:
            comparison = -1

    if comparison != 0:
        return False
    return True

# check that A*(g^r) = g^(x1*x2*...*xn)^cofactor
@public
def checkNonInclusionProof(_primes: uint256[8], _rLimbs: uint256[8], _cofactorLimbs: uint256[8]) -> bool:
    for p in _primes:
        assert self._isPrime(p)
    Nread: uint256[8] = self.N
    lhs: uint256[8] = self._modularExpVariableLength(self.g, _rLimbs, Nread)
    lhs = self._modularMul4(lhs, self.accumulator, Nread)
    # extra factor of 4 on the LHS, assuming M_LIST_LENGTH % 4 == 0
    multiplicationResult: uint256 = 1
    rhs: uint256[8] = self._modularExpVariableLength(self.g, _cofactorLimbs, Nread)
    for i in range(2): # 2 = M_LIST_LENGTH / 4
        multiplicationResult = _primes[4 * i] * _primes[4 * i + 1] * _primes[4 * i + 2] * _primes[4 * i + 3]
        rhs = self._modularExp(rhs, multiplicationResult, Nread)
    rhs = self._modularMulBy4(rhs, Nread)
    # extra factor of 4 on LHS is compensated

    comparison: int128 = 0
    for i in range(M_LIST_LENGTH):
        if lhs[i] > rhs[i]:
            comparison = 1
        elif lhs[i] < rhs[i]:
            comparison = -1

    if comparison != 0:
        return False
    return True
