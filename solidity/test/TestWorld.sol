
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/WorldContract.sol";

contract TestWorld {

    function isContract(address addr) returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function bytesToAddress (bytes32 b) constant returns (address) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            if(c >= 65 && c<= 90) {
                result = result * 16 + (c - 55);
            }
            if(c >= 97 && c<= 122) {
                result = result * 16 + (c - 87);
            }
        }
        return address(result);
    }

    function stringToBytes32(string memory source) returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
        result := mload(add(source, 32))
        }
    }

    function stringToAddress(string str) public returns (address) {
        return bytesToAddress(stringToBytes32(str));
    }

    function testCreateWorld() {
        WorldContract world = WorldContract(DeployedAddresses.WorldContract());
        Assert.equal(world.owner(), msg.sender, "Creator should be msg.sender");
    }
//
//    function testCreateIslands() {
//        WorldContract world = WorldContract(DeployedAddresses.WorldContract());
//        address created = world.createIsland(1, 2, 2, 4);
//        Island island = Island(created);
//
//        Assert.equal(island.oceanX(), 1, "Dimension x should be 1");
//        Assert.equal(island.oceanY(), 2, "Dimension y should be 2");
//    }

    function testAttack() {
        WorldContract world = WorldContract(DeployedAddresses.WorldContract());
        address attacking = world.createIsland(1, 1, 2, 4);
        address target = world.createIsland(1, 2, 4, 4);
        Island attackingIsland = Island(attacking);
        Island targetIsland = Island(target);

        Assert.equal(isContract(attacking), true, "Attacking island does not exist!");
        Assert.equal(isContract(target), true, "Target island does not exist!");

        Assert.equal(!world.isDead(attackingIsland.getArmy()) && !world.isDead(targetIsland.getArmy()), true, "Both armies must not be dead.");

        uint attackIndex = world.setAttackSuperuser(attacking, target, attackingIsland.getArmy(), now - 5 minutes);

        Assert.equal(world.somethingNew(msg.sender), true, "Nothing has changed!");
        Assert.equal(world.updateWorld(msg.sender), true, "Nothing was updated!");
        Assert.equal(world.isSunkenShip(attackIndex) || world.isDead(targetIsland.getArmy()), true, "One of the armies must die!");

        attackingIsland.kill();
        targetIsland.kill();
    }
}