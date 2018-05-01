pragma solidity ^0.4.23;
import "../token/ERC20/ERC20.sol"; //Our token contract include all information about our token
import "../math/SafeMath.sol";//Smart contract for secure 256-bit protection
contract PreICOSale{
  ERC20 public token;
  address public wallet; // Token address information
  uint256 public rate;  // How many token units a buyer gets per wei, we will decide
  uint256 public weiRaised;
  event Released(uint256 amount);
  event Revoked();
  uint256 public cliff; // Maximum amount that can be purchased
  uint256 public start; // Start point at which the buying process begins
  uint256 public duration; // Progressive buying process
  bool public revocable;
  mapping (address => uint256) public released;
  mapping (address => bool) public revoked; // Determine refund process
 event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   function PreicoSale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    rate = _rate;
    wallet = _wallet;
    token = _token;
  }
  function () external payable { //User Interface
    buyTokens(msg.sender);
  }
    function TokenVesting(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);
    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }
  function release(ERC20 _token) public { //Start function of progressive token sale .
    uint256 unreleased = releasableAmount(token);
    require(unreleased > 0);
    released[token] = released[token].add(unreleased);
    token.buyTokens(beneficiary, unreleased);
    emit Released(unreleased);
  }
  function revoke(ERC20 _token) public  { // Cancel the progressive transaction process.
    require(revocable);
    require(!revoked[token]);
    uint256 balance = token.balanceOf(this);
    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);
    revoked[token] = true;
    token.buyTokens(owner, refund);
    emit Revoked();
  }
  function releasableAmount(ERC20Basic token) public view returns (uint256) { //Shows the amount of incomplete tokens in progressive transaction process.
    return vestedAmount(token).sub(released[token]);
  }
  function vestedAmount(ERC20Basic token) public view returns (uint256) {// Calculate the amount of completed tokens
  uint256 currentBalance = token.balanceOf(this);
  uint256 totalBalance = currentBalance.add(released[token]);
    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
  function buyTokens(address _beneficiary) public payable { //If users have enough tokens, this function make transaction
    uint256 weiAmount = msg.value;
   _preValidatePurchase(_beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount); // Calculate token amount to be created
    weiRaised = weiRaised.add(weiAmount);
    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase( //It shows how many token we will send
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
    _updatePurchasingState(_beneficiary, weiAmount); //Update to purchasing process in user interface
    _forwardFunds(); // Forward to purchased token to etherium wallet
    _postValidatePurchase(_beneficiary, weiAmount); // Carry out the payment
  }
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal { // This function controls user address information and how many tokens owned user
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {// It is optional function ,this function will use for refund
    // optional override }
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal { //Start the purchasing process in token contract
    _deliverTokens(_beneficiary, _tokenAmount);
  }
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {// Converts to purchased ether  to token
    return _weiAmount.mul(rate);
  }
  function _forwardFunds() internal { // How ETH is stored on purchases
    wallet.transfer(msg.value);
  }    
}