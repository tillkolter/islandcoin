pragma solidity ^0.4.18;

import './PlayerContract.sol';

contract StoneThrower {
    uint8 offense = 10;

    uint8 defense = 10;
}


contract Island {

    // Defines the army
    struct Army {
    uint stonethrowers;
    }

    struct Transfer {
    WorldContract.ResourceType resourceType;
    uint amount;
    uint arrival;
    }

    Transfer[] incomingTransfers;
    Transfer[] outgoingTransfers;

    enum ResearchType {Sail}

    address public owner;

    string name;

    WorldContract.MapPosition position;

    Army army;

    address world;

    mapping (bytes32 => uint8) techLevels;

    function Island(uint8 oceanX, uint8 oceanY, uint8 positionX, uint8 positionY, address _world) public {
        require(WorldContract(_world).owner() == msg.sender);
        owner = msg.sender;
        world = _world;

        position.x = oceanX;
        position.y = oceanY;
        position.x = positionX;
        position.y = positionY;
    }

    function getArmy() public constant returns (uint) {
        requirePermission();
        return army.stonethrowers;
    }

    function getTechLevel(WorldContract.ResourceType resourceType) public constant returns (uint8) {
        return techLevels[sha3(resourceType)];
    }

    function isArmed() private constant returns (bool) {
        return army.stonethrowers > 0;
    }

    function isEmpty() public constant returns (bool) {
        return WorldContract(world).owner() == owner;
    }

    function requirePermission() private {
        require(msg.sender == owner || msg.sender == WorldContract(world).owner());
    }

    function hasArrivals() public constant returns (bool) {
        requirePermission();
        for (uint i = 0; i < incomingTransfers.length; i++) {
            if (incomingTransfers[i].arrival < now) {
                return true;
            }
        }
        return false;
    }

    function transferResource(WorldContract.ResourceType resourceType, uint amount, uint arrivalTime) public returns (bool) {
        requirePermission();
        Transfer t;
        t.amount = amount;
        t.resourceType = resourceType;
        t.arrival = arrivalTime;
        incomingTransfers.push(t);
        return true;
    }

}


contract WorldContract is GameContract {

    enum ResourceType {Gold, Stone, Lumber, StoneThrower, Spearfighter, Archer, Catapult}

    struct IslandAddress {
    address id;
    uint index;
    bytes32 positionHash;
    }

    // Defines a position inside the world map
    struct MapPosition {
    uint8 ocean_x;
    uint8 ocean_y;
    uint8 x;
    uint8 y;
    bytes32 hash;
    }

    // Creator/Superuser of a world
    address public owner;

    // Players
    address players;

    mapping (address => address[]) playerIslands;

    mapping (address => IslandAddress) islands;
    mapping (bytes32 => IslandAddress) islandsPositions;

    IslandAddress[] islandIndex;

    // world dimension x
    uint8 x;
    // world dimension y
    uint8 y;


    function WorldContract(uint8 _x, uint8 _y) public {
        owner = msg.sender;
        x = _x;
        y = _y;

        // create a new players contract
        players = new PlayerContract(this);
    }

    function isFree(uint8 oceanX, uint8 oceanY, uint8 positionX, uint8 positionY) private constant returns (bool) {
        require(oceanX <= x && oceanY <= y);
        if (islandIndex.length == 0) return true;
        bytes32 positionHash = keccak256(oceanX, oceanY, positionX, positionY, owner);
        return islandIndex[islandsPositions[positionHash].index].positionHash != positionHash;
    }

    function isIsland(address islandAddress) public constant returns (bool) {
        if (islandIndex.length == 0) return false;
        return islandIndex[islands[islandAddress].index].id == islandAddress;
    }

    function createIsland(uint8 oceanX, uint8 oceanY, uint8 positionX, uint8 positionY) public returns (bool){
        bytes32 positionHash = sha3(oceanX, oceanY, positionX, positionY, owner);
        require(isFree(oceanX, oceanY, positionX, positionY));

        address island = new Island(oceanX, oceanY, positionX, positionY, owner);

        islandsPositions[positionHash].id = island;
        islandsPositions[positionHash].index = islandIndex.push(islandsPositions[positionHash]);

        return true;
    }

    function getTravelTime(address _sourceIsland, address _targetIsland) public constant returns (uint) {
        require(isIsland(_sourceIsland));
        require(isIsland(_targetIsland));

        Island sourceIsland = Island(_sourceIsland);
        require(msg.sender == sourceIsland.owner() || msg.sender == owner);
        // TODO: calculate travel time depending on tech level and boat type
        // uint level = sourceIsland.getTechLevel(Island.ResearchType.Sail);
        return 5 minutes;
    }

    function createTransferOrder(ResourceType resourceType, uint amount, address sourceIsland, address targetIsland) public returns (bool) {
        require(isIsland(targetIsland));
        require(amount > 0);
        Island island = Island(targetIsland);
        if (!isIsland(targetIsland) && msg.sender == owner) {
            require(sourceIsland == owner);
            island.transferResource(resourceType, amount, now);
        }
        else {
            uint travelTime = getTravelTime(sourceIsland, targetIsland);
            island.transferResource(resourceType, amount, now + travelTime);
        }
    }
//
//    function getArmy(address _player) public constant returns (uint) {
//        require(msg.sender == owner || msg.sender == _player);
//        uint stonethrowers = 0;
//        uint player = PlayerContract(players).players[_player];
//        for (uint i = 0; i < player.islands.length; i++) {
//            Island island = player.islands[i];
//            stonethrowers += island.army.stonethrowers;
//        }
//        return stonethrowers;
//    }

    function kill() public {
        require(msg.sender == owner);
    }

}