const BusinessLogicContract = artifacts.require("BusinessLogicContract");
const BigNumber = require("bignumber.js");

contract("Business Logic Contract", async(accounts) => {
    it('Test transfer', async() => {
        // Remember, account 1 is the administrator account for the token.
        // Account 2 is the owner of the token contract, subsequently, he is also the owner of all the tokens pregenerated.
        let ownerAccount = accounts[1];
        let adminAccount = accounts[0];
        let tokenContract = await BusinessLogicContract.deployed();

        const amountToTransfer = (new BigNumber(500)).times((new BigNumber(10).pow(new BigNumber(18))));
        const smallerAmountToTransfer = (new BigNumber(100)).times((new BigNumber(10).pow(new BigNumber(18))));
        const smallestAmountToTransfer = (new BigNumber(5)).times((new BigNumber(10).pow(new BigNumber(18))));

        // transfer using owner for self.
        await tokenContract.transfer(accounts[2], web3.utils.toBN(amountToTransfer), {from: ownerAccount});
        let balanceAcc2 = await tokenContract.balanceOf.call(accounts[2]);
        //console.log(balanceAcc2.toString());
        assert.strictEqual((new BigNumber(balanceAcc2.toString())).toString(), amountToTransfer.toString(), "1st transfer mistmatch");

        // transfer using admin for others.
        await tokenContract.transferFor(accounts[1], accounts[2], web3.utils.toBN(amountToTransfer), {from: adminAccount});
        balanceAcc2 = await tokenContract.balanceOf.call(accounts[2]);
        assert.strictEqual(new BigNumber(balanceAcc2.toString()).toString(), amountToTransfer.plus(amountToTransfer).toString(), "2nd transfer mistmatch");

        // transfer using anyuser (fail).
        let hasError = false;

        try{
            await tokenContract.transfer(accounts[3], web3.utils.toBN(smallerAmountToTransfer), {from: accounts[2]});
        }
        catch(e){
            hasError = true;
        }
        assert.strictEqual(hasError, true, "No error detected for public transfer not allowed.");

        // allow public transfer. transfer using anyuser (pass).
        hasError = false;
        await tokenContract.allowPublicTransfers(true, {from: ownerAccount});

        try{
            await tokenContract.transfer(accounts[3], web3.utils.toBN(smallerAmountToTransfer), {from: accounts[2]});
        }
        catch(e){
            hasError = true;
        }

        assert.strictEqual(hasError, false, "Error detected for public transfer allowed.");
        balanceAcc2 = await tokenContract.balanceOf.call(accounts[3]);
        assert.strictEqual(new BigNumber(balanceAcc2.toString()).toString(), smallerAmountToTransfer.toString(), "3rd transfer mistmatch");
    });
});

