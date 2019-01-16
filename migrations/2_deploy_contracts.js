// this is what separates the men from the boys


// Get all contract artifacts
const businessLogicContract = artifacts.require("BusinessLogicContract");
const dataLayerContract = artifacts.require("DataLayerContract");
const safeMath = artifacts.require("SafeMath");
const returnKeccakHash = artifacts.require("ReturnKeccakHash");

const fs = require("fs");
const path = require("path");
const tokenConfig = JSON.parse(fs.readFileSync(path.join(__dirname, '../token-config.json'), 'utf-8'));

module.exports = function(deployer, network, accounts){
    deployer.deploy(safeMath);
    deployer.link(safeMath, businessLogicContract);

    let helperInstance = null;
    let transactionCount = 0;

    let contractAdd1 = null;
    let contractAdd2 = null;

    let businessContractInstance = null;
    let dataContractInstance = null;
    
    deployer.deploy(returnKeccakHash)
    .then(function(instance){
        helperInstance = instance;
        return web3.eth.getTransactionCount(accounts[1]);
    })
    .then(function(n){
        transactionCount = n;
        //console.log(transactionCount);
        //console.log(transactionCount + 1);

        var hex = web3.utils.toHex(transactionCount);
        if(hex == 0x00)
            hex = 0x80;

        return helperInstance.keccakHash.call(accounts[1], hex);
    }).then(function(n){
        contractAdd1 = n;
        return helperInstance.keccakHash.call(accounts[1], web3.utils.toHex(transactionCount + 1));
    }).then(function(n){
        contractAdd2 = n;

        return deployer.deploy(dataLayerContract, contractAdd2, {from: accounts[1]});
    }).then(function(instance){
        dataContractInstance = instance;
        //console.log(dataContractInstance.address + " : " + contractAdd1);

        return deployer.deploy(businessLogicContract, tokenConfig.tokenName, tokenConfig.tokenDecimals, tokenConfig.tokenSymbol, tokenConfig.tokenTotalSupply, accounts[0], contractAdd1, {from: accounts[1]});
    }).then(function(instance){
        businessContractInstance = instance;

        //console.log(businessContractInstance.address + " : " + contractAdd2);
    });
}