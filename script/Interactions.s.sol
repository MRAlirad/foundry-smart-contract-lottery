// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstances} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

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

contract FuncSubscription is Script, CodeConstances {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK
    
    function fundSuscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint64 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address linkToken) public {
        console.log('Funding Subscription : ', subscriptionId);
        console.log('using vrfCoordinator : ', vrfCoordinator);
        console.log('On ChainId : ', block.chainid);

        if(block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription({
                _subId : subscriptionId,
                _amount : FUND_AMOUNT
            });
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSuscriptionUsingConfig();
    }
}