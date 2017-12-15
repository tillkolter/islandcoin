var WorldContract = artifacts.require("./WorldContract.sol");
var GameContract = artifacts.require("./GameContract.sol");
var PlayerContract = artifacts.require("./PlayerContract.sol");

module.exports = function(deployer) {
  deployer.deploy(GameContract);
  deployer.deploy(PlayerContract);
  deployer.deploy(WorldContract, 1, 2);

  deployer.link(WorldContract, GameContract);
  deployer.link(WorldContract, PlayerContract);
  deployer.link(PlayerContract, WorldContract);
};
