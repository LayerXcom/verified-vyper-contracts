# @dev RSA Accumulator
# @author Ryuya Nakamura (@nrryuya)
# Based on The Matter team's work:
# https://github.com/matterinc/RSAAccumulator/blob/master/contracts/RSAAccumulator.sol

### CONSTANTS ###
M_LIST_LENGTH: constant(int128) = 8
M_BYTE_COUNT: constant(int128) = 32 * M_LIST_LENGTH
# For now, the same lengths are used for the simplicity of impelementation.
BASE_BYTE_COUNT: constant(int128) = M_BYTE_COUNT
E_BYTE_COUNT: constant(int128) = M_BYTE_COUNT
# Lenth in bytes32 representation
M_BYTE_COUNT_BYTES32: constant(bytes32) = convert(M_BYTE_COUNT, bytes32)
BASE_BYTE_COUNT_BYTES32: constant(bytes32) = convert(BASE_BYTE_COUNT, bytes32)
E_BYTE_COUNT_BYTES32: constant(bytes32) = convert(BASE_BYTE_COUNT, bytes32)

PRECOMPILED_BIGMODEXP: constant(address) = 0x0000000000000000000000000000000000000005
BIGMODEXP_RES_SIZE: constant(int128) = 32 * 3 + M_BYTE_COUNT + BASE_BYTE_COUNT + E_BYTE_COUNT

### BIG INTEGER ARITHMETIC FUNCTIONS ###

@private
def _bigModExp(_base: uint256[M_LIST_LENGTH], _e: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    # convert UInt256 list to bytes (inlined for code size reduction)
    tmp: bytes32[M_LIST_LENGTH]
    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_base[i], bytes32)
    base: bytes[M_BYTE_COUNT] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

    # convert UInt256 list to bytes (inlined for code size reduction)
    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_e[i], bytes32)
    exponent: bytes[M_BYTE_COUNT] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

    # convert UInt256 list to bytes (inlined for code size reduction)
    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_m[i], bytes32)
    modulus: bytes[M_BYTE_COUNT] = concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

    # ref. https://eips.ethereum.org/EIPS/eip-198
    data: bytes[BIGMODEXP_RES_SIZE] = concat(
        BASE_BYTE_COUNT_BYTES32, E_BYTE_COUNT_BYTES32, M_BYTE_COUNT_BYTES32, base, exponent, modulus)
    # NOTE: raw_call doesn't support static call for now.
    res: bytes[M_BYTE_COUNT] = raw_call(PRECOMPILED_BIGMODEXP, data, outsize=256, gas=2000)

    # convert bytes array to UInt256 list (inlined for code size reduction)
    out: uint256[M_LIST_LENGTH]
    for i in range(M_LIST_LENGTH):
        out[i] = convert(extract32(res, i * 32, type=bytes32), uint256)
    return out


@private
@constant
def _wrappingSub(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    borrow: bool = False
    limb: uint256 = 0
    o: uint256[M_LIST_LENGTH]
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
def _wrappingAdd(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    carry: bool = False
    limb: uint256 = 0
    subaddition: uint256 = 0
    o: uint256[M_LIST_LENGTH]
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
def _modularSub(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    o: uint256[M_LIST_LENGTH]

    # Comparison (inlined for code size reduction)
    comparison: int128
    for i in range(M_LIST_LENGTH):
        if _a[i] > _b[i]:
            comparison = 1
        elif _a[i] < _b[i]:
            comparison = -1
        else:
            comparison = 0

    if comparison == 0:
        return o
    elif comparison == 1:
        return self._wrappingSub(_a, _b)
    else:
        tmp: uint256[M_LIST_LENGTH] = self._wrappingSub(_b, _a)
        return self._wrappingSub(_m, tmp)


@private
@constant
def _modularAdd(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    space: uint256[M_LIST_LENGTH] = self._wrappingSub(_m, _a)
    o: uint256[M_LIST_LENGTH]

    # Comparison (inlined for code size reduction)
    comparison: int128
    for i in range(M_LIST_LENGTH):
        if _a[i] > _b[i]:
            comparison = 1
        elif _a[i] < _b[i]:
            comparison = -1
        else:
            comparison = 0

    if comparison == 0:
        return o
    elif comparison == 1:
        return self._wrappingAdd(_a, _b)
    else:
        return self._wrappingSub(_b, space)


### PUBLIC FUNCTIONS ###
@public
@constant
def modularAdd(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    return self._modularAdd(_a, _b, _m)


@public
@constant
def modularSub(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    return self._modularSub(_a, _b, _m)


@public
def modularExp(_base: uint256[M_LIST_LENGTH], _e: uint256, _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    e: uint256[M_LIST_LENGTH]
    e[M_LIST_LENGTH - 1] = _e
    return self._bigModExp(_base, e, _m)


@public
def modularExpVariableLength(_base: uint256[M_LIST_LENGTH], _e: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    return self._bigModExp(_base, _e, _m)


# 4ab = (a + b)^2 - (a - b)^2
@public
def modularMul4(_a: uint256[M_LIST_LENGTH], _b: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    two: uint256[M_LIST_LENGTH]
    two[M_LIST_LENGTH - 1] = 2
    aPlusB: uint256[M_LIST_LENGTH] = self._bigModExp(self._modularAdd(_a, _b, _m), two, _m)
    aMinusB: uint256[M_LIST_LENGTH] = self._bigModExp(self._modularSub(_a, _b, _m), two, _m)
    return self._modularSub(aPlusB, aMinusB, _m)


# 4a = (a + a) + (a + a)
@public
@constant
def modularMulBy4(_a: uint256[M_LIST_LENGTH], _m: uint256[M_LIST_LENGTH]) -> uint256[M_LIST_LENGTH]:
    t: uint256[M_LIST_LENGTH] = self._modularAdd(_a, _a, _m)
    return self._modularAdd(t, t, _m)
