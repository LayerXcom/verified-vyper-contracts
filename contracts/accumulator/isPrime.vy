# @dev isPrime
# @author Nick Hyungsuk Kang (@hskang9)
# Prime Tester using Fermat's primality test where a=2

@private
@constant
def _compare(_a: uint256[8], _b: uint256[8]) -> int128:
    for i in range(M_LIST_LENGTH):
        if _a[i] > _b[i]:
            return 1
        elif _a[i] < _b[i]:
            return -1
    return 0

### BIG INTEGER ARITHMETIC FUNCTIONS ###

@private
@constant
def _convertUInt256ListToBytes(_inp: uint256[8]) -> bytes[256]:
    # FIXME: Make it more simple when conversion to bytes is supported:
    #        https://github.com/ethereum/vyper/issues/1093
    tmp: bytes32[8]
    for i in range(M_LIST_LENGTH):
        tmp[i] = convert(_inp[i], bytes32)
    return concat(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7])

@private
@constant
def _convertBytesArrayToUInt256List(_inp: bytes[256]) -> uint256[8]:
    out: uint256[8]
    for i in range(M_LIST_LENGTH):
        out[i] = convert(extract32(_inp, i * 32, type=bytes32), uint256)
    return out

@private
def _bigModExp(_base: uint256[8], _e: uint256[8], _m: uint256[8]) -> uint256[8]:
    base: bytes[256] = self._convertUInt256ListToBytes(_base)
    exponent: bytes[256] = self._convertUInt256ListToBytes(_e)
    modulus: bytes[256] = self._convertUInt256ListToBytes(_m)
    # ref. https://eips.ethereum.org/EIPS/eip-198
    # 864 = 32 * 3 + <length_of_BASE> + <length_of_EXPONENT> + <length_of_MODULUS>
    data: bytes[864] = concat(BASE_BYTE_COUNT_BYTES32, E_BYTE_COUNT_BYTES32, M_BYTE_COUNT_BYTES32,
                    base, exponent, modulus)
    # NOTE: raw_call doesn't support static call for now.
    res: bytes[256] = raw_call(PRECOMPILED_BIGMODEXP, data, outsize=256, gas=2000)
    return self._convertBytesArrayToUInt256List(res)

# this assumes that the number is less than 2 ** 64
@public
@constant
def _isPrime(_num: uint256) -> bool:
    assert _num < 2 ** 64
    if _num < 2:
        return False
    det: uint256[8] = _bigModExp(2, _num-1, _num)
    if self._compare(det, [0,0,0,0,0,0,0,1]) ==0:
        return True
    return False
