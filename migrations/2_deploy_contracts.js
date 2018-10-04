const DonationCampaigns = artifacts.require("./DonationCampaigns.sol");
const DonationCampaignsTime = artifacts.require("./DonationCampaignsTime.sol");

const contractOptions = {
  gasPrice: 1000000000,
  gas: 4500000
};

module.exports = function(deployer) {
    deployer.deploy(DonationCampaigns, contractOptions);
    deployer.deploy(DonationCampaignsTime, contractOptions);
};