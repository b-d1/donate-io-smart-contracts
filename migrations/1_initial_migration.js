var Migrations = artifacts.require("./Migrations.sol");

const contractOptions = {
    gasPrice: 1000000000,
    gas: 4500000
};


module.exports = function(deployer) {
  deployer.deploy(Migrations, contractOptions);
};
