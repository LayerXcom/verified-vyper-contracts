Transfer: event({_from: indexed(address), _to: indexed(address), _value: uint256(wei)})
Approval: event({_owner: indexed(address), _spender: indexed(address), _value: uint256(wei)})

name: public(bytes32)
symbol: public(bytes32)
decimals: public(uint256)
balances: uint256(wei)[address]
allowances: (uint256(wei)[address])[address]
total_supply: uint256(wei)
minter: address

@public
def __init__(_name: bytes32, _symbol: bytes32, _decimals: uint256, _supply: uint256(wei)):
    _sender: address = msg.sender
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balances[_sender] = _supply
    self.total_supply = _supply
    self.minter = _sender
    log.Transfer(ZERO_ADDRESS, _sender, _supply)

@public
@constant
def totalSupply() -> uint256(wei):
    return self.total_supply

@public
@constant
def balanceOf(_owner : address) -> uint256(wei):
    return self.balances[_owner]

@public
def transfer(_to : address, _value : uint256(wei)) -> bool:
    _sender: address = msg.sender
    self.balances[_sender] = self.balances[_sender] - _value
    self.balances[_to] = self.balances[_to] + _value
    log.Transfer(_sender, _to, _value)
    return True

@public
def transferFrom(_from : address, _to : address, _value : uint256(wei)) -> bool:
    _sender: address = msg.sender
    allowance: uint256(wei) = self.allowances[_from][_sender]
    self.balances[_from] = self.balances[_from] - _value
    self.balances[_to] = self.balances[_to] + _value
    self.allowances[_from][_sender] = allowance - _value
    log.Transfer(_from, _to, _value)
    return True

@public
def approve(_spender : address, _value : uint256(wei)) -> bool:
    _sender: address = msg.sender
    self.allowances[_sender][_spender] = _value
    log.Approval(_sender, _spender, _value)
    return True

@public
@constant
def allowance(_owner : address, _spender : address) -> uint256(wei):
    return self.allowances[_owner][_spender]

@public
def mint(_to: address, _value: uint256(wei)):
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.total_supply = self.total_supply + _value
    self.balances[_to] = self.balances[_to] + _value
    log.Transfer(ZERO_ADDRESS, _to, _value)

@private
def _burn(_to: address, _value: uint256(wei)):
    assert _to != ZERO_ADDRESS
    self.total_supply = self.total_supply - _value
    self.balances[_to] = self.balances[_to] - _value
    log.Transfer(_to, ZERO_ADDRESS, _value)

@public
def burn(_value: uint256(wei)):
    self._burn(msg.sender, _value)

@public
def burnFrom(_to: address, _value: uint256(wei)):
    _sender: address = msg.sender
    self.allowances[_to][_sender] = self.allowances[_to][_sender] - _value
    self._burn(_to, _value)
