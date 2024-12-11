// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from '../src/Raffle.sol';
import {HelperConfig} from './HelperConfig.s.sol';
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external {
        deployRaffle();
    }

    function deployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0) {
            // create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (uint256 subId, address vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator);
            config.subscriptionId = uint64(subId);
            config.vrfCoordinator = vrfCoordinator;
            
            // fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle({
            entranceFee : config.entranceFee,
            interval : config.interval,
            vrfCoordinator : config.vrfCoordinator,
            gasLane : config.gasLane,
            subscriptionId : config.subscriptionId,
            callbackGasLimit : config.callbackGasLimit
        });
        vm.stopBroadcast();
        
        console.log('asfasdfsadfsdafasdfsadf');
        
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, uint64(config.subscriptionId));

        return (raffle, helperConfig);
    }
}