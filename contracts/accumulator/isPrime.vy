# @dev isPrime
# @author Nick Hyungsuk Kang (@hskang9)
# Prime Tester using Fermat's primality test where a=2


# this assumes that the number is less than 2 ** 64
@public
@constant
def _isPrime(_num: uint256) -> bool:
    assert _num < 2 ** 64
    if _num < 2:
        return False
    det: uint256 = 2<<(_num-2)
    if det % _num == 1:
        return True
    return False
