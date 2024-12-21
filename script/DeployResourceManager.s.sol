// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Foundry's Script and other necessary contracts
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ResourceManager.sol";

contract DeployResourceManager is Script {
    function run() external {
        // Start broadcasting transactions to the network
        // The PRIVATE_KEY is set in the environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the ResourceManager Contract
        console.log("Deploying ResourceManager contract...");
        // ResourceManager resourceManager = new ResourceManager();
        ResourceManager resourceManager = ResourceManager(address(0x303AE9878288cd970741C568377059B27F47735F));
        console.log("ResourceManager deployed at:", address(resourceManager));

        // 2. Define the token address
        address tokenAddress = 0x83c84Ad6614E8e6e31D2e7A8FbeD660b90c06a79;

        // 3. Generate the resourceId by appending zeros to the token address
        // Remove '0x' and convert to lowercase for consistency
        bytes20 tokenAddressBytes = bytes20(tokenAddress);
        bytes32 resourceId = bytes32(bytes.concat(tokenAddressBytes, bytes12(0)));

        // console.log("Generated resourceId:", toHex(resourceId));

        // // 4. Register the resource (token is not mintable)
        // console.log("Registering the resource...");
        // resourceManager.setResource(resourceId, tokenAddress, false);
        // console.log("Resource registered successfully.");

        // 5. Approve the ResourceManager to spend tokens
        // uint256 amountToApprove = 1000 * 10**18; // Example amount
        // IERC20 token = IERC20(tokenAddress);
        // console.log("Approving ResourceManager to spend tokens...");
        // token.approve(address(resourceManager), amountToApprove);
        // // require(approval, "Token approval failed");
        // console.log("Token approved successfully.");


        uint64 destChainId = 421614;
        resourceManager.setDestChainId(resourceId, destChainId, true);

        uint256 depositAmount = 50 * 10**18; // Example deposit amount
        resourceManager.deposit(resourceId, depositAmount, destChainId);


        // Stop broadcasting transactions
        vm.stopBroadcast();
    }

    // Helper function to convert bytes32 to string
    function toHex(bytes32 data) internal pure returns (string memory) {
        return string(abi.encodePacked("0x", toHexString(data)));
    }

    function toHexString(bytes32 data) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = hexChars[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = hexChars[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}
