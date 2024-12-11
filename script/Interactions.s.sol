// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns(uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return(subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint256, address) {
        console.log('Creating subscription on Chain ID', block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your Subscription Id is: ", subId);
        console.log("Please update the subscription id in your HelperConfig.s.sol");

        return(subId, vrfCoordinator);
    }

    function run () public {
        createSubscriptionUsingConfig();
    }
}