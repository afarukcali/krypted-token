pragma solidity ^0.4.23;
import './ERC20Basic.sol';

import './Ownable.sol';
import "./ERC20.sol";   //Tokenımızın contractı
import "./SafeMath.sol"; //güvenli bir 256 bit koruma için kullanılan akıllı contract
contract PreicoSale{
using SafeMath for uint256;
    ERC20 public token;
  address public wallet; // transfer edilicek address
  uint256 public rate;  // alım oranı  kendimiz beliricez
  uint256 public weiRaised;
  // SÜREÇ İÇİNDE KADEMELİ SATIN ALMA OLAYI İÇİN
  event Released(uint256 amount);
  event Revoked();
  uint256 public cliff; // ALINABİLCEK UÇ SINIR
  uint256 public start; // BAŞLANGIÇ
  uint256 public duration; // ALIM SÜRESİ

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked; // GERİ ALIŞ İŞLEMİ

 event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
 
   function PreicoSale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    rate = _rate;
    wallet = _wallet;
    token = _token;
    
  }
// ----------------- KULLANICI TARAFI
  function () external payable { //ÖDENECEK TUTARI BELİRLİYECEK FONKSİYON KURALLARIMIZI BU KISIMDA BELİRLİYECEĞİZ

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
  function release(ERC20 _token) public { //KULLANCIYA TOKEN SATIŞINI BELİRLER

    uint256 unreleased = releasableAmount(token);
    require(unreleased > 0);
    released[token] = released[token].add(unreleased);
    token.buyTokens(beneficiary, unreleased);
    emit Released(unreleased);

  }
  function revoke(ERC20 _token) public  { // KULLANICININ SATIN ALMA OLAYININ İPTALİNİ SAĞLAR

    require(revocable);
    require(!revoked[token]);
    uint256 balance = token.balanceOf(this);
    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);
    revoked[token] = true;
    token.buyTokens(owner, refund);
    emit Revoked();
  }
  function releasableAmount(ERC20Basic token) public view returns (uint256) { // KULLANICININ ALDIĞI FAKAT HENÜZ GÖNDERİLMEMİŞ TOKEN MİKTARINI GÖSTERİR

    return vestedAmount(token).sub(released[token]);

  }

  function vestedAmount(ERC20Basic token) public view returns (uint256) {// KULLANICIYA GÖNDERİLMEMİŞ MİKTARI HESAPLAR

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
 
  function buyTokens(address _beneficiary) public payable { //EĞER TUTAR YETERLİYSE ALIM YAPABİLECEK ADDREES

    uint256 weiAmount = msg.value;

    _preValidatePurchase(_beneficiary, weiAmount);

    uint256 tokens = _getTokenAmount(weiAmount); // YOLLANICAK TOKEN MİKTARINI BELİLER

    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);

    emit TokenPurchase( //YAPILACAK TOKEN ÖDEMESİNİ GÖSTERİR

      msg.sender,

      _beneficiary,

      weiAmount,

      tokens

    );
    _updatePurchasingState(_beneficiary, weiAmount); //SATIN ALMA DURUMUNU KULLANICI TARAFINDA GÜNCELLER

    _forwardFunds(); // GÖNDERİLEN TOKEN MİKTARINI YÖNLENDİRİR

    _postValidatePurchase(_beneficiary, weiAmount); // ÖDEMEYİ GERÇEKLEŞTİRİR

  }

  // ------------- TOKEN TARAFI ----------------
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal { // KULLANICI ADRESİNİ VE TOKEN MİKTARINI KONTROL EDECEK FONKSİYON

    require(_beneficiary != address(0));

    require(_weiAmount != 0);

  }




  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {//İADE KOŞULLARINI GERÇEKLEŞTİREBİLCEĞİMİZ FONKSİYON
 // OLUMSUZ DURUMLARDA KED İADRESİNİ BİZ AKILLI KONTRACT ÜZERİNDEN YAPACAĞIZ
    // optional override

  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {

    token.transfer(_beneficiary, _tokenAmount);

  }
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal { //SATIN ALMA OLAYINI TOKEN TARAFINDA BAŞLATIR

    _deliverTokens(_beneficiary, _tokenAmount);

  }


  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {

    // optional override

  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {// ÖDENEN ETERİ TOKENA ÇEVİRİR

    return _weiAmount.mul(rate);

  }

  function _forwardFunds() internal { // ETH'IN ALIMLARDA NASIL SAKLANDIĞINI BELİRLER

    wallet.transfer(msg.value);

  }
    
}