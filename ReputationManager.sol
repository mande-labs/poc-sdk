// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IReclaimSDK } from './IReclaimSDK.sol';
import { BrokerFactory } from './BrokerFactory.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ReputationManager is Initializable, UUPSUpgradeable {
    enum TaskType { VOTING, ONCHAIN_ACTIVITY, RECLAIM_PROOF, ADMIN_ACTIVITY, ORDER_COMPLETE }

    struct RmUser {
        uint256 reputationPoints;
        uint256 voteCount;
        bool isBlacklisted;
        bool initialised;
    }

    struct Task {
        TaskType taskType;
        int256 rp;
        uint256 timestamp;
    }

    uint256 public constant secondsInMonth = 30 days;

    mapping(address => RmUser) public rmusers;
    mapping(address => Task[]) public taskLedger;
    mapping(address => bool) public isWhitelisted;

    // Voting related data
    mapping(address => address) public votedBy;
    mapping(address => mapping(address => bool)) public votedTo;
    mapping(address => mapping(uint256 => uint256)) public epochVotes;
    mapping(address => bool) public claimedVotingRp;
    mapping(address => bool) public claimedVotingReward;
    mapping(address => uint256) public accruedVotingRewards;

    // Aadhar proof data
    mapping(address => IReclaimSDK.Proof) public aadharProof;

    mapping(address => mapping(uint256 => bool)) public claimedOnchainActivity;

    address public admin;
    uint256 public contractCreationTime;

    IReclaimSDK public reclaimSDK;
    BrokerFactory public brokerFactory;
    IERC20 public usdtContract;

    // Config variables
    uint256 public defaultRp;
    uint256 public voterSlashRp;
    uint256 public votesPerEpoch;
    uint256 public minRpToVote;
    uint256 public maxRpToBeVoted;
    uint256 public reclaimRp;
    uint256 public votingRp;
    uint256 public votingVolumeThreshold;
    uint256 public onChainActivityBase;
    uint256 public onChainActivityRp;
    uint256 public orderCompleteRp;
    uint256 public votingRewardVolume;
    uint256 public votingReward;

    mapping(address => address[]) public votes;


    // Events
    event UserBlacklisted(address indexed user);
    event UserWhitelisted(address indexed contractAddress);
    event ReputationPointsUpdated(address indexed user, int256 rpChange);
    event UserVoted(address indexed voter, address indexed votedUser);
    event ReclaimProofSubmitted(address indexed user, IReclaimSDK.Proof proof);
    event VotingRPUpdated(address indexed voter, uint256 points);
    event OnchainActivityRPUpdated(address indexed user, uint256 points);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an admin");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Not whitelisted");
        _;
    }

    modifier onlyBrokers() {
        (,,address brokerAddr,,) = brokerFactory.brokers(msg.sender);
        require(brokerAddr != address(0), "Not authorised");
        _;
    }

    function initialize(address _brokerFactoryAddr, address _usdtAddr, address _admin) public initializer {
        admin = _admin;
        contractCreationTime = block.timestamp;
        brokerFactory = BrokerFactory(_brokerFactoryAddr);
        usdtContract = IERC20(_usdtAddr);

        defaultRp = 100;
        voterSlashRp = 500;
        votesPerEpoch = 4;
        minRpToVote = 300;
        maxRpToBeVoted = 300;
        reclaimRp = 200;
        votingRp = 50;
        votingVolumeThreshold = 100 * 1e6;
        onChainActivityBase = 5;
        onChainActivityRp = 50;
        orderCompleteRp = 2;
        votingRewardVolume = 500 * 1e6;
        votingReward = 5 * 1e6;

        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function initUserRp(address userAddr) external {
        require(userAddr == msg.sender, "Not authorised");
        RmUser memory user = rmusers[userAddr];
        if (!user.initialised) {
            rmusers[userAddr].initialised = true;
            rmusers[userAddr].reputationPoints = defaultRp;
        }
    }

    function setReclaimSDK(address _reclaimSDK) external onlyAdmin {
        reclaimSDK = IReclaimSDK(_reclaimSDK);
    }

    function markUserBlacklisted(address user) external onlyAdmin {
        rmusers[user].isBlacklisted = true;
        rmusers[user].reputationPoints = 0;

        // Slash rp of voter also if exists
        address voter = votedBy[user];
        if (voter != address(0)) {
            if (rmusers[user].reputationPoints < voterSlashRp) {
                rmusers[user].reputationPoints = 0;
            } else {
                rmusers[user].reputationPoints -= voterSlashRp;
            }
        }

        emit UserBlacklisted(user);
    }

    function whitelistContract(address contractAddress) external onlyAdmin {
        isWhitelisted[contractAddress] = true;

        emit UserWhitelisted(contractAddress);
    }

    function updateReputationPoints(address userAddr, int256 rpChange) external onlyBrokers {
        _updateUserRp(userAddr, rpChange);
        _updateTaskLedger(userAddr, TaskType.ADMIN_ACTIVITY, rpChange);
    }

    function getUserTaskLedger(address userAddr) public view returns (Task[] memory) {
        return taskLedger[userAddr];
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (block.timestamp - contractCreationTime) / secondsInMonth;
    }

    function getVotesBy(address voter) public view returns (address[] memory) {
        return votes[voter];
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getContextMessageFromProof(IReclaimSDK.Proof memory proof)
        internal
        pure
        returns (string memory)
    {
        string memory context = proof.claimInfo.context;
        return substring(context, 0, 42);
    }

    function stringToAddress(string memory str) internal pure returns (address) {
        bytes memory data = bytes(str);
        uint160 result = 0;
        for (uint8 i = 2; i < 42; i++) {
            uint8 digit = uint8(data[i]);
            if (digit >= 48 && digit <= 57) {
                result = result * 16 + (digit - 48);
            } else if (digit >= 65 && digit <= 70) {
                result = result * 16 + (digit - 55);
            } else if (digit >= 97 && digit <= 102) {
                result = result * 16 + (digit - 87);
            } else {
                revert("Invalid address characters");
            }
        }
        return address(result);
    }

    function vote(address userToVote) external {
        uint256 currentEpoch = getCurrentEpoch();
        require(msg.sender != userToVote, "You can't vote yourself");
        require(epochVotes[msg.sender][currentEpoch] < votesPerEpoch, "No recommendations left");
        require(rmusers[msg.sender].reputationPoints >= minRpToVote, "You need atleast 300 RP to recommend");
        require(rmusers[userToVote].reputationPoints <= maxRpToBeVoted && !rmusers[userToVote].isBlacklisted, "User is not eligle for recommendations");
        require(votedBy[userToVote] == address(0), "User already recommended");

        epochVotes[msg.sender][currentEpoch]++;
        votedBy[userToVote] = msg.sender;
        votedTo[msg.sender][userToVote] = true; // TODO: remove this
        rmusers[userToVote].voteCount += 1;
        votes[msg.sender].push(userToVote);

        emit UserVoted(msg.sender, userToVote);
    }

    function submitReclaimProof(IReclaimSDK.Proof memory proof) external {
        require(rmusers[msg.sender].reputationPoints > 0, "Insufficient RP");
        require(aadharProof[msg.sender].signedClaim.claim.owner == address(0), "Proof already submitted");

        bool verified = reclaimSDK.verifyProof(proof);
        require(verified, "Verification failed");

        address verifier = stringToAddress(getContextMessageFromProof(proof));
        require(msg.sender == verifier, "Not allowed");

        aadharProof[msg.sender] = proof;

        _updateUserRp(msg.sender, int256(reclaimRp));
        _updateTaskLedger(msg.sender, TaskType.RECLAIM_PROOF, int256(reclaimRp));
    }

    function orderVolumeUpdateRpHook(address user, uint256 volume, uint256 numTxns) external onlyWhitelisted {
        _updateOnchainActivityRP(user, numTxns);
        _updateVotingRP(user, volume);
        _votingRewardsLedger(user, volume);
    }

    function orderCompleteUpdateRpHook(address user) external onlyWhitelisted {
        _updateUserRp(user, int256(orderCompleteRp));
        _updateTaskLedger(user, TaskType.ORDER_COMPLETE, int256(orderCompleteRp));
    }

    function claimVotingRewards() external {
        require(accruedVotingRewards[msg.sender] > 0, "No rewards accrued");
        uint256 rewardsAccrued = accruedVotingRewards[msg.sender];
        accruedVotingRewards[msg.sender] = 0;
        usdtContract.transfer(msg.sender, rewardsAccrued);
    }

    function withdrawDepositedRewards() external onlyAdmin {
        uint256 totBal = usdtContract.balanceOf(address(this));
        usdtContract.transfer(admin, totBal);
    }

    function _updateVotingRP(address votee, uint256 volume) private {
        // Check if the user has been voted on, their volume meets the threshold, and they haven't claimed yet
        if (votedBy[votee] != address(0) && volume >= votingVolumeThreshold && !claimedVotingRp[votee]) {
            address voter = votedBy[votee];
            _updateUserRp(voter, int256(votingRp));
            _updateUserRp(votee, int256(votingRp));
            _updateTaskLedger(voter, TaskType.VOTING, int256(votingRp));
            _updateTaskLedger(votee, TaskType.VOTING, int256(votingRp));
            claimedVotingRp[votee] = true;  // Mark rp claimed for the user
            emit VotingRPUpdated(voter, votingRp);
        }
    }

    function _updateOnchainActivityRP(address user, uint256 numTxns) private {
        // Loop to check for a milestone match, up to 5^20 (as an arbitrary large number)
        for (uint256 i = 1; i <= 20; i++) {
            uint256 milestone = onChainActivityBase**i;
            if (numTxns == milestone && !claimedOnchainActivity[user][i]) {
                _updateUserRp(user, int256(onChainActivityRp));
                _updateTaskLedger(user, TaskType.ONCHAIN_ACTIVITY, int256(onChainActivityRp));
                claimedOnchainActivity[user][i] = true;  // Mark the milestone as claimed
                emit OnchainActivityRPUpdated(user, onChainActivityRp);
                break;  // Exit loop if a match is found
            } else if (numTxns < milestone) {
                break;  // Exit loop if numTxns is less than the current milestone
            }
        }
    }

    function _votingRewardsLedger(address votee, uint256 volume) private {
        // Check if the user has been voted on, their volume meets the threshold, and they haven't claimed yet
        if (votedBy[votee] != address(0) && volume >= votingRewardVolume && !claimedVotingReward[votee]) {
            address voter = votedBy[votee];
            accruedVotingRewards[voter] += votingReward;
            claimedVotingReward[votee] = true;  // Mark the reward as claimed for the user
        }
    }

    function _updateUserRp(address userAddr, int256 rpChange) private {
        RmUser storage user = rmusers[userAddr];

        if (!user.initialised) {
            user.initialised = true;
            user.reputationPoints = defaultRp;
        }

        if(rpChange < 0 && uint256(-rpChange) > user.reputationPoints) {
            user.reputationPoints = 0; // Avoid underflow
        } else if (rpChange < 0) {
            user.reputationPoints -= uint256(-rpChange);
        } else {
            user.reputationPoints += uint256(rpChange);
        }

        emit ReputationPointsUpdated(userAddr, rpChange);
    }

    function _updateTaskLedger(address user, TaskType taskType, int256 rp) private {
        Task memory newTask = Task({
            taskType: taskType,
            rp: rp,
            timestamp: block.timestamp
        });

        taskLedger[user].push(newTask);
    }
}
