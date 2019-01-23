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

    // CHANGE THIS PARAMETER DURING DEPLOYMENT
    let contractOwner = accounts[1];
    let contractAdmin = accounts[0];

    if(network == "ropsten"){
        contractOwner = "0xE4A8E9a0fC38293191302fc5F373f25EAd4c5E04";
        contractAdmin = "0x15c0fA3a553F6DC1AF3F950565e5f4403aE62f72";
    }

    //console.log(network);
    //var acc = null;

    let helperInstance = null;
    let transactionCount = 0;

    let contractAdd1 = null;
    let contractAdd2 = null;

    let businessContractInstance = null;
    let dataContractInstance = null;
    
    // web3.eth.getAccounts().then(function(x){
    //     acc = x;
    //     console.log(acc);
    //     return deployer.deploy(returnKeccakHash);
    // })
    deployer.deploy(returnKeccakHash)
    .then(function(instance){
        helperInstance = instance;
        return web3.eth.getTransactionCount(contractOwner);
    })
    .then(function(n){
        transactionCount = n;
        //console.log(transactionCount);
        //console.log(transactionCount + 1);

        var hex = web3.utils.toHex(transactionCount);
        if(hex == 0x00)
            hex = 0x80;

        return helperInstance.keccakHash.call(contractOwner, hex);
    }).then(function(n){
        contractAdd1 = n;
        return helperInstance.keccakHash.call(contractOwner, web3.utils.toHex(transactionCount + 1));
    }).then(function(n){
        contractAdd2 = n;

        return deployer.deploy(dataLayerContract, contractAdd2, {from: contractOwner});
    }).then(function(instance){
        dataContractInstance = instance;
        console.log(dataContractInstance.address + " : " + contractAdd1);

        return deployer.deploy(businessLogicContract, tokenConfig.tokenName, tokenConfig.tokenDecimals, tokenConfig.tokenSymbol, contractAdmin, {from: contractOwner});
    }).then(function(instance){
        businessContractInstance = instance;

        console.log(businessContractInstance.address + " : " + contractAdd2);
        return businessContractInstance.firstTimeInit(tokenConfig.tokenTotalSupply, contractAdd1, {from: contractOwner});
    }).then(function(){
        console.log("Success!");
    });
}