// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Foundry's Script and other necessary contracts
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ResourceManager.sol";

interface IERC20Mintable is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract DeployResourceManager is Script {
    function run() external {
        // Start broadcasting transactions to the network
        // The PRIVATE_KEY is set in the environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // base sepolia
        address bridgeAddress = 0x303AE9878288cd970741C568377059B27F47735F;
        address tokenAddress = 0x408DdbB94C985f8Fec4D3Bb8d4b05d69D0620283;
        bytes32 resourceId = bytes32(0x000000000000000000000000408DdbB94C985f8Fec4D3Bb8d4b05d69D0620283);
        bool isMintable = false;
        uint256 amount = 1000 * 10 ** 18;
        uint64 destChainId = 421614;

        // // arbitrum sepolia
        // address bridgeAddress = 0xE0915765ebe676359CdA2a18f0Ac7EA590Ae9a76;
        // address tokenAddress = 0x21B18e8c6c8e4eB7f05Fa6A48373002AA389Feec;
        // bytes32 resourceId = bytes32(0x000000000000000000000000408DdbB94C985f8Fec4D3Bb8d4b05d69D0620283);
        // bool isMintable = true;
        // uint256 amount = 1000 * 10 ** 18;
        // uint64 destChainId = 84532;


        ResourceManager resourceManager = ResourceManager(bridgeAddress);
        // resourceManager.setResource(resourceId, tokenAddress, isMintable);
        // resourceManager.setDestChainId(resourceId, destChainId, true);

        // IERC20Mintable token = IERC20Mintable(tokenAddress);
        // token.approve(address(resourceManager), amount);
        // token.mint(0x4BEB1413d5B15B147458242Fc6E96bF8f6635F52, amount);

        // uint256 depositAmount = 50 * 10**18; // Example deposit amount
        resourceManager.deposit(resourceId, amount / 10, destChainId);


        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
