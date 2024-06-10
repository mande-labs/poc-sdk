// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ReputationRegistry {
    struct DappInfo {
        address owner;
        address reputationSystem;
    }

    // Mapping from dApp name to its owner and reputation system address
    mapping(bytes32 => DappInfo) public dapps;

    // Function to make an entry in the mapping
    function registerDapp(bytes32 dappName, address reputationSystem) public {
        DappInfo storage info = dapps[dappName];

        // If the dApp already exists
        if (info.owner != address(0)) {
            // Check if the sender is the owner
            require(msg.sender == info.owner, "Unauthorized: Sender is not the owner");
            // If owner is the same, do nothing
            return;
        }

        // Register new dApp with sender as owner and provided reputation system address
        dapps[dappName] = DappInfo({
            owner: msg.sender,
            reputationSystem: reputationSystem
        });
    }

    // Function to get dApp information
    function getDappInfo(bytes32 dappName) public view returns (DappInfo memory) {
        return dapps[dappName];
    }
}
