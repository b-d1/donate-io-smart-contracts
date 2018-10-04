let account0 = web3.eth.accounts[0];
let account1 = web3.eth.accounts[1];
let account2 = web3.eth.accounts[2];

async function contractWork() {
    let DCI;
    await DonationCampaigns.deployed().then(inst => {
        DCI = inst;
        return Promise.resolve(true);
    });

    await DCI.newCampaign(web3.toWei(10, "ether", {from: account1, gasPrice: 21000})).then(result => {
        console.log("RESULT", result);

        for(let i = 0; i < result.logs.length; i++) {
            let log = result.logs[i];

            console.log("LOG", log);

        }
        return Promise.resolve(true);
    });

}

contractWork();

DonationCampaignsTime.deployed().then(inst => { DCTI = inst })
DCTI.newCampaign(web3.toWei(10, "ether"), 1534495200, {from: account1, gasPrice:21000})
DCTI.donate(0, {from: account2, gasPrice:21000, value: web3.toWei(6, "ether")}).then(ret => {console.log(ret.logs[0].event, ret.logs[0].args); console.log(ret.logs[1].event, ret.logs[1].args)})
DCTI.donate(0, {from: account2, gasPrice:21000, value: web3.toWei(6, "ether")}).then(ret => {console.log(ret.logs[0].event, ret.logs[0].args)})
DCTI.withdraw(0, {from: account1, gasPrice:21000}).then(ret => {console.log(ret.logs[0].args)})

account0 = web3.eth.accounts[0]
account1 = web3.eth.accounts[1]
account2 = web3.eth.accounts[2]

DCI.donate(0, {from: account2, gasPrice:21000, value: web3.toWei(6, "ether")}).then(ret => {console.log(ret.logs[0].event, ret.logs[0].args); console.log(ret.logs[1].event, ret.logs[1].args)})
