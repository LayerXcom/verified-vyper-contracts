int128_data: int128
uint256_data: uint256

@public
def clearInt128Storage():
    clear(self.int128_data)

@public
def clearInt128Memory(_input: int128) -> int128:
    data: int128 = _input
    clear(data)
    return data

@public
def clearUInt256Storage():
    clear(self.uint256_data)

@public
def clearUInt256Memory(_input: uint256) -> uint256:
    data: uint256 = _input
    clear(data)
    return data
