pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract ERC20 {
    function balanceOf(address nonpayable) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFor(address, address, uint256) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ShareholderContract {
	function getShareholderBalance(address _address) public view returns (uint256);
	function setShareholderBalance(address _address, uint256 _value) public returns (uint256);
	function getShareholderUID(address _address) public returns (bytes32);
	function setShareholderUID(address _address, bytes32 _uid) public returns (bool);
	function setTotalSupply(uint256 _amount) public returns (bool);
	function getTotalSupply() public view returns (uint256);
}


contract Owned {
    address public owner;
	address public administrator;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier ownerOrAdministrator {
		require(msg.sender == owner || msg.sender == administrator);
		_;
	}
	
    // allow transfer of administrator to another address
    function transferAdministrator(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        administrator = newAdmin;
    }
}

contract transferContract is ERC20 {
    using SafeMath for uint256;

    ShareholderContract public dL;
	address public datalayer;

    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= dL.getShareholderBalance(msg.sender));
        
        dL.setShareholderBalance(msg.sender, dL.getShareholderBalance(msg.sender).sub(_value));
        dL.setShareholderBalance(_to, dL.getShareholderBalance(_to).add(_value));
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFor(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= dL.getShareholderBalance(_from));
        
        dL.setShareholderBalance(_from, dL.getShareholderBalance(_from).sub(_value));
        dL.setShareholderBalance(_to, dL.getShareholderBalance(_to).add(_value));
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return dL.getShareholderBalance(_owner);
    }
}


//token contract
contract BusinessLayer is Owned, transferContract {
    
    event Burn(address indexed burner, uint256 value);
    
    /* Public variables of the token */
    string public name;                   
    uint8 public decimals;                
    string public symbol;    
    bool public publicTransfers;


    constructor(string memory _name, uint8 _decimals, string memory _symbol, uint256 _ttlSupply, address _administrator, address _datalayer) public {		
        // provide contract name, decimals and symbol of share
        name = _name;                         
        decimals = _decimals; 
        symbol = _symbol;

        // ownership and administrator
        owner = msg.sender;
        require(_administrator != address(0));
        administrator = _administrator;

        // connect to data layer
        require(connectToDataLayer(_datalayer));

        // set total supply of shares
        dL.setTotalSupply(_ttlSupply * 10 ** uint256(decimals));

        //transfer all to owner
        dL.setShareholderBalance(msg.sender, _ttlSupply * 10 ** uint256(decimals));
        emit Transfer(address(0x0), msg.sender, _ttlSupply * 10 ** uint256(decimals));
    }
	
    function connectToDataLayer(address _datalayer) public onlyOwner returns (bool) {
        uint codeLength;
        /**
            * Data layer to connect to needs to be a contract - Checks for code existence.
            */
        assembly {
            codeLength := extcodesize(_datalayer)
        }
        require(codeLength > 0);
        datalayer = _datalayer;


        // initialise datalayer contract
        dL = ShareholderContract(datalayer);
        return true;
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(publicTransfers == true || msg.sender == owner || msg.sender == administrator);
        return super.transfer(_to, _value);
    } 
    
    function transferFor(address _from, address _to, uint256 _value) public ownerOrAdministrator returns (bool) {
        return super.transferFor(_from, _to, _value);
    }
    
    function allowPublicTransfers(bool _allow) public onlyOwner {
        publicTransfers = _allow;
    }
    

    /**
	 * returns total number of shares
     */    
    function totalSupply() public view returns (uint256) {
        return dL.getTotalSupply();
    }


// pending implementation
//     /**
// 	 * can be used as part of redemption
// 	 * burns shares collected to this account
// 	 */
//     function burn(uint256 _value) public ownerOrAdministrator {
        
//     }
    
    
//     /**
// 	 * can be used as part of a share split
// 	 * increases total supply of shares, and subsequently assigns to owner.
// 	 * From there, shares could be distributed according to agreed share split rules.
// 	 */
//     function mint(uint256 _value) public ownerOrAdministrator {
        
//     }
}
