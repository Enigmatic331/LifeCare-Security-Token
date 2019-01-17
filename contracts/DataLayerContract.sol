pragma solidity ^0.5.0;

contract Shareholders {
    uint256 public totalShares;
    mapping (address => Shareholder) internal shareholderDetail;
	
    struct Shareholder {
        bytes32 uid;
        uint256 amount;
    }

    function getShareholderBalance(address _address) public returns (uint256);
    function setShareholderBalance(address _address, uint256 _value) public returns (bool);
    function getShareholderUID(address _address) public returns (bytes32);
    function setShareholderUID(address _address, bytes32 _uid) public returns (bool);

    function getTotalSupply() public view returns (uint256);
    function adjustTotalSupply(uint256 _amount, bool add) public returns (bool);
}

contract DataOwned {
    address public owner;
    address public approvedBusinessLayer;
    
    modifier onlyCallableByBusinessLayer {
        require(approvedBusinessLayer == msg.sender);
        _;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
}

contract DataLayerContract is Shareholders, DataOwned {
    bool hadSetSupply = false;
    
    constructor(address _pregeneratedBusinessLogicAddress) public {
        // set Owner
        owner = msg.sender;
        approvedBusinessLayer = _pregeneratedBusinessLogicAddress;
    }
    
    // setters
    function setShareholderBalance(address _address, uint256 _value) public onlyCallableByBusinessLayer returns (bool) {
        shareholderDetail[_address].amount = _value;
        return true;
    }

    function setShareholderUID(address _address, bytes32 _value) public onlyCallableByBusinessLayer returns (bool) {
        shareholderDetail[_address].uid = _value;
        return true;
    }
    
    function initTotalSupply(uint256 _amount) public onlyCallableByBusinessLayer returns (bool) {
        // can only be done once - done during constructor initialisation of business layer
        // subsequent change in supply needs to be minted or burnt, even if business layer changes
        require(hadSetSupply == false);
        totalShares = _amount;
        hadSetSupply = true;
        return true;
    }

    function adjustTotalSupply(uint256 _amount, bool add) public onlyCallableByBusinessLayer returns (bool) {
        require(hadSetSupply == true);
        if (add == true) {
            // prevent overflow
            require(totalShares + _amount > totalShares);
            totalShares = totalShares + _amount;
        } else {
            // prevent underflow
            require(_amount <= totalShares);
            totalShares = totalShares - _amount;
        }
        return true;
    }
    
    function connectToBusinessLayer(address _contract) public onlyOwner returns (bool) {
        approvedBusinessLayer = _contract;
        return true;
    }
    
    
    
    // getters
    function getShareholderBalance(address _address) public returns (uint256) {
        return shareholderDetail[_address].amount;
    }
    
    function getShareholderUID(address _address) public returns (bytes32) {
        return shareholderDetail[_address].uid;
    }
    
    function getTotalSupply() public view returns (uint256) {
        return totalShares;
    }
}