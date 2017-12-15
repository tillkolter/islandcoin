pragma solidity ^0.4.18;


import './PlayerContract.sol';


contract StoneThrower {
    uint8 offense = 10;

    uint8 defense = 10;
}


contract Island {

    uint[1] army;

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

    //    Army army;

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

        army = [uint(10)];

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


    function getArmy() public constant returns (uint[1]) {
        return army;
    }

    function setArmy(uint[1] _army) requireWorldOwner public returns (bool) {
        army = _army;
        return true;
    }

    function getTechLevel(WorldContract.ResourceType resourceType) public constant returns (uint8) {
        return techLevels[keccak256(resourceType)];
    }

    function isArmed() private constant returns (bool) {
        return army[0] > 0;
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

    function attack(address targetIsland, uint[1] army) {
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
    address defender;
    uint arrivalTime;
    uint index;
    uint[1] army;
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

    function getETA(uint[1] army) public constant returns (uint) {
        return now + 5 minutes;
        // + 5 minutes;
    }

    function somethingNew(address user) public constant returns (bool) {
        for (uint i = 0; i < attacksPerUser[user].length; i++) {
            if (attacksIndex[attacksPerUser[user][i].index].arrivalTime < now) {
                return true;
            }
        }
        return attacks[user].length > 0;
    }

    function isDead(uint[1] army) public constant returns (bool) {
        return army[0] < 1;
    }

    function isContract(address addr) returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }

    function fight(address attacker, address defender, uint[1] army) public returns (uint[1]) {
        require(isContract(defender));
        Island defendingIsland = Island(defender);
        uint[1] memory defArmy = defendingIsland.getArmy();
        while (!isDead(army) && !isDead(defArmy)) {
            uint randomDefense = uint(keccak256(block.timestamp)) % 10 + 1;
            uint randomAttack = uint(keccak256(block.timestamp)) % 10 + 1;
            if (randomAttack >= defArmy[0]) {
                defArmy[0] = 0;
            } else {
                defArmy[0] -= randomAttack;
            }
            if (randomDefense >= defArmy[0]) {
                army[0] = 0;
            } else {
                army[0] -= randomDefense;
            }
        }
        defendingIsland.setArmy(defArmy);
        return army;
    }

    function updateWorld(address user) public returns (bool) {
        if (somethingNew(user)) {
            for (uint i = 0; i < attacksPerUser[user].length; i++) {
                attacksPerUser[user][i].army = fight(
                    attacksIndex[attacksPerUser[user][i].index].attacker,
                    attacksIndex[attacksPerUser[user][i].index].defender,
                    attacksIndex[attacksPerUser[user][i].index].army
                );
                attacksIndex[attacksPerUser[user][i].index].army = attacksPerUser[user][i].army;
            }
//            for (uint j = 0; j < defends[user].length; j++) {
//                if (defends[user][i].arrivalTime < now) {
//                    fight(user, defends[user][i].army, defends[user][i].victim);
//                }
//            }
            return true;
        }
        return false;
    }

    function setAttackSuperuser(address attacker, address defender, uint[1] army, uint eta) public onlyOwner returns (uint) {
        uint attackIndex = setAttack(attacker, defender, army);
        attacksIndex[attackIndex].arrivalTime = eta;
        return attackIndex;
    }

    function setAttack(address attacker, address defender, uint[1] army) public returns (uint) {
        uint arrivalTime = getETA(army);
        Attack attack;
        attack.attacker = attacker;
        attack.defender = defender;
        attack.arrivalTime = arrivalTime;
        attack.index = attacksIndex.length;
        attack.army = army;
        attacksIndex.push(attack);
        attacksPerUser[Island(attacker).owner()].push(attack);
        attacks[attacker].push(attack);
        defends[defender].push(attack);
        return attack.index;
    }

    function getAttacks(address island) public constant returns (Attack[]){
        require(tx.origin == Island(island).owner());
        return attacks[island];
    }

    function isSunkenShip(uint attackIndex) public constant returns (bool) {
        return isDead(attacksIndex[attackIndex].army);
    }

    function kill() public onlyOwner view {
        selfdestruct(owner);
    }

}