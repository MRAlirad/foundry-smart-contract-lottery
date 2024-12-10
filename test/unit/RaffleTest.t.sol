// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from 'forge-std/Test.sol';
import {DeployRaffle} from '../../script/DeployRaffle.s.sol';
import {Raffle} from '../../src/Raffle.sol';
import {HelperConfig} from '../../script/HelperConfig.s.sol';

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr('player');
    uint256 public STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }
    
    function testRaffleInitializesIsOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}