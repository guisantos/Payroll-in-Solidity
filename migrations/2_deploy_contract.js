var owned = artifacts.require("./Owned.sol");
var payroll = artifacts.require("./Payroll.sol");

module.exports = function(deployer) {
    deployer.deploy(owned);
    deployer.deploy(payroll);
};