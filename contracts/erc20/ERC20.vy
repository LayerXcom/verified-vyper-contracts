# @dev Implementation of ERC-20 token standard.
# @author Ryuya Nakamura (@nrryuya)

Transfer: event({_from: indexed(address), _to: indexed(address), _value: uint256})
Approval: event({_owner: indexed(address), _spender: indexed(address), _value: uint256})

name: public(bytes32)
symbol: public(bytes32)
decimals: public(uint256)
balances: map(address, uint256)
allowances: map(address, map(address, uint256))
total_supply: uint256
minter: address

@public
def __init__(_name: bytes32, _symbol: bytes32, _decimals: uint256, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    sender: address = msg.sender
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balances[sender] = init_supply
    self.total_supply = init_supply
    self.minter = sender
    log.Transfer(ZERO_ADDRESS, sender, init_supply)


# @dev Total number of tokens in existence.
@public
@constant
def totalSupply() -> uint256:
    return self.total_supply


# @dev Gets the balance of the specified address.
# @param _owner The address to query the balance of.
# @return An uint256 representing the amount owned by the passed address.
@public
@constant
def balanceOf(_owner : address) -> uint256:
    return self.balances[_owner]


# @dev Function to check the amount of tokens that an owner allowed to a spender.
# @param _owner The address which owns the funds.
# @param _spender The address which will spend the funds.
# @return An uint256 specifying the amount of tokens still available for the spender.
@public
@constant
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]


# @dev Transfer token for a specified address
# @param _to The address to transfer to.
# @param _value The amount to be transferred.
@public
def transfer(_to : address, _value : uint256) -> bool:
    _sender: address = msg.sender
    self.balances[_sender] = self.balances[_sender] - _value
    self.balances[_to] = self.balances[_to] + _value
    log.Transfer(_sender, _to, _value)
    return True


#  @dev Transfer tokens from one address to another.
#       Note that while this function emits an Approval event, this is not required as per the specification,
#       and other compliant implementations may not emit the event.
#  @param _from address The address which you want to send tokens from
#  @param _to address The address which you want to transfer to
#  @param _value uint256 the amount of tokens to be transferred
@public
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    _sender: address = msg.sender
    allowance: uint256 = self.allowances[_from][_sender]
    self.balances[_from] = self.balances[_from] - _value
    self.balances[_to] = self.balances[_to] + _value
    self.allowances[_from][_sender] = allowance - _value
    log.Transfer(_from, _to, _value)
    return True


# @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
#      Beware that changing an allowance with this method brings the risk that someone may use both the old
#      and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
#      race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
#      https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
# @param _spender The address which will spend the funds.
# @param _value The amount of tokens to be spent.
@public
def approve(_spender : address, _value : uint256) -> bool:
    _sender: address = msg.sender
    self.allowances[_sender][_spender] = _value
    log.Approval(_sender, _spender, _value)
    return True
