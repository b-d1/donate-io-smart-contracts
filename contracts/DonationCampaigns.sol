pragma solidity ^0.4.11;

contract DonationCampaigns {

    struct Donation {
        address from;
        uint amount;
    }

    /* Donation campaign status
        Active = Active
        FundingGoalReached = Finished (goal reached) - not withdrawn yet, donations stopped, owner can withdraw.
        Stopped = Finished - failed - function call by owner (funds ready for refund, donations stopped)
        Succeeded = Finished - succeeded - owner withdrawn the funds
    */

    enum CampaignStatus {
        Active,
        FundingGoalReached,
        Stopped,
        Succeeded
    }

    struct DonationCampaign {
        address owner;
        uint fundingGoal; // wei
        uint amount; // wei
        uint numDonations;
        CampaignStatus status;
        mapping (uint => Donation) donations;
    }

    uint public numCampaigns;
    uint public numSucceededCampaigns;

    mapping (uint => DonationCampaign) private donationCampaigns;

    event DonationCampaignGoalReached(uint donationCampaignId);
    event DonationCampaignSucceeded(uint donationCampaignId);
    event DonationCampaignStopped(uint donationCampaignId);
    event DonationReceived(uint donationCampaignId, address from, uint amount);
    event DonationCampaignCreated(uint donationCampaignId, uint fundingGoal);

    function newCampaign(uint fundingGoal) public returns (uint donationCampaignId) {
        require(fundingGoal != 0, "Invalid funding goal.");
        donationCampaignId = numCampaigns++;

        donationCampaigns[donationCampaignId] = DonationCampaign({owner: msg.sender, fundingGoal: fundingGoal, amount: 0, numDonations: 0, status: CampaignStatus.Active});
        emit DonationCampaignCreated(donationCampaignId, fundingGoal);
    }

    function donate(uint donationCampaignId) public payable returns (bool) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        // Check if donation campaign exists
        require(donationCampaign.fundingGoal > 0, 'The donation campaign does not exists.');

        // Check if donation campaign is not finished yet
        require(donationCampaign.status == CampaignStatus.Active, 'The donation campaign already finished.');

        // Check if the the donor is not the owner
        require(msg.sender != donationCampaign.owner, 'The owner of the campaign cannot donate!');

        donationCampaign.donations[donationCampaign.numDonations++] = Donation({from: msg.sender, amount: msg.value});
        donationCampaign.amount += msg.value;

        emit DonationReceived(donationCampaignId, msg.sender, msg.value);

        if(donationCampaign.amount >= donationCampaign.fundingGoal) {
            donationCampaign.status = CampaignStatus.FundingGoalReached;
            emit DonationCampaignGoalReached(donationCampaignId);
        }

        return true;
    }

    // Donor withdraw, if the campaign has failed.
    // Check all donations, collect total amount, nullify donation amounts and transfer to donor,
    // if the donor didn't withdraw already.
    function withdrawFromFailedCampaign(uint donationCampaignId) public returns (bool) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        require(donationCampaign.status == CampaignStatus.Stopped, "You cannot withdraw, this campaign is not a stopped campaign.");

        require(donationCampaign.numDonations > 0, "You cannot withdraw, the campaign contains no donations.");

        uint withdrawAmount = 0;
        for (uint i = 0; i < donationCampaign.numDonations; i++) {

            Donation storage donation = donationCampaign.donations[i];
            if(donation.from == msg.sender) {
                withdrawAmount += donation.amount;
                donation.amount = 0;
            }
        }

        if(withdrawAmount > 0) {
            msg.sender.transfer(withdrawAmount);
            return true;
        } else {
//            revert("You have nothing to withdraw");
            return false;
        }


    }

    // Withdraw by campaign owner, if the campaign has finished successfully.
    // The campaign has succeeded if the funding goal is reached.
    function withdraw(uint donationCampaignId) public {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        // Check if donation campaign exists and is finished (the owner did not withdraw yet).
        require(donationCampaigns[donationCampaignId].status == CampaignStatus.FundingGoalReached, 'Cannot withdraw, the funding goal not reached (conditions not met).');

        // Check if the owner is the one who is going to withdraw.
        require(donationCampaign.owner == msg.sender, 'The donation campaign owner can only withdraw the collected campaign funds.');

        // Update donation campaign state and transfer to owner.
        donationCampaign.status = CampaignStatus.Succeeded;

        uint amount = donationCampaign.amount;
        // Nullify amount in case the owner tries to withdraw again.
        donationCampaign.amount = 0;

        numSucceededCampaigns++;
        emit DonationCampaignSucceeded(donationCampaignId);
        msg.sender.transfer(amount);
    }

    function stopDonationCampaign(uint donationCampaignId) public returns (bool) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        require(donationCampaign.status == CampaignStatus.Active || donationCampaign.status == CampaignStatus.FundingGoalReached, 'The campaign cannot be stopped at this stage, it has finished successfully, is already stopped or failed.');

        require(donationCampaign.owner == msg.sender, 'The donation campaign owner can only stop the transaction.');

        donationCampaign.status = CampaignStatus.Stopped;

        emit DonationCampaignStopped(donationCampaignId);

        return true;
    }

    function getCampaignCollectedAmount(uint donationCampaignId) public view returns (uint) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        return donationCampaign.amount;
    }

    function getCampaignFundingGoal(uint donationCampaignId) public view returns (uint) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        return donationCampaign.fundingGoal;
    }

}
