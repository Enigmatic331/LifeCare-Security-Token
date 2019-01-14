pragma solidity ^0.5.0;

contract ReturnKeccakHash {
    function keccakHash(address _addr, uint8 nonce) public pure returns (address) {
        return bytes32toAddress(keccak256(abi.encodePacked(uint8(0xd6), uint8(0x94), _addr, nonce)));
    }
    
    function bytes32toAddress(bytes32 hash) internal pure returns (address addr) {
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }
}