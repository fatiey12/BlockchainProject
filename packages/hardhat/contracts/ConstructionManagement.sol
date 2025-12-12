// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Blockchain-Based Construction Milestone Management System
 * ---------------------------------------------------------
 * Features:
 * - Role-based access control
 * - Milestone submission, revision, verification & approval
 * - Multiple suppliers
 * - Material delivery linked to milestones
 * - Document hash registry
 * - Immutable audit trail
 */

contract ConstructionManagement {

    // ENUMS
    enum Status { NOT_CREATED, SUBMITTED, REVISION_REQUIRED, VERIFIED, APPROVED }
    enum Role { NONE, ADMIN, CONTRACTOR, ARCHITECT, INVESTOR, SUPPLIER }

    // STRUCTS
    struct Participant {
        bool isRegistered;
        Role role;
    }

    struct Milestone {
        string description;
        bytes32[] fileHashes;
        address submittedBy;
        address verifiedBy;
        address approvedBy;
        uint256 submissionTime;
        uint256 verificationTime;
        uint256 approvalTime;
        Status status;
    }

    struct Delivery {
        uint256 milestoneID;
        bytes32 deliveryHash;
        string description;
        uint256 timestamp;
        address supplier;
    }

    // STATE VARIABLES
    address public admin;

    mapping(address => Participant) public participants;
    mapping(uint256 => Milestone) public milestones;
    mapping(uint256 => Delivery) public deliveries;

    // Multiple deliveries per milestone
    mapping(uint256 => uint256[]) public milestoneDeliveries;

    // EVENTS
    event ParticipantRegistered(address user, Role role);
    event MilestoneSubmitted(uint256 milestoneID, address contractor);
    event MilestoneChangeRequested(uint256 milestoneID, address architect);
    event MilestoneVerified(uint256 milestoneID, address architect);
    event MilestoneApproved(uint256 milestoneID, address investor);
    event DeliveryLogged(uint256 deliveryID, uint256 milestoneID, address supplier);
    event DocumentHashRegistered(bytes32 hashValue, string docType, address uploadedBy);
    event MilestoneResubmitted(uint256 milestoneID, address contractor);

    // MODIFIERS
    modifier onlyAdmin() {
        require(participants[msg.sender].role == Role.ADMIN, "Not admin");
        _;
    }

    modifier onlyRole(Role r) {
        require(participants[msg.sender].role == r, "Unauthorized role");
        _;
    }

    // CONSTRUCTOR
    constructor() {
        admin = msg.sender;
        participants[msg.sender] = Participant(true, Role.ADMIN);
        emit ParticipantRegistered(msg.sender, Role.ADMIN);
    }

    // PARTICIPANT REGISTRATION (Admin Only)
    function registerParticipant(address user, uint8 roleIndex)
    public
    onlyAdmin
    
{
    require(!participants[user].isRegistered, "Already registered");
    require(roleIndex > 0, "Invalid role");

    Role role = Role(roleIndex);

    participants[user] = Participant(true, role);
    emit ParticipantRegistered(user, role);
}


    // MILESTONE SUBMISSION (Contractor)
    function submitMilestone(
        uint256 milestoneID,
        string memory description,
        bytes32[] memory fileHashes
    )
        public
        onlyRole(Role.CONTRACTOR)
    {
        require(fileHashes.length > 0, "At least one document hash required");
        require(
            milestones[milestoneID].status == Status.NOT_CREATED ||
            milestones[milestoneID].status == Status.REVISION_REQUIRED,
            "Milestone cannot be submitted"
        );

        bool isResubmission = milestones[milestoneID].status == Status.REVISION_REQUIRED;

        milestones[milestoneID].description = description;
        milestones[milestoneID].fileHashes = fileHashes;
        milestones[milestoneID].submittedBy = msg.sender;
        milestones[milestoneID].submissionTime = block.timestamp;
        milestones[milestoneID].status = Status.SUBMITTED;

        emit MilestoneSubmitted(milestoneID, msg.sender);

        if (isResubmission) {
            emit MilestoneResubmitted(milestoneID, msg.sender);
        }
    }

    // REQUEST CHANGES (Architect)
    function requestChanges(uint256 milestoneID)
        public
        onlyRole(Role.ARCHITECT)
    {
        require(milestones[milestoneID].status == Status.SUBMITTED, "Not awaiting review");

        milestones[milestoneID].verifiedBy = msg.sender;
        milestones[milestoneID].verificationTime = block.timestamp;
        milestones[milestoneID].status = Status.REVISION_REQUIRED;

        emit MilestoneChangeRequested(milestoneID, msg.sender);
    }

    // VERIFY MILESTONE (Architect)
    function verifyMilestone(uint256 milestoneID)
        public
        onlyRole(Role.ARCHITECT)
    {
        require(milestones[milestoneID].status == Status.SUBMITTED, "Not submitted");

        milestones[milestoneID].verifiedBy = msg.sender;
        milestones[milestoneID].verificationTime = block.timestamp;
        milestones[milestoneID].status = Status.VERIFIED;

        emit MilestoneVerified(milestoneID, msg.sender);
    }

    // APPROVE MILESTONE (Investor)
    function approveMilestone(uint256 milestoneID)
        public
        onlyRole(Role.INVESTOR)
    {
        require(milestones[milestoneID].status == Status.VERIFIED, "Not verified");

        milestones[milestoneID].approvedBy = msg.sender;
        milestones[milestoneID].approvalTime = block.timestamp;
        milestones[milestoneID].status = Status.APPROVED;

        emit MilestoneApproved(milestoneID, msg.sender);
    }

    // MATERIAL DELIVERY LOGGING (Supplier)
    function logDelivery(
        uint256 deliveryID,
        uint256 milestoneID,
        bytes32 deliveryHash,
        string memory description
    )
        public
        onlyRole(Role.SUPPLIER)
    {
        require(deliveries[deliveryID].timestamp == 0, "Delivery already exists");

        deliveries[deliveryID] = Delivery({
            milestoneID: milestoneID,
            deliveryHash: deliveryHash,
            description: description,
            timestamp: block.timestamp,
            supplier: msg.sender
        });

        milestoneDeliveries[milestoneID].push(deliveryID);

        emit DeliveryLogged(deliveryID, milestoneID, msg.sender);
    }

    // VIEW FUNCTIONS
    function getMilestone(uint256 milestoneID)
        public
        view
        returns (Milestone memory)
    {
        return milestones[milestoneID];
    }

    function getDelivery(uint256 deliveryID)
        public
        view
        returns (Delivery memory)
    {
        return deliveries[deliveryID];
    }

    function getDeliveriesForMilestone(uint256 milestoneID)
        public
        view
        returns (uint256[] memory)
    {
        return milestoneDeliveries[milestoneID];
    }

    // DOCUMENT HASH REGISTRATION
    function registerDocumentHash(bytes32 hashValue, string memory docType)
        public
    {
        require(hashValue != bytes32(0), "Invalid hash");

        emit DocumentHashRegistered(hashValue, docType, msg.sender);
    }
}

