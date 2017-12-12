pragma solidity ^0.4.18;

contract Owned {

    address _owner;
    
    modifier onlyOwner() {
        if (msg.sender == _owner) {
            _;
        } else {
            revert();
        }
    }
    
    function Owned() public {
        _owner = msg.sender;
    }
}