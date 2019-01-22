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


### BIG INTEGER ARITHMETIC FUNCTIONS ###

# this assumes that exponent in never larger than 256 bits
@private
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


@private
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

@private
@constant
def _compare(_a: uint256[8], _b: uint256[8]) -> int128:
    for i in range(M_LIST_LENGTH):
        if _a[i] > _b[i]:
            return 1
        elif _a[i] < _b[i]:
            return -1
    return 0

@private
@constant
def _modularSub(_a: uint256[8], _b: uint256[8], _m: uint256[8]) -> uint256[8]:
    o: uint256[8]
    comparison: int128 = self._compare(_a, _b)
    if comparison == 0:
        return o
    elif comparison == 1:
        return self._wrappingSub(_a, _b)
    else:
        tmp: uint256[8] = self._wrappingSub(_b, _a)
        return self._wrappingSub(_m, tmp)

@private
@constant
def _modularAdd(_a: uint256[8], _b: uint256[8], _m: uint256[8]) -> uint256[8]:
    space: uint256[8] = self._wrappingSub(_m, _a)
    o: uint256[8]
    comparison: int128 = self._compare(_a, _b)
    if comparison == 0:
        return o
    elif comparison == 1:
        return self._wrappingAdd(_a, _b)
    else:
        return self._wrappingSub(_b, space)

@private
def _modularMul4(_a: uint256[8], _b: uint256[8], _m: uint256[8]) -> uint256[8]:
    aPlusB: uint256[8] = self._modularExp(self._modularAdd(_a, _b, _m), 2, _m)
    aMinusB: uint256[8] = self._modularExp(self._modularSub(_a, _b, _m), 2, _m)
    return self._modularSub(aPlusB, aMinusB, _m)

# cheat and just do two additions
@private
@constant
def _modularMulBy4(_a: uint256[8], _m: uint256[8]) -> uint256[8]:
    t: uint256[8] = self._modularAdd(_a, _a, _m)
    return self._modularAdd(t, t, _m)
