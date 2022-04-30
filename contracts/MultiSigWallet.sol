// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MultiSigWallet {

  uint256 private required;
  uint256 private Id;

  mapping (address => bool) public _isOwner;
  mapping (address => mapping(uint256 => bool)) public _approved;
  mapping (uint256 => bool) public _executed;
  mapping (uint256 => bool) private _transactions;

  modifier onlyOwner() {
    require(_isOwner[msg.sender], "User is not an owner");
    _;
  }

  modifier notApproved(uint256 index) {
    require(_approved[msg.sender][index] == false, "Tx already approved by user");
    _;
  }

  modifier txExist(uint256 index) {
    require(_transactions[index] == true, "Tx does not exist");
    _;
  }

  modifier notExecuted(uint256 index) {
    require(_executed[index] == false, "Tx already executed");
    _;
  }

  event Submit(uint256 indexed Id, address indexed from, address indexed to, uint256 amount);
  event Approval(uint256 indexed Id, address indexed from);
  event Revoke(uint256 indexed Id, address indexed from);
  event Withdrawal(address indexed to, uint256 amount);

  struct Transaction {
    uint256 index;
    address from;
    address to;
    uint256 amount;
    uint256 approval;
  }

  Transaction[] public transactions;
  address[] public _Owners;

  constructor(uint256 _required) {
    _isOwner[msg.sender] = true;
    _Owners.push(msg.sender);
    required = _required;
  }

  function Deposit()
  public
  payable{

  }

  function submit(uint256 _amount, address _to)
  public
  onlyOwner{
    require(_amount <= address(this).balance, "invalid amount");
    Transaction memory transaction;
    transaction.index = Id;
    transaction.from = msg.sender;
    transaction.to = _to;
    transaction.amount = _amount;
    transaction.approval = 0;

    transactions.push(transaction);
    emit Submit(Id, msg.sender, _to, _amount);
    _transactions[Id] = true;
    Id++;
  }

  function approve(uint256 _index)
  public
  onlyOwner
  txExist(_index)
  notApproved(_index) {
    transactions[_index].approval++;
    _approved[msg.sender][_index] = true;
    emit Approval(_index, msg.sender);
  }

  function revoke(uint256 _index)
  public
  txExist(_index)
  notExecuted(_index) {
    transactions[_index].approval--;
    _approved[msg.sender][_index] = false;
    emit Revoke(_index, msg.sender);
  }

  function execute(uint256 _index)
  public
  txExist(_index)
  notExecuted(_index) {
    require(getApprovalCount(_index), "Approval not up to required");
    _withdraw(_index);
    _executed[_index] = true;
  }

  function _withdraw(uint256 _index)
  internal {
    uint256 amount = transactions[_index].amount;
    address to = transactions[_index].to;
    require(amount <= address(this).balance, "invalid amount");
    (bool success, ) = to.call{value: amount}(" ");
    require(success, "Withdrawal unsuccessful");
    emit Withdrawal(to, amount);
  }

  function addOwner(address _owner)
  public
  onlyOwner {
    _Owners.push(_owner);
    _isOwner[_owner] = true;
  }

  function removeOwner(address _owner, uint256 _index)
  public
  onlyOwner {
    require(_Owners.length > 1, "There must be atleast one owner");
    _isOwner[_owner] = false;

    for(uint256 i = _index; i < _Owners.length - 1; i++){
      _Owners[i] = _Owners[i+1];
      _Owners.pop();
    }
  }

  function getApprovalCount(uint256 _index) internal view returns (bool) {
    require(transactions[_index].approval >= required);
    return true;
  }

  receive() external payable {}
  fallback() external payable {}
}
