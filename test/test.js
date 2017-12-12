var payroll = artifacts.require("./Payroll.sol");

contract(payroll, function(){

    it('Shoukd be possible to add employee?', function() {
        var contractInstance;
        return payroll.deployed().then(function(instance) {
            contractInstance = instance;
            return contractInstance.addEmployee("0x627306090abaB3A6e1400e9345bC60c78a8BEf57", ['0xf17f52151EbEF6C7334FAD080c5704D77216b732'], 50000);
        });
    });
})