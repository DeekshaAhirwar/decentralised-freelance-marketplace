// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FreelanceMarketplace
 * @dev Smart contract for a decentralized freelance marketplace
 */
contract FreelanceMarketplace {
    struct Project {
        address client;
        address freelancer;
        uint256 amount;
        string description;
        bool isCompleted;
        bool isApproved;
    }

    mapping(uint256 => Project) public projects;
    uint256 public projectCount;
    uint256 public platformFee = 2; // 2% platform fee

    event ProjectCreated(uint256 projectId, address client, uint256 amount, string description);
    event ProjectAssigned(uint256 projectId, address freelancer);
    event ProjectCompleted(uint256 projectId);

    /**
     * @dev Creates a new project
     * @param _description Description of the project
     * @return projectId The ID of the newly created project
     */
    function createProject(string memory _description) external payable returns (uint256) {
        require(msg.value > 0, "Payment must be greater than 0");
        
        uint256 projectId = projectCount;
        
        projects[projectId] = Project({
            client: msg.sender,
            freelancer: address(0),
            amount: msg.value,
            description: _description,
            isCompleted: false,
            isApproved: false
        });
        
        projectCount++;
        
        emit ProjectCreated(projectId, msg.sender, msg.value, _description);
        
        return projectId;
    }

    /**
     * @dev Assigns a freelancer to a project
     * @param _projectId ID of the project
     * @param _freelancer Address of the freelancer
     */
    function assignFreelancer(uint256 _projectId, address _freelancer) external {
        Project storage project = projects[_projectId];
        
        require(msg.sender == project.client, "Only client can assign freelancer");
        require(project.freelancer == address(0), "Freelancer already assigned");
        require(_freelancer != address(0), "Invalid freelancer address");
        require(!project.isCompleted, "Project already completed");
        
        project.freelancer = _freelancer;
        
        emit ProjectAssigned(_projectId, _freelancer);
    }

    /**
     * @dev Completes a project and releases payment to freelancer
     * @param _projectId ID of the project
     */
    function completeProject(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        
        require(msg.sender == project.client, "Only client can complete project");
        require(project.freelancer != address(0), "No freelancer assigned");
        require(!project.isCompleted, "Project already completed");
        
        project.isCompleted = true;
        project.isApproved = true;
        
        uint256 fee = (project.amount * platformFee) / 100;
        uint256 payment = project.amount - fee;
        
        // Transfer payment to freelancer
        (bool sent, ) = project.freelancer.call{value: payment}("");
        require(sent, "Failed to send payment to freelancer");
        
        emit ProjectCompleted(_projectId);
    }
}
