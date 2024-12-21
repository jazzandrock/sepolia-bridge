// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin Contracts
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract ResourceManager is AccessControl {
    // Define roles using keccak256 hash
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    // Mappings
    mapping(bytes32 => bool) public txExecuted;
    mapping(bytes32 => bool) public isMintable;
    mapping(bytes32 => address) public resourceToTokenAddress;
    mapping(bytes32 => mapping(uint64 => bool)) public resourceToDestChainId;

    // Events
    event Deposited(bytes32 indexed resourceId, address indexed user, uint256 amount, uint64 destChainId);
    event ResourceSet(bytes32 indexed resourceId, address tokenAddress, bool mintable);
    event TxExecuted(bytes32 indexed originalTxHash, address indexed user, uint256 amount);
    event DestChainIdSet(bytes32 indexed resourceId, uint64 indexed chainId, bool supported);

    constructor() {
        // Grant the contract deployer the admin and relayer roles
        _grantRole(ADMIN_ROLE, msg.sender);
        // Set ADMIN_ROLE as the admin of ADMIN_ROLE and RELAYER_ROLE
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(RELAYER_ROLE, ADMIN_ROLE);

        _grantRole(RELAYER_ROLE, msg.sender);
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
     * @dev Sets or updates the supported destination chain ID for a specific resource.
     * @param resourceId The ID of the resource.
     * @param chainId The destination chain ID to set.
     * @param supported Indicates if the chain ID is supported.
     */
    function setDestChainId(bytes32 resourceId, uint64 chainId, bool supported) external onlyRole(ADMIN_ROLE) {
        require(resourceToTokenAddress[resourceId] != address(0), "Resource not set");
        resourceToDestChainId[resourceId][chainId] = supported;

        emit DestChainIdSet(resourceId, chainId, supported);
    }

    /**
     * @dev Deposits tokens into the contract for a specific destination chain.
     * @param resourceId The ID of the resource.
     * @param amount The amount of tokens to deposit.
     * @param destChainId The destination chain ID where the tokens will be used.
     */
    function deposit(bytes32 resourceId, uint256 amount, uint64 destChainId) external {
        require(amount > 0, "Amount must be greater than zero");
        address tokenAddress = resourceToTokenAddress[resourceId];
        require(tokenAddress != address(0), "Resource not set");

        // Check if the destination chain ID is supported for the given resource
        require(resourceToDestChainId[resourceId][destChainId], "Unsupported destination chain ID");

        IERC20 token = IERC20(tokenAddress);

        if (isMintable[resourceId]) {
            // If mintable, burn tokens from the user
            IMintableERC20 burnableToken = IMintableERC20(tokenAddress);
            burnableToken.burnFrom(msg.sender, amount);
        } else {
            // If not mintable, transfer tokens from the user to the contract
            bool success = token.transferFrom(msg.sender, address(this), amount);
            require(success, "Token transfer failed");
        }

        emit Deposited(resourceId, msg.sender, amount, destChainId);
    }

    /**
     * @dev Executes a transaction by either minting new tokens to the user or transferring existing tokens from the contract.
     * @param originalTxHash The original transaction hash to ensure idempotency.
     * @param resourceId The ID of the resource associated with the transaction.
     * @param user The address of the user to receive the tokens.
     * @param amount The amount of tokens to transfer or mint.
     */
    function executeTx(
        bytes32 originalTxHash,
        bytes32 resourceId,
        address user,
        uint256 amount
    ) external onlyRole(RELAYER_ROLE) {
        // Ensure the transaction hasn't been executed before
        require(!txExecuted[originalTxHash], "Transaction already executed");
        
        // Validate the user address
        require(user != address(0), "Invalid user address");
        
        // Validate the amount
        require(amount > 0, "Amount must be greater than zero");

        // Retrieve the token address associated with the resource
        address tokenAddress = resourceToTokenAddress[resourceId];
        require(tokenAddress != address(0), "No such resource registered");

        IMintableERC20 token = IMintableERC20(tokenAddress);

        // Mark the transaction as executed to prevent re-execution
        txExecuted[originalTxHash] = true;

        if (isMintable[resourceId]) {
            // If the token is mintable, mint new tokens to the user
            bool mintSuccess = token.mint(user, amount);
            require(mintSuccess, "Minting failed");
        } else {            
            bool transferSuccess = token.transfer(user, amount);
            require(transferSuccess, "Transfer failed");
        }

        // Emit the TxExecuted event to log the transaction
        emit TxExecuted(originalTxHash, user, amount);
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
