// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Burnable.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

contract ResourceManager is AccessControl {
    // Define roles using keccak256 hash
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    // Mappings
    mapping(bytes32 => bool) public txExecuted;
    mapping(bytes32 => bool) public isMintable;
    mapping(bytes32 => address) public resourceToTokenAddress;

    // Events
    event DepositId(bytes32 indexed resourceId, address indexed user, uint256 amount, uint256 depositId);
    event ResourceSet(bytes32 indexed resourceId, address tokenAddress, bool mintable);
    event TxExecuted(bytes32 indexed originalTxHash, address indexed user, uint256 amount);

    // Deposit counter
    uint256 private depositCounter;

    constructor() {
        // Grant the contract deployer the admin role
        _setupRole(ADMIN_ROLE, msg.sender);
        // Set ADMIN_ROLE as the admin of ADMIN_ROLE and RELAYER_ROLE
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(RELAYER_ROLE, ADMIN_ROLE);
    }

    /**
     * @dev Sets or updates a resource.
     * @param resourceId The ID of the resource.
     * @param tokenAddress The ERC20 token address associated with the resource.
     * @param mintable Indicates if the token is mintable.
     */
    function setResource(bytes32 resourceId, address tokenAddress, bool mintable) external onlyRole(ADMIN_ROLE) {
        require(tokenAddress != address(0), "Invalid token address");
        resourceToTokenAddress[resourceId] = tokenAddress;
        isMintable[resourceId] = mintable;

        emit ResourceSet(resourceId, tokenAddress, mintable);
    }

    /**
     * @dev Deposits tokens into the contract.
     * @param resourceId The ID of the resource.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(bytes32 resourceId, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        address tokenAddress = resourceToTokenAddress[resourceId];
        require(tokenAddress != address(0), "Resource not set");

        IERC20 token = IERC20(tokenAddress);

        if (isMintable[resourceId]) {
            // If mintable, burn tokens from the user
            IERC20Burnable burnableToken = IERC20Burnable(tokenAddress);
            burnableToken.transferFrom(msg.sender, address(this), amount);
            // Alternatively, if the token has a burnFrom function
            // burnableToken.burnFrom(msg.sender, amount);
        } else {
            // If not mintable, transfer tokens from the user to the contract
            token.transferFrom(msg.sender, address(this), amount);
        }

        depositCounter += 1;
        emit DepositId(resourceId, msg.sender, amount, depositCounter);
    }

    /**
     * @dev Executes a transaction.
     * @param originalTxHash The original transaction hash.
     * @param user The user address to execute the transaction for.
     * @param amount The amount involved in the transaction.
     */
    function executeTx(bytes32 originalTxHash, address user, uint256 amount) external onlyRole(RELAYER_ROLE) {
        require(!txExecuted[originalTxHash], "Transaction already executed");
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than zero");

        // Here, you might need to retrieve the resourceId associated with the originalTxHash
        // For simplicity, assuming resourceId is derived or stored elsewhere
        // This example assumes a single resource; adjust as needed.

        // Example: Assume resourceId is part of originalTxHash or mapped elsewhere
        // bytes32 resourceId = ...;

        // For demonstration, let's iterate through resources to find a matching condition
        // Not efficient; ideally, you should have a direct mapping
        // Here, we'll assume a single resource for simplicity
        revert("Resource ID retrieval not implemented");
    }

    /**
     * @dev Allows the admin to grant the relayer role to an address.
     * @param relayer The address to be granted the relayer role.
     */
    function addRelayer(address relayer) external onlyRole(ADMIN_ROLE) {
        grantRole(RELAYER_ROLE, relayer);
    }

    /**
     * @dev Allows the admin to revoke the relayer role from an address.
     * @param relayer The address to have the relayer role revoked.
     */
    function removeRelayer(address relayer) external onlyRole(ADMIN_ROLE) {
        revokeRole(RELAYER_ROLE, relayer);
    }
}
