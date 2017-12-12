pragma solidity ^0.4.18;

import './GameContract.sol';

contract PlayerContract {

    // Represents a player of the game
    struct Player {
    // username of the player
    string username;
    // public key of the player
    address identity;
    }

    address game;

    mapping (address => Player) public players;
    Player[] playerIndex;

    function PlayerContract(address _game) public {
        game = _game;
    }

    function kill() public {
        require(GameContract(game).owner() == msg.sender);
    }
}
