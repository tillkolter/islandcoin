pragma solidity ^0.4.18;

import './PlayerContract.sol';

contract StoneThrower {
    uint8 offense = 10;

    uint8 defense = 10;
}
//
//contract Attack {
//    address attacker;
//    address victim;
//    uint arrivalTime;
//    uint index;
//    Island.Army army;
//
//    function Attack(address _attacker, address _victim, uint _arrivalTime, uint _index, Island.Army _army) {
//        attacker = _attacker;
//        victim = _victim;
//        arrivalTime = _arrivalTime;
//        index = _index;
//        army = _army;
//    }
//}


contract Island {

    // Defines the army
    struct Army {
    uint stonethrowers;
    }

    modifier requireIslandOwner {
        require(msg.sender == owner || msg.sender == WorldContract(world).owner());
        _;
    }

    modifier requireIslandOwnerOrAttacked {
        require(tx.origin == owner
            || false
        );
        _;
    }

    modifier requireWorldOwner {
        require(WorldContract(world).owner() == tx.origin);
        _;
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

    WorldContract.MapPosition public position;

    Army army;

    address world;
    uint public oceanX;
    uint public oceanY;

    mapping (bytes32 => uint8) techLevels;

    function Island(uint _oceanX, uint _oceanY, uint8 positionX, uint8 positionY, address _world) public {
        require(WorldContract(_world).owner() == tx.origin);
        owner = tx.origin;
        world = _world;

        oceanX = _oceanX;
        oceanY = _oceanY;

        army.stonethrowers = 10;

//        position.x = _oceanX;
//        position.y = _oceanY;
//        position.xDimension = positionX;
//        position.yDimension = positionY;
    }

    function getSerialized()
    public
    constant
    returns (uint, uint){
        return (position.x, position.y);
    }


    function getArmy() requireIslandOwnerOrAttacked public constant returns (Army) {
        return army;
    }

    function getTechLevel(WorldContract.ResourceType resourceType) public constant returns (uint8) {
        return techLevels[keccak256(resourceType)];
    }

    function isArmed() private constant returns (bool) {
        return army.stonethrowers > 0;
    }

    function isEmpty() public constant returns (bool) {
        return WorldContract(world).owner() == owner;
    }

    mapping (address => WorldContract.Attack) attacks;
    function isAttacked(address defender) public constant returns (bool) {
        return attacks[defender].victim == defender;
    }

    function hasArrivals() requireIslandOwner public constant returns (bool) {
        for (uint i = 0; i < incomingTransfers.length; i++) {
            if (incomingTransfers[i].arrival < now) {
                return true;
            }
        }
        return false;
    }

    function transferResource(WorldContract.ResourceType resourceType, uint amount, uint arrivalTime) requireIslandOwner public returns (bool) {
        Transfer memory t;
        t.amount = amount;
        t.resourceType = resourceType;
        t.arrival = arrivalTime;
        incomingTransfers.push(t);
        return true;
    }

    function attack(address targetIsland, Army army) {
        WorldContract worldInstance = WorldContract(world);
        worldInstance.setAttack(this, targetIsland, army);
    }

    function kill() public requireWorldOwner {
        selfdestruct(WorldContract(world).owner());
    }

//    function getAttacks()
//    public
//    constant
//    returns (WorldContract.Attack[]) {
//        require(tx.origin == owner || tx.origin == WorldContract(world).owner());
//        return WorldContract(world).getAttacks(this);
//    }

}


contract WorldContract is GameContract {

    modifier onlyOwner {
        require(tx.origin == owner);
        _;
    }

    enum ResourceType {StoneThrower}

    struct IslandAddress {
    address id;
    uint index;
    bytes32 positionHash;
    }

    // Defines a position inside the world map
    struct MapPosition {
    uint8 xDimension;
    uint8 yDimension;
    uint x;
    uint y;
    bytes32 hash;
    }


    struct Attack {
    address attacker;
    address victim;
    uint arrivalTime;
    uint index;
    Island.Army army;
    }

    Attack[] attacksIndex;
    mapping (address => Attack[]) attacksPerUser;
    mapping (address => Attack[]) attacks;

    Attack[] defendsIndex;
    mapping (address => Attack[]) defends;

    // Creator/Superuser of a world
    address public owner;

    // Players
    address players;

    mapping (address => address[]) playerIslands;

    mapping (address => IslandAddress) islands;
    mapping (bytes32 => IslandAddress) islandsPositions;

    IslandAddress[] islandIndex;

    // world dimension x
    uint public xDimension;
    // world dimension y
    uint public yDimension;

    function WorldContract(uint _x, uint _y) public {
        owner = tx.origin;
        xDimension = _x;
        yDimension = _y;

        // create a new players contract
        players = new PlayerContract(this);
    }

    function isFree(uint oceanX, uint oceanY, uint8 positionX, uint8 positionY) private constant returns (bool) {
//        return true;
//        require(oceanX <= xDimension && oceanY <= yDimension);
        if (islandIndex.length == 0) return true;
        bytes32 positionHash = keccak256(oceanX, oceanY, positionX, positionY, owner);
        return islandIndex[islandsPositions[positionHash].index].positionHash != positionHash;
    }

    function isIsland(address islandAddress) public constant returns (bool) {
        if (islandIndex.length == 0) return false;
        return islandIndex[islands[islandAddress].index].id == islandAddress;
    }

    function createIsland(uint oceanX, uint oceanY, uint8 positionX, uint8 positionY) public returns (address){
        require(oceanX <= xDimension);
        bytes32 positionHash = keccak256(oceanX, oceanY, positionX, positionY, owner);
        require(isFree(oceanX, oceanY, positionX, positionY));

        address island = new Island(oceanX, oceanY, positionX, positionY, this);
        islandsPositions[positionHash].id = island;
        islandsPositions[positionHash].index = islandIndex.push(islandsPositions[positionHash]);

        return island;
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

    function getETA(Island.Army army) public constant returns (uint) {
        return now + 5 minutes;  // + 5 minutes;
    }

    function somethingNew(address user) public constant returns (bool) {
        for (uint i = 0; i < attacksPerUser[user].length; i++) {
            if (attacksPerUser[user][i].arrivalTime < now) {
                return true;
            }
        }
        return attacks[user].length > 0;
    }

    function isDead(Island.Army army) public constant returns (bool) {
        return army.stonethrowers < 1;
    }

    function fight(address attacker, Island.Army army, address defender) public returns (bool) {
        Island defendingIsland = Island(defender);
        Island.Army memory defArmy = defendingIsland.getArmy();
        while (!isDead(army) && !isDead(defArmy)) {
            uint randomDefense = uint(keccak256(block.timestamp)) % 10 + 1;
            uint randomAttack = uint(keccak256(block.timestamp)) % 10 + 1;
            defArmy.stonethrowers - randomAttack;
            army.stonethrowers - randomDefense;
        }
        return isDead(defArmy);
    }

    function updateWorld(address user) public returns (bool) {
        if (somethingNew(user)) {
            for (uint i = 0; i < attacks[user].length; i++) {
                if (attacks[user][i].arrivalTime < now) {
                    fight(attacks[user][i].attacker, attacks[user][i].army, user);

                }
            }
            for (uint j = 0; j < defends[user].length; j++) {
                if (defends[user][i].arrivalTime < now) {
                    fight(user, defends[user][i].army, defends[user][i].victim);
                }
            }
            return true;
        }
        return false;
    }

    function setAttack(address attacker, address victim, Island.Army army, uint eta) public onlyOwner returns (bool) {
        Attack attack;
        attack.attacker = attacker;
        attack.victim = victim;
        attack.arrivalTime = eta;
        attack.index = attacksIndex.length;
        attack.army = army;
        attacksIndex.push(attack);
        attacksPerUser[Island(attacker).owner()].push(attack);
        attacks[attacker].push(attack);
        defends[victim].push(attack);
        return true;
    }

    function setAttack(address attacker, address victim, Island.Army army) public returns (bool) {
        uint arrivalTime = getETA(army);
        Attack attack;
        attack.attacker = attacker;
        attack.victim = victim;
        attack.arrivalTime = arrivalTime;
        attack.index = attacksIndex.length;
        attack.army = army;
        attacksIndex.push(attack);
        attacksPerUser[Island(attacker).owner()].push(attack);
        attacks[attacker].push(attack);
        defends[victim].push(attack);
        return true;
    }

    function getAttacks(address island) public constant returns (Attack[]){
        require(tx.origin == Island(island).owner());
//        Attack[] myArray =
        return attacks[island];
    }

    function kill() public view {
        require(msg.sender == owner);
    }

}