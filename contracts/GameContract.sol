pragma solidity ^0.4.18;


contract GameContract {
    address public owner;

    function GameContract() public {
        owner = tx.origin;
    }
}