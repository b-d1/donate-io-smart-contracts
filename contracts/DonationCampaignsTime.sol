pragma solidity ^0.4.11;

contract DonationCampaignsTime {

    struct Donation {
        address from;
        uint amount;
    }

    //

    /* Donation campaign statuses
        Active = Active
        FundingGoalReachedNotExpired = Funding goal reached, time not expired yet.
        FundingGoalReachedExpired = Funding goal reached, time has expired - owner can withdraw. (Finished)
        FundingGoalNotReachedExpired = Funding goal not reached, time has expired - funds ready for refund. (Failed)
        Stopped = Stopped - function call by owner, before the time has expired - funds ready for refund (Failed).
        Succeeded = Finished - succeeded - owner withdrawn the funds
    */

    enum CampaignStatus {
        Active,
        FundingGoalReachedNotExpired,
        FundingGoalReachedExpired,
        FundingGoalNotReachedExpired,
        Stopped,
        Succeeded
    }

    struct DonationCampaign {
        address owner;
        uint fundingGoal;
        uint timeGoal;
        uint amount;
        uint numDonations;
        CampaignStatus status;
        mapping (uint => Donation) donations;
    }

    uint public numCampaigns;
    uint public numSucceededCampaigns;

    mapping (uint => DonationCampaign) private donationCampaigns;

    event DonationCampaignFundingGoalReached(uint donationCampaignId, uint amount);
    event DonationCampaignGoalsReached(uint donationCampaignId, uint amount);
    event DonationCampaignTimeExpiredNotFunded(uint donationCampaignId, uint amount);
    event DonationCampaignSucceeded(uint donationCampaignId, uint amount);
    event DonationCampaignStopped(uint donationCampaignId);
    event DonationReceived(uint donationCampaignId, address from, uint amount);
    event DonationCampaignCreated(uint donationCampaignId, uint fundingGoal, uint timeGoal);

    function newCampaign(uint fundingGoal, uint timeGoal) public returns (uint donationCampaignId) {
        require(fundingGoal != 0, "Invalid funding goal.");
        require(timeGoal > now, "Invalid time goal.");

        donationCampaignId = numCampaigns++;

        donationCampaigns[donationCampaignId] = DonationCampaign({owner: msg.sender, fundingGoal: fundingGoal, timeGoal: timeGoal, amount: 0, numDonations: 0, status: CampaignStatus.Active});
        emit DonationCampaignCreated(donationCampaignId, fundingGoal, timeGoal);
    }

    function donate(uint donationCampaignId) public payable returns (bool) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        // Check if donation campaign exists
        require(donationCampaign.fundingGoal > 0, 'The donation campaign does not exists');

        // Check if donation campaign is not finished yet
        require(donationCampaign.status == CampaignStatus.Active || donationCampaign.status == CampaignStatus.FundingGoalReachedNotExpired, 'The donation campaign already finished.');

        // Check if the the donor is not the owner
        require(msg.sender != donationCampaign.owner, 'The owner of the campaign cannot donate!');

        // Check if donation campaign has expired
        if(now > donationCampaign.timeGoal) {
            // check if the campaign has failed in funding, if the funding is still not reached (use status to save on computation)
            if(donationCampaign.status == CampaignStatus.Active) {
                donationCampaign.status = CampaignStatus.FundingGoalNotReachedExpired;
                emit DonationCampaignTimeExpiredNotFunded(donationCampaignId, donationCampaign.amount);
            } else {
                donationCampaign.status = CampaignStatus.FundingGoalReachedExpired;
                emit DonationCampaignGoalsReached(donationCampaignId, donationCampaign.amount);
            }
            // return money to sender
            msg.sender.transfer(msg.value);
            return false;
        }

        donationCampaign.donations[donationCampaign.numDonations++] = Donation({from: msg.sender, amount: msg.value});
        donationCampaign.amount += msg.value;

        emit DonationReceived(donationCampaignId, msg.sender, msg.value);

        if(donationCampaign.amount >= donationCampaign.fundingGoal) {
            donationCampaign.status = CampaignStatus.FundingGoalReachedNotExpired;
            emit DonationCampaignFundingGoalReached(donationCampaignId, donationCampaign.amount);
        }

        return true;
    }

    // Donor withdraw, if the campaign has failed.
    // Check all donations, collect total amount, nullify donation amounts and transfer to donor,
    // if the donor didn't withdraw already.
    function withdrawFromFailedCampaign(uint donationCampaignId) public returns (bool) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        require(donationCampaign.status == CampaignStatus.FundingGoalNotReachedExpired || donationCampaign.status == CampaignStatus.Stopped, "You cannot withdraw, this campaign is not a failed campaign.");

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
    // The campaign has succeeded if the time has expired and the funding goal is reached.
    function withdraw(uint donationCampaignId) public {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];
        // Check if the owner is the one who is going to withdraw.
        require(donationCampaign.owner == msg.sender, 'The donation campaign owner can only withdraw the collected campaign funds.');

        /*
         Check if the donation campaign has finished (the funding goal is reached,
         the time goal is reached (or about to be reached - time passed already but status not updated
         - no donations or withdraw calls), and the owner hasn't withdrawn already).
        */
        require(donationCampaign.status == CampaignStatus.FundingGoalReachedNotExpired ||  donationCampaign.status == CampaignStatus.FundingGoalReachedExpired, 'Cannot withdraw, the goals not reached (conditions not met).');


        if(donationCampaign.status == CampaignStatus.FundingGoalReachedNotExpired) {
            if(now < donationCampaign.timeGoal) {
                revert('Cannot withdraw, the campaign is still active - time not expired yet.');
            }
        }

        // Update donation campaign state and transfer to owner.
        donationCampaign.status = CampaignStatus.Succeeded;

        uint amount = donationCampaign.amount;
        // Nullify amount in case the owner tries to withdraw again.
        donationCampaign.amount = 0;

        numSucceededCampaigns++;
        emit DonationCampaignSucceeded(donationCampaignId, amount);
        msg.sender.transfer(amount);
    }

    function stopDonationCampaign(uint donationCampaignId) public returns (bool) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        require(donationCampaign.status == CampaignStatus.Active || donationCampaign.status == CampaignStatus.FundingGoalReachedNotExpired || donationCampaign.status == CampaignStatus.FundingGoalReachedExpired, 'The campaign cannot be stopped at this stage, it has finished successfully, is already stopped or failed.');

        require(donationCampaign.owner == msg.sender, 'The donation campaign owner can only stop the transaction.');

        donationCampaign.status = CampaignStatus.Stopped;

        emit DonationCampaignStopped(donationCampaignId);

        return true;
    }


    function getCampaignCollectedAmount(uint donationCampaignId) view public returns (uint) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        return donationCampaign.amount;
    }

    function getCampaignGoals(uint donationCampaignId) public view returns (uint, uint) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        return (donationCampaign.fundingGoal, donationCampaign.timeGoal);
    }

    // revisit
    function checkCampaignStatus(uint donationCampaignId) public returns (CampaignStatus) {

        DonationCampaign storage donationCampaign = donationCampaigns[donationCampaignId];

        require(donationCampaign.fundingGoal > 0, 'The donation campaign does not exists');

        if(donationCampaign.status == CampaignStatus.Active) {
            if(donationCampaign.timeGoal > now && donationCampaign.amount < donationCampaign.fundingGoal) {
                donationCampaign.status = CampaignStatus.FundingGoalNotReachedExpired;
            }
            return donationCampaign.status;
        } else if(donationCampaign.status == CampaignStatus.FundingGoalReachedNotExpired) {
            if(donationCampaign.timeGoal > now) {
                donationCampaign.status = CampaignStatus.FundingGoalReachedExpired;
            }
            return donationCampaign.status;
        }

        return donationCampaign.status;

    }
}
