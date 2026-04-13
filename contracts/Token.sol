pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _dividends;
  address[] private _holderAddresses;
  mapping(address => uint256) private _holderIndex;

  function _updateHolderList(address account) private {
    if (balanceOf[account] > 0 && _holderIndex[account] == 0) {
      _holderAddresses.push(account);
      _holderIndex[account] = _holderAddresses.length;
    } else if (balanceOf[account] == 0 && _holderIndex[account] != 0) {
      uint256 idx = _holderIndex[account];
      uint256 lastIdx = _holderAddresses.length;
      if (idx != lastIdx) {
        address lastAddr = _holderAddresses[lastIdx - 1];
        _holderAddresses[idx - 1] = lastAddr;
        _holderIndex[lastAddr] = idx;
      }
      _holderAddresses.pop();
      delete _holderIndex[account];
    }
  }

  // IERC20

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    require(balanceOf[msg.sender] >= value);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    _updateHolderList(msg.sender);
    _updateHolderList(to);
    return true;
  }

  function approve(address spender, uint256 value) external override returns (bool) {
    _allowances[msg.sender][spender] = value;
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(balanceOf[from] >= value);
    require(_allowances[from][msg.sender] >= value);
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    _updateHolderList(from);
    _updateHolderList(to);
    return true;
  }

  // IMintableToken

  function mint() external payable override {
    require(msg.value > 0);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
    totalSupply = totalSupply.add(msg.value);
    _updateHolderList(msg.sender);
  }

  function burn(address payable dest) external override {
    uint256 amount = balanceOf[msg.sender];
    balanceOf[msg.sender] = 0;
    totalSupply = totalSupply.sub(amount);
    _updateHolderList(msg.sender);
    dest.transfer(amount);
  }

  // IDividends

  function getNumTokenHolders() external view override returns (uint256) {
    return _holderAddresses.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
    if (index == 0 || index > _holderAddresses.length) {
      return address(0);
    }
    return _holderAddresses[index - 1];
  }

  function recordDividend() external payable override {
    require(msg.value > 0);
    for (uint256 i = 0; i < _holderAddresses.length; i++) {
      address holder = _holderAddresses[i];
      uint256 share = msg.value.mul(balanceOf[holder]).div(totalSupply);
      _dividends[holder] = _dividends[holder].add(share);
    }
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
    return _dividends[payee];
  }

  function withdrawDividend(address payable dest) external override {
    uint256 amount = _dividends[msg.sender];
    _dividends[msg.sender] = 0;
    dest.transfer(amount);
  }
}
