# Foundry Smart Contract Lottery

In this lesson, we will cover **events**, **true random numbers**, **modules**, and **automation**.

The main contract that we'll work on will be `src/Raffle.sol`. It contains detailed comments and professional-looking NAT spec, such as:

```solidity
/**
    * @title A sample Raffle Contract
    * @notice This contract is for creating a sample raffle contract
    * @dev This implements the Chainlink VRF Version 2
*/
```

This smart contract allows for a **fully automated** Smart Contract Lottery where users can buy a lottery ticket by entering a raffle. Functions like `checkUpkeep` and `performUpkeep` will automate the lottery process, ensuring the system runs without manual intervention.

We'll use **Chainlink VRF** version 2.5 for randomness. The `fulfillRandomWords` function will handle the selection of the random winner and reset the lottery, ensuring a provably fair system.

We'll also write advanced **scripts** that you can find inside the `makefile`. These include various commands to interact with the smart contract, such as creating subscriptions and adding a consumer.


## Project setup

For the project, we'll be working with an advanced lottery or raffle smart contract. It will have the following features:

-   Events
-   On-chain randomness (done the proper way)
-   Chainlink automation
-   And many more!

### Setup

To start a new foundry project, please call the following commands in your terminal:

```Solidity
mkdir smart-contract-lottery
cd smart-contract-lottery
```

Init our Foundry project:

```Solidity
forge init
```

Please delete all the `Counter` files that are populated by default when we initiate a new Foundry project.

A good practice at this stage in your project is to come up with a plan/blueprint. What do we want to do with this? What is the main functionality of the project?

What we want it to do?

1. Users should be able to enter the raffle by paying for a ticket. The ticket fees are going to be the prize the winner receives.
2. The lottery should automatically and programmatically draw a winner after a certain period.
3. Chainlink VRF should generate a provably random number.
4. Chainlink Automation should trigger the lottery draw regularly.

we will use the Chainlink VRF service to obtain a random number, an operation that is harder than you think in the absence of a Chainlink VRF-like service.


Inside the `src` folder create a file named `Raffle.sol`. Inside the newly created file, we start our new project as always:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Raffle {

}
```

As you might know already having a strong NATSPEC is a key element in developing a nicely structured and readable smart contract. Let's create a NATSPEC description above the contract declaration line:

```solidity

/**
 * @title A sample Raffle Contract
 * @author Patrick Collins (or even better, you own name)
 * @notice This contract is for creating a sample raffle
 * @dev It implements Chainlink VRFv2.5 and Chainlink Automation
 */
contract Raffle {

}
```

What is the main functionality a raffle should have?

1. Users should be able to enter the raffle by paying a ticket price;
2. At some point, we should be able to pick a winner out of the registered users.

```solidity
contract Raffle{
    function enterRaffle() public {}

    function pickWinner() public {}
}
```

Good! Given that users need to pay for a ticket, we need to define the price of this ticket and also make the `enterRaffle` function `payable` to be able to receive the user's ETH. Every time we introduce a new state variable we need to think about what type of variable we need to use. Should we make the `entranceFee` constant, immutable or simply private? Why private and not public? The best solution is to make it a private immutable, so we get to define it once at the constructor level. If we decide to create a new raffle we simply redeploy the contract and change the `entranceFee`. Ok, but we need people to be able to see what they should pay as `entranceFee`. To facilitate this we will create a getter function.

```solidity
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    /** Getter Function */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
```

## Solidity style guide

Solidity docs provide an [Order of Layout](https://docs.soliditylang.org/en/latest/style-guide.html#order-of-layout):

```solidity
// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
```

## Creating Custom Errors

Previously we defined the `i_entranceFee` variable. This is the amount the user has to send to enter the raffle. How do we check this?

```solidity
function enterRaffle() external payable {
    require(msg.value >= i_entranceFee, "Not enough ETH sent");
}
```

First, we changed the visibility from `public` to `external`. `external` is more gas efficient, and we won't call the `enterRaffle` function internally.

We used a `require` statement to ensure that the `msg.value` is higher than `i_entranceFee`. If that is false, we will yield an error message `"Not enough ETH sent"`.

**Note: The** **`require`** **statement is used to enforce certain conditions at runtime. If the condition specified in the** **`require`** **statement evaluates to** **`false`, the transaction is reverted, and any changes made to the state within that transaction are undone. This is useful for ensuring that certain prerequisites or validations are met before executing further logic in a smart contract.**

In Solidity 0.8.4 a new and more gas-efficient way has been introduced.

### Custom errors

[Custom errors](https://docs.soliditylang.org/en/v0.8.25/contracts.html#errors-and-the-revert-statement) provide a way to define and use specific error types that can be used to revert transactions with more efficient and gas-saving mechanisms compared to the `require` statements with string messages. If you want to find out more about how custom errors decrease both deploy and runtime gas [click here](https://soliditylang.org/blog/2021/04/21/custom-errors/).

I know we just wrote this using the `require` statement, we did that because `require` is used in a lot of projects, that you might get inspiration from or build on top of and so on. But from now on we will perform checks using the `if` statement combined with custom errors.

We will refactor `enterRaffle`, but before that let's define our custom error.

```solidity
error Raffle_NotEnoughEthSent();
```

Now the `enterRaffle()` function:

```solidity
function enterRaffle() external payable {
    // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
    if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
}
```

You will see that we named the custom error using the `Raffle__` prefix. This is a very good practice that will save you a ton of time when you need to debug a protocol with 20 smart contracts. You will run your tests and then ask yourself `Ok, it failed with this error ... but where does this come from?`. Because you thought ahead and used prefixes in naming your error you won't have that problem!


## Smart contracts events

We need a storage structure that keeps track of all registered users from where to pick the winner.
We can use and **array** to do that.


Add the array below the `i_entranceFee` declaration: `address payable[] private s_players;`

We've made it `address payable` because one of the participants registered in this array will be paid the ETH prize, hence the need for the `payable` attribute.

Back in the `enterRaffle` function, we need to add the address that paid into the `s_players` array:

```solidity
function enterRaffle() external payable {
    if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
    s_players.push(payable(msg.sender));
}
```

The `.push` method is used to append an element to an array, increasing its length by 1.

`s_players.push(payable(msg.sender));` performs a modification of the state by adding the payable address `msg.sender` in the array. It is customary to emit an **event** every time we perform a state modification.

### Events

Events are a way for smart contracts to communicate with the outside world, primarily with the front-end applications that interact with these contracts. Events are logs that the Ethereum Virtual Machine (EVM) stores in a special data structure known as the blockchain log. These logs can be efficiently accessed and filtered by external applications, such as dApps (decentralized applications) or off-chain services. The logs can also be accessed from the blockchain nodes. Each emitted event is tied up to the smart contract that emitted it.

Please click [here](https://docs.soliditylang.org/en/v0.8.25/contracts.html#events) to find out more about events.

How can we use events?

Imagine we have a more complex function that changes an important parameter, let's say we are recording the exchange rate of BTC/USDC. We change it by calling the function `changeER()`. After we perform the call and the exchange rate is changed we need to make sure this also gets picked up by our front-end. We make the front-end listen for the `BTCUSDCupdated` event. An example of that event could be this:

```solidity
event BTCUSDCupdated(
    uint256 indexed oldER,
    uint256 indexed newER,
    uint256 timestamp,
    address sender
)
```

You will see that some of the emitted parameters are indexed and some are not. Indexed parameters, also called `topics`, are much more easy to search than non-indexed ones.

For an event to be logged we need to emit it.

Let's come back to our `Raffle` contract where we'll also learn how to emit them.

First, we define the event (be mindful of where the events should go in terms of our defined layout)

```solidity
event EnteredRaffle(address indexed player);
```

Then, we emit it in `enterRaffle`:

```solidity
function enterRaffle() external payable {
    if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
    s_players.push(payable(msg.sender));
    emit EnteredRaffle(msg.sender);
}
```

## Random numbers - Block Timestamp

One of the Raffle contract goals is `...we should be able to automatically pick a winner out of the registered users.`

What do we need to do that?

1. A random number
2. Use the random number to pick a winning player
3. Call `pickWinner` automatically

For now, let's focus on points 1 and 2. But before diving straight into the randomness let's think a bit about the Raffle design. We don't have any problem with anyone calling `pickWinner`. As long as someone wants to pay the gas associated with that they are more than welcome to do it. But we need to make sure that a decent amount of time passed since the start of the raffle. We don't want to host a 10-second raffle where two people get to register and then someone calls the `pickWinner`. In that sense, we need to define a new state variable called `i_interval` which represents the duration of a raffle:

```solidity
contract Raffle {

    error Raffle__NotEnoughEthSent();

    uint256 private immutable i_entranceFee;
    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;

    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
    }
}
```

Now that we have defined a raffle duration, we need to check it in `pickWinner`, but check it against what? We need to check it against the difference between the moment in time when the raffle started and the moment in time when the function `pickWinner` is called. But for that, we need to record the raffle starting time.

Perform the following update:

```solidity
contract Raffle{

    error Raffle__NotEnoughEthSent();

    uint256 private immutable i_entranceFee;
    // @dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    event EnteredRaffle(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestmap;
    }
}
```

And now we have all the prerequisites to perform the check:

```solidity
// 1. Get a random number
// 2. Use the random number to pick a player
// 3. Automatically called
function pickWinner() external {
    // check to see if enough time has passed
    if (block.timestamp - s_lastTimeStamp < interval) revert();
}
```

## Random numbers - Introduction to Chainlink VRF

Chainlink VRF (Verifiable Random Function) is a service provided by the Chainlink network that offers secure and verifiable randomness to smart contracts on blockchain platforms. This randomness is crucial for our Raffle and for any other applications that need a source of randomness.

How does Chainlink VRF work?

Chainlink VRF provides randomness in 3 steps:

1. Requesting Randomness: A smart contract makes a request for randomness by calling the `requestRandomness` function provided by the Chainlink VRF. This involves sending a request to the Chainlink oracle along with the necessary fees.

2. Generating Randomness: The Chainlink oracle node generates a random number off-chain using a secure cryptographic method. The oracle also generates a proof that this number was generated in a verifiable manner.

3. Returning the Result: The oracle returns the random number along with the cryptographic proof to the smart contract. The smart contract can then use the random number, and any external observer can verify the proof to confirm the authenticity and integrity of the randomness.

We will follow the Chainlink tutorial available [here](https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number).

Go to the [Chainlink Faucet](https://faucets.chain.link/sepolia) and grab yourself some test LINK and/or ETH.

Go [here](https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number) and scroll down and press on the blue button that says `Open the Subscription Manager`.

Press on the blue button that says `Create Subscription`. You don't need to provide a project name or an email address, but you can if you want to.

When you press `Create subscription` you will need to approve the subscription creation. Sign it using your MetaMask and wait until you receive the confirmation. You will be asked to sign the message again. If you are not taken to the `Add Funds` page, go to `My Subscriptions` section and click on the id of the subscription you just created, then click on `Actions` and `Fund subscription`. Proceed in funding your subscription.

The next step is adding consumers. On the same page, we clicked on the `Actions` button you can find a button called `Add consumer`. You will be prompted with an `Important` message that communicates your `Subscription ID`. That is a very important thing that we'll use in our smart contract.

Keep in mind that our smart contract and Chainlink VRF need to be aware of each other, which means that Chainlink needs to know the address that will consume the LINK we provided in our subscription and the smart contract needs to know the Subscription ID.

Go back to the [tutorial page](https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number#create-and-deploy-a-vrf-compatible-contract). Scroll down to the `Create and deploy a VRF v2 compatible contract` section. Read the short description about dependencies and pre-configured values and open the contract in Remix by pressing on `Open in Remix`.

```Solidity
For this example, use the VRFv2Consumer.sol sample contract. This contract imports the following dependencies:

- VRFConsumerBaseV2.sol
- VRFCoordinatorV2Interface.sol
- ConfirmedOwner.sol

The contract also includes pre-configured values for the necessary request parameters such as vrfCoordinator address, gas lane keyHash, callbackGasLimit, requestConfirmations and number of random words numWords. You can change these parameters if you want to experiment on different testnets, but for this example you only need to specify subscriptionId when you deploy the contract.

Build and deploy the contract on Sepolia.
```

Ignoring the configuration parameters for now let's look through the most important elements of the contract:

```solidity
struct RequestStatus {
    bool fulfilled; // whether the request has been successfully fulfilled
    bool exists;    // whether a requestId exists
    uint256[] randomWords;
}

mapping(uint256 => RequestStatus) public s_requests; // requestId --> requestStatus
uint256[] public requestIds;
uint256 public lastRequestId;
```

This is the way the contract keeps track of the requests, their status and the `randomWords` provided as a response to the requests. The mapping uses the `requestId` as a key and the details regarding the request are stored inside the `RequestStatus` struct which acts as a mapping value. Given that we can't loop through mappings we will also have a `requestIds` array. We also record the `lastRequestId` for efficiency.

We will also store the `subscriptionId` as a state variable, this will be checked inside the `requestRandomWords` by the `VRFCoordinatorV2`. If we don't have a valid subscription or we don't have enough funds our request will revert.

The next important piece is the `VRFCoordinatorV2Interface` which is one of the dependencies we import, this [contract](https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol) has a lot of methods related to subscription management and requests, but the one we are interested in right now is `requestRandomWords`, this is the function that we need to call to trigger the process of receiving the random words, that we'll use as a source of randomness in our application.

```solidity
// Assumes the subscription is funded sufficiently.
function requestRandomWords()
    external
    onlyOwner
    returns (uint256 requestId)
{
    // Will revert if subscription is not set and funded.
    requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
    );
    s_requests[requestId] = RequestStatus({
        randomWords: new uint256[](0),
        exists: true,
        fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numWords);
    return requestId;
}
```

This function is the place where we call the `requestRandomWords` on the `VRFCoordinatorV2Interface` which sends us back the `requestId`. We record this `requestId` in the mapping, creating its `RequestStatus`, we push it into the `requestIds` array and update the `lastRequestId` variable. The function returns the `requestId`.

After calling the function above, Chainlink will call your `fulfillRandomWords` function. They will provide the `_requestId` corresponding to your `requestRandomWords` call together with the `_randomWrods`. It updates the `fulfilled` and `randomWords` struct parameters. In real-world applications, this is where the logic happens. If you have to assign some traits to an NFT, roll a dice, draw the raffle winner, etc.

Great! Let's come back to the configuration parameters. The `keyHash` variable represents the gas lane we want to use. Think of those as the maximum gas price you are willing to pay for a request in gwei. It functions as an ID of the off-chain VRF job that runs in response to requests.

```Solidity
200 gwei Key Hash   0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
500 gwei Key Hash   0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92
1000 gwei Key Hash  0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805
```

These are the gas lanes available on Ethereum mainnet, you can find out info about all available gas lanes on [this page](https://docs.chain.link/vrf/v2/subscription/supported-networks).

The same page contains information about `Max Gas Limit` and `Minimum Confirmations`. Our contract specifies those in `callbackGasLimit` and `requestConfirmations`.

-   `callbackGasLimit` needs to be adjusted depending on the number of random words you request and the logic you are employing in the callback function.
-   `requestConfirmations` specifies the number of block confirmations required before the Chainlink VRF node responds to a randomness request. This parameter plays a crucial role in ensuring the security and reliability of the randomness provided. A higher number of block confirmations reduces the risk of chain reorganizations affecting the randomness request. Chain reorganizations (or reorgs) occur when the blockchain reorganizes due to the discovery of a longer chain, which can potentially alter the order of transactions.

Another extremely important aspect related to Chainlink VRF is understanding its `Security Considerations`. Please read them [here](https://docs.chain.link/vrf/v2-5/security#use-requestid-to-match-randomness-requests-with-their-fulfillment-in-order).

I know this lesson was a bit abstract. But let's implement this in our project in the next lesson. See you there!

## Implement the Chainlink VRF

> 🗒️ **NOTE**:
> This written lesson uses VRF V2. Video lesson uses VRF V2.5. There are
> some changes. Import path for VRF contract is slightly different, and the
> `requestRandomWords()` parameter is slightly different\*\*

Continuing the previous lesson, let's integrate Chainlink VRF into our Raffle project.

Coming back to our `pickWinner` function.

```solidity
// 1. Get a random number
// 2. Use the random number to pick a player
// 3. Automatically called
function pickWinner() external {
    // check to see if enough time has passed
    if (block.timestamp - s_lastTimeStamp < i_interval) revert();
}
```

Let's focus on points 1 and 2. In the previous lesson, we learned that we need to request a `randomWord` and Chainlink needs to callback one of our functions to answer the request. Let's copy the `requestId` line from the [Chainlink VRF docs](https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number#analyzing-the-contract) example inside our `pickWinner` function and start fixing the missing dependencies.

```solidity
function pickWinner() external {
    // check to see if enough time has passed
    if (block.timestamp - s_lastTimeStamp < i_interval) revert();

    VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
        .RandomWordsRequest({
            keyHash,
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
}
```

You know the `keyHash`, `subId`, `requestConfirmations`, `callbackGasLimit` and `numWords` from our previous lesson.

Ok, starting from the beginning what do we need?

1. We need to establish the fact that our `Raffle` contract is a consumer of Chainlink VRF;
2. We need to take care of the VRF Coordinator, define it as an immutable variable and give it a value in the constructor;

Let's add the following imports:

```solidity
import {VRFConsumerBaseV2Plus} from "@chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
```

Let's make our contract inherit the `VRFConsumerBaseV2Plus`:

```solidity
contract Raffle is VRFConsumerBaseV2Plus
```

For our imports to work we need to install the Chainlink library, and run the following command in your terminal:

```bash
forge install smartcontractkit/chainlink@42c74fcd30969bca26a9aadc07463d1c2f473b8c --no-commit
```


Now run `forge build`. **It will fail**, it should fail because we didn't define a ton of variables. But what matters at this point is how it fails! We need it to fail with the following error:

```Solidity
Error:
Compiler run failed:
Error (7576): Undeclared identifier.
  --> src/Raffle.sol:53:8:
```

If it doesn't fail with that error but fails with this error then we need to do additional things:

```Solidity
Error:
Compiler run failed:
Error (6275): Source "lib/chainlink/contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol" not found: File not found. Searched the following locations:
```

```toml
remappings = [
    '@chainlink/=lib/chainlink/contracts/',
    '@solmate=lib/solmate/src/'
]
```

This is to be read as follows: `@chainlink/` in your imports becomes `lib/chainlink/contracts/` behind the stage. We need to make sure that if we apply that change to our import the resulting **PATH is correct**.

`chainlink/src/v0.8/vrf/VRFConsumerBaseV2Plus.sol` becomes `lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2Plus.sol`, which is correct. Sometimes some elements of the PATH are either missing or doubled, as follows:

`lib/chainlink/contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol`

or

`lib/chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol`

Both these variants are **incorrect**. You need to always be able to access the PATH in your explorer window on the left, if you can't then you need to adjust the remappings to match the lib folder structure.

Output:

```Solidity
Compiler run failed:
Error (7576): Undeclared identifier.
  --> src/Raffle.sol:55:26:
   |
55 |                 keyHash: s_keyHash, // gas lane
   |                          ^^^^^^^^^

Error (7576): Undeclared identifier.
  --> src/Raffle.sol:56:24:
   |
56 |                 subId: s_subscriptionId, // subscription ID
   |                        ^^^^^^^^^^^^^^^^

Error (7576): Undeclared identifier.
  --> src/Raffle.sol:57:39:
   |
57 |                 requestConfirmations: requestConfirmations,
   |                                       ^^^^^^^^^^^^^^^^^^^^

Error (7576): Undeclared identifier.
  --> src/Raffle.sol:58:35:
   |
58 |                 callbackGasLimit: callbackGasLimit,// make sure we don't overspend
   |                                   ^^^^^^^^^^^^^^^^

Error (7576): Undeclared identifier.
  --> src/Raffle.sol:59:27:
   |
59 |                 numWords: numWords, // number random numbers
```

At least now we know what's left.

Let's add the above-mentioned variables inside the VRF state variables block:

```solidity
// Chainlink VRF related variables
bytes32 private immutable i_keyhash;
uint256 private immutable i_subscriptionId;
uint16 private constant REQUEST_CONFIRMATIONS = 3;
uint32 private immutable i_callbackGasLimit;
uint32 private constant NUM_WORDS = 1;
```

For simplicity we request only 1 word, thus we make that variable constant. The same goes for request confirmations, this number can vary depending on the blockchain we chose to deploy to but for mainnet 3 is perfect. Cool!

The next step is to attribute values inside the constructor:

```solidity
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyhash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
    }
```

-   We are providing the `gasLane`, `subscriptionId` and `callbackGasLimit` in our input section of the constructor;
-   We are assigning the inputted values to the state variables we defined at an earlier point;


```solidity
function fulfillRandomWords(
    uint256 requestId,
    uint256[] calldata randomWords
) internal override {}
```

This will be called by the `vrfCoordinator` when it sends back the requested `randomWords`. This is also where we'll select our winner!


## Implementing Vrf Fulfil

To work with the Chainlink VRF (Verifiable Random Function) in Solidity, we need to inherit functions from an **abstract contract** called [`VRFConsumerBaseV2Plus`](https://github.com/smartcontractkit/chainlink-brownie-contracts/blob/12393bd475bd60c222ff12e75c0f68effe1bbaaf/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol). Abstract contracts can contain both defined and undefined functions, such as:

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;
```

-   When we call the `Raffle::performUpkeep` function, we send a request for a **random number** to the VRF coordinator, using the `s_vrfCoordinator` variable inherited from `VRFConsumerBaseV2Plus`. This request involves passing a `VRFV2PlusClient.RandomWordsRequest` struct to the `requestRandomWords` method, which generates a **request ID**.

-   After a certain number of block confirmations, the Chainlink Node will generate a random number and call the `VRFConsumerBaseV2Plus::rawFulfillRandomWords` function. This function validates the caller address and then invokes the `fulfillRandomWords` function in our `Raffle` contract.

> 🗒️ **NOTE**:br
> Since `VRFConsumerBaseV2Plus::fulfillRandomWords` is marked as `virtual`, we need to **override** it in its child contract. This requires defining the actions to take when the random number is returned, such as selecting a winner and distributing the prize.

Here’s how you override the `fulfillRandomWords` function:

```solidity
function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
    //pick a winner here, send him the reward and reset the raffle
}
```

## The modulo operation

We ended the previous lesson when we defined the following function:

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {}
```

As we've said before, this function is going to be called by the VRF service. Here we will be given 1 random word (1 because of the `NUM_WORDS` we defined in the previous lesson). This isn't a `word` as in a string of letters like `pizza`, this is a big and random uint256. Being a number we can use it to do math.

What we need is to use the `modulo` operator denoted as `%` in Solidity.

The modulo operation (often abbreviated as "mod") is a mathematical operation that finds the remainder when one integer is divided by another. In other words, given two numbers, a and b, the modulo operation `a % b` returns the remainder of the `a / b` division.

Examples:

```Solidity
5 % 2 = 1 // Because 5 is 2 * 2 + 1
11 % 3 = 2 // Because 11 is 3 * 3 + 2
159 % 50 = 9 // Because 153 is 50 * 3 + 9
1000 % 10 = 0 // Because 1000 is 100 * 10 + 0
```

We are going to use this function to pick a random winner.

Let's say we have 10 players (`s_players.length = 10`).

Now let's say Chainlink VRF sends back the number `123454321` (I know, super random).

Given that the `% 10` operation can yield a value between \[0:9] we can use the result of the `randomNumber % 10` as the `s_players` index corresponding to the winner.

Using the actual numbers:

```Solidity
123454321 % 10 = 1
```

This means that the player with index 1 (`s_players[1]`) is the winner of our raffle! The random number will always be different and sufficiently large. Using `s_players.length` will ensure that we always include all the players who paid a ticket. Perfect!

### Picking the winner


```solidity
function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[indexOfWinner];
}
```

Now let's record this last winner in state and send them their prize.

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[indexOfWinner];
    s_recentWinner = winner;

    (bool success,) = winner.call{value:address(this).balance}("");
    if (!success) revert Raffle__TransferFailed();
}
```

Let's define the `Raffle__TransferFailed()` custom error and the `s_recentWinner` variable in the state variables section.

```solidity
error Raffle__NotEnoughEthSent();
error Raffle__TransferFailed();

// Raffle related variables
uint256 private immutable i_entranceFee;
uint256 private immutable i_interval;
uint256 private s_lastTimeStamp;
address payable[] private s_players;
address payable private s_recentWinner;
```

## Implementing the lottery state - Enum

In Solidity, `enum` stands for Enumerable. It is a user-defined data type that restricts a variable to have only one of the predefined values listed within the enum declaration. These predefined values are internally treated as unsigned integers, starting from 0 up to the count of elements minus one. Enums are useful for improving code readability and reducing potential errors by limiting the range of acceptable values for a variable. Read more about enums [here](https://docs.soliditylang.org/en/v0.8.26/types.html#enums).

Let's think about all the possible states of our Raffle. We deploy the contract and the raffle is started, the participants buy a ticket to register. Let's call this state `OPEN`. After this, we have a period when we need to wait at least 3 blocks for Chainlink VRF to send us the random number this means that we have at least 36 seconds (12 seconds/block) of time when our Raffle is processing the winner. Let's call this state `CALCULATING`.

Paste the following code between the errors definition section and the state variables section:

```solidity
// Type declarations
enum RaffleState {
    OPEN,           // 0
    CALCULATING     // 1
}

// Put this one in `Raffle related variables`
    ;
```

Add the following inside your constructor:

```solidity
s_raffleState = RaffleState.OPEN;
```

Chainlink VRF has an [interesting page](https://docs.chain.link/vrf/v2-5/security) where they provide Security Considerations you should always implement when interacting with their service. One of these is called `Don't accept bids/bets/inputs after you have made a randomness request`, in our case this translates to `Don't let people buy tickets while we calculate the final winner`. I strongly encourage you to give that whole page a read, it will save you a lot of headaches.

Let's implement this in the code:

```solidity
function enterRaffle() external payable {
    if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
    if(s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen(); // If not open you don't enter.

    s_players.push(payable(msg.sender));
    emit EnteredRaffle(msg.sender);
}
```

Make sure to also define the new `Raffle__RaffleNotOpen()` error.

Great, now let's also change the state of the Raffle when we commence the process of picking the winner.

```solidity
function pickWinner() external {
    // check to see if enough time has passed
    if (block.timestamp - s_lastTimeStamp < i_interval) revert();

    s_raffleState = RaffleState.CALCULATING;
}
```

The last thing we need to do is to reopen the Raffle after we pick the winner inside `fulfillRandomWords` function.

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[indexOfWinner];
    s_recentWinner = winner;
    s_raffleState = RaffleState.OPEN;
    (bool success,) = winner.call{value:address(this).balance}("");
    if (!success) {
        revert Raffle__TransferFailed();
    }
}
```

## Lottery restart - Resetting an Array

 We've picked the winner, we've opened the lottery and ... what do we do with the players already in the array? They've had their chance to win and they didn't.

We add the following line inside the `fulfillRandomWords` function:

```solidity
s_players = new address payable[](0);
```

This initializes a new empty array over the existing array, which is another way of saying **we wipe out the existing array**.

Additionally, given that we are starting up a fresh raffle, we also need to bring the `s_lastTimeStamp` to the present time.

```solidity
s_lastTimeStamp = block.timestamp;
```

The last thing we need to do is to emit an event that logs the fact that we picked a winner.

Put this in your events section: `event PickedWinner(address winner);`.

And emit it as the last line of the `fulfillRandomWords` function: `emit PickedWinner(winner);`.

Run a `forge build` to make sure everything compiles.

## The Checks-Effects-Interactions (CEI) Pattern

The Checks-Effects-Interactions pattern is a crucial best practice in Solidity development aimed at enhancing the security of smart contracts, especially against reentrancy attacks. This pattern structures the code within a function into three distinct phases:

-   Checks: Validate inputs and conditions to ensure the function can execute safely. This includes checking permissions, input validity, and contract state prerequisites.
-   Effects: Modify the state of our contract based on the validated inputs. This phase ensures that all internal state changes occur before any external interactions.
-   Interactions: Perform external calls to other contracts or accounts. This is the last step to prevent reentrancy attacks, where an external call could potentially call back into the original function before it completes, leading to unexpected behavior. (More about reentrancy attacks on a later date)

Another important reason for using CEI in your smart contract is gas efficiency. Let's go through a small example:

```solidity
function coolFunction() public {
    sendA();
    callB();
    checkX();
    checkY();
    updateM();
}
```

In the function above what happens if `checkX()` fails? The EVM goes through a function from top to bottom. That means it will execute `sendA()` then `callB()` then attempt `checkX()` which will fail, and then all the things need to be reverted. Every single operation costs gas, we pay for everything, and we just performed 2 operations, to revert at the 3rd. From this perspective isn't the following more logical?

```solidity
function coolFunction() public {
    // Checks
    checkX();
    checkY();

    // Effects
    updateStateM();

    // Interactions
    sendA();
    callB();
}
```

First, we do the checks, if something goes bad we revert, but we don't spend that much gas. Then, if checks pass, we do effects, and all internal state changes are performed, these usually can't fail, or if they fail they spend an amount of gas that we can control. Lastly, we perform the interactions, here we send the tokens or ETH or perform external calls to other contracts. We wouldn't want these to happen in the absence of the checks or the state update so it's more logical to put them last.

## Introduction to Chainlink Automation

Looking through it we can see that there's an obvious problem. For the winner to be picked we need someone to call `pickWinner`. Manually calling this day after day is not optimal, and we, as engineers, need to come up with a better solution! Let's discuss Chainlink Automation!

**Chainlink Automation** is a decentralized service designed to automate key functions and DevOps tasks within smart contracts in a highly reliable, trust-minimized, and cost-efficient manner. It allows smart contracts to automatically execute transactions based on predefined conditions or schedules.


Open up the [Chainlink Automation link](https://automation.chain.link/) and press the blue button saying `Register new Upkeep`. Connect your wallet. Now we are asked to select a trigger for the automation. Please select `Time-based`. At the next step, we are asked to provide a `Target contract address` and copy-paste the address of the contract we just deployed on Sepolia.

Given that we didn't verify the contract we need to provide an ABI. Return to the Remix tab and on the menu on the left select the `SOLIDITY COMPILER` (It has the Solidity language logo). Ensure the proper contract is selected. Click on `ABI`, this will copy the ABI in your clipboard. Paste it inside the field Chainlink asks for it and press `Next`.

At this point, you will have access to a dropdown list containing all the callable functions. Select `count` ... the only function our contract has. Again press `Next`.

We need to specify our time schedule, i.e. the amount of time Chainlink Automation needs to wait between function calls. This takes the form of a `Cron expression`.

Chainlink provides a small but super intuitive tutorial that helps you to craft your Cron expression:

```Solidity
What is a CRON expression?
The CRON expression is a shorthand way to create a time schedule. Use the provided example buttons to experiment with different schedules and then create your own.

Cron schedules are interpreted according to this format:

┌───────── minute (0 - 59)
│ ┌─────── hour (0 - 23)
│ │ ┌───── day of the month (1 - 31)
│ │ │ ┌─── month (1 - 12)
│ │ │ │ ┌─ day of the week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
│ │ │ │ │
│ │ │ │ │
* * * * *
All times are in UTC

- can be used for range e.g. "0 8-16 * * *"
/ can be used for interval e.g. "0 */2 * * *"
, can be used for list e.g. "0 17 * * 0,2,4"

Special limitations:
no special characters: ? L W #
lists can have a max length of 26
no words
```

You can find out more about how to properly craft these by playing around with [crontab.guru](https://crontab.guru/) or using your favorite AI chatbot. Even better, you could ask the AI chatbot to craft it for you!

After you provide the Cron expression press `Next`.

Now we got to the `Upkeep details` section. Give it a name. The `Admin Address` should be defaulted to the address you used to deploy the contract. You should have some test LINK there. If you don't have any pick some up from [here](https://faucets.chain.link/sepolia). You have the option of specifying a `Gas limit`. Specify a `Starting balance`, I've used 10 LINK. You don't need to provide a project name or email address.

Click on `Register Upkeep` and sign the transactions that pop up.

I had to sign 3 transactions, after that let's click on `View Upkeep`.

In the `History` section, you can see the exact date and tx hash of the automated call. Make sure you fund the upkeep to always be above the `Minimum Balance`. You can fund your upkeep using the blue `Actions` button. Use the same button to edit your upkeep, change the frequency, or the gas limit, pause the upkeep or cancel it.

From time to time go back to Remix and check the `counter` value. You'll see it incremented with a number corresponding to the number of calls visible in the `History` we talked about earlier.

## Implementing Chainlink Automation


We need to refactor the `pickWinner` function. That functionality needs to be part of the `performUpkeep` if we want the Chainlink node to call it for us. But before that, let's create the `checkUpkeep` function:

```solidity
/**
 * @dev This is the function that the Chainlink Keeper nodes call
 * they look for `upkeepNeeded` to return True.
 * the following should be true for this to return true:
 * 1. The time interval has passed between raffle runs.
 * 2. The lottery is open.
 * 3. The contract has ETH.
 * 4. There are players registered.
 * 5. Implicity, your subscription is funded with LINK.
 */
function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
    bool isOpen = s_raffleState == RaffleState.OPEN;
    bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
    bool hasPlayers = s_players.length > 0;
    bool hasBalance = address(this).balance > 0;

    upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
    return (upkeepNeeded, "0x0");
}
```


Going back to the [Chainlink Automation tutorial](https://docs.chain.link/chainlink-automation/guides/compatible-contracts) we see that `checkUpkeep` can use onchain data and a specified `checkData` parameter to perform complex calculations offchain and then send the result to `performUpkeep` as `performData`. But in our case, we don't need that `checkData` parameter. If a function expects an input, but we are not going to use it we can comment it out like this: `/* checkData */`. we'll make `checkUpkeep` public view and we match the expected returns of `(bool upkeepNeeded, bytes memory /* performData */)` commenting out that `performData` because we aren't going to use it.

Back to our raffle now, what are the conditions required to be true in order to commence the winner-picking process? We've placed the answer to this in the NATSPEC comments.

```solidity
    * 1. The time interval has passed between raffle runs.
    * 2. The lottery is open.
    * 3. The contract has ETH.
    * 4. There are players registered.
    * 5. Implicity, your subscription is funded with LINK.
```

For points 1-3 we coded the following lines:

```solidity
bool isOpen = RaffleState.OPEN == s_raffleState;
bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
bool hasPlayers = s_players.length > 0;
bool hasBalance = address(this).balance > 0;
```

We check if the Raffle is in the open state, if enough time has passed and if there are players registered to the Raffle and if we have a prize to give out. All these need to be true for the winner-picking process to be able to run.

In the end, we return the two elements required by the function declaration:

```solidity
return (upkeepNeeded, "0x0");
```

`"0x0"` is just `0` in `bytes`, we ain't going to use this return anyway.

Chainlink nodes will call this `checkUpkeep` function. If the return `upkeepNeeded` is true, then they will call `performUpkeep` ... which in our case is the `pickWinner` function. Let's refactor it a little bit:

```solidity
// 1. Get a random number
// 2. Use the random number to pick a player
// 3. Automatically called
function performUpkeep(bytes calldata /* performData */) external {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded) revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));

    s_raffleState = RaffleState.CALCULATING;

    VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
        .RandomWordsRequest({
            keyHash: i_keyhash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

    uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
}
```

We copied the start from the [Chainlink Automation tutorial](https://docs.chain.link/chainlink-automation/guides/compatible-contracts) renaming the `pickWinner` function. Given that our new `performUpkeep` is external, as it should be if we want one of the Chainlink nodes to call it, we need to ensure that the same conditions are required for everyone else to call it. In other words, there are two possibilities for this function to be called:

1. A Chainlink node calls it, but it will first call `checkUpkeep`, see if it returns true, and then call `performUpkeep`.
2. Everyone else calls it ... but nothing is checked.

We need to fix point 2.

For that we will make the function perform a call to `checkUpkeep`:

`(bool upkeepNeeded, ) = checkUpkeep("");`

And we check it's result. If the result is false we revert with a new custom error:

```solidity
if(!upkeepNeeded) revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
```

Let's define it at the top of the contract, next to the other errors:

```solidity
error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);
```

This is the first time when we provided some parameters to the error. Think about them as extra info you get when you receive the error.

**Note: you can do both** **`uint256 raffleState`** **or** **`RaffleState raffleState`** **because these are directly convertible.**

## Custom Error with parameters

Using a basic `revert()` statement may not provide evidence on why a transaction failed. A better approach is to define custom errors by combining the **contract name** with a **description**, such as `Raffle__UpkeepNotNeeded()`. Additionally, including **parameters** can offer more detailed information about the cause of the transaction failure.

```Solidity
Raffle__UpkeepNotNeeded(address balance, uint256 length, uint256 raffleState);
```

## Quick recap

What did we do?

-   We implemented Chainlink VRF to get a random number
-   We defined a couple of variables that we need both for Raffle operation and for Chainlink VRF interaction
-   We have a not-so-small constructor
-   We created a method for the willing participants to enter the Raffle
-   Then made the necessary integrations with Chainlink Automation to automatically draw a winner when the time is right.
-   When the time is right and after the Chainlink nodes perform the call then Chainlink VRF will provide the requested randomness inside `fulfillRandomWords`
-   The randomness is used to find out who won, the prize is sent, raffle is reset.


## Deploying and testing our lottery

Now that we've got all the prerequisites for deployment let's proceed in deploying the raffle.

Let's open the `DeployRaffle.s.sol` and use our new tools.

First, import the newly created HelperConfig.

`import {HelperConfig} from "./HelperConfig.s.sol";`

Then, modify the run function:

```solidity
function run() external returns (Raffle, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
    (
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;

    ) = helperConfig.activeNetworkConfig();

}
```

Great! Now that we have deconstructed the NetworkConfig we have all the variables we need to deploy::

```solidity
vm.startBroadcast();
Raffle raffle = new Raffle(
    entranceFee,
    interval,
    vrfCoordinator,
    gasLane,
    subscriptionId,
    callbackGasLimit
)
vm.stopBroadcast();

return raffle;
```

We use the `vm.startBroadcast` and `vm.stopBroadcast` commands to indicate that we are going to send a transaction. The transaction is the deployment of a new `Raffle` contract using the parameters we've obtained from the `HelperConfig`. In the end, we are returning the newly deployed contract.

This code is good on its own, but, we can make it better. For example, we need a `subscriptionId`. We can either obtain this through the front end as we've learned in a previous lesson, or we can get on programmatically. For now, we'll leave everything as is, but we will refactor this in the future.

Before that, let's write some tests.

Inside the `test` folder create two new folders called `intergration` and `unit`. Here we'll put our integration and unit tests. Inside the newly created `unit` folder create a file called `RaffleTest.t.sol`.

Let's start writing the first test. You've already done this at least two times in this section. Try to do it on your own and come back when you get stuck.

Your unit test should start like this:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {

}
```

We've declared the SPDX-License-Identifier, the solidity version, imported the `DeployRaffle` which we will use to deploy our contract, then `Raffle` the contract to be deployed and then `Test` and `console` which are required for Foundry to function.

In `DeployRaffle.s.sol` we need to make sure that `run` also returns the `HelperConfig` contract:

```solidity
function run() external returns (Raffle, HelperConfig) {
    HelperConfig helperConfig = new HelperConfig();
    (
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) = helperConfig.activeNetworkConfig();

    vm.startBroadcast();
    Raffle raffle = new Raffle(
        entranceFee,
        interval,
        vrfCoordinator,
        gasLane,
        subscriptionId,
        callbackGasLimit
    );
    vm.stopBroadcast();

    return (raffle, helperConfig);
}
```

Next comes the state variables and `setUp` function in `RaffleTest.t.sol`:

```solidity
contract RaffleTest is Test {

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit

        ) = helperConfig.activeNetworkConfig();
    }
}
```

This seems like a lot, but it isn't, let's go through it.

-   We made `RaffleTest` contract inherit `Test` to enable the testing functionality;
-   We've defined a `raffle` and `helperConfig` variables to store the contracts;
-   Next, we defined the variables required for the deployment;
-   Then, we created a new user called `PLAYER` and defined how many tokens they should receive;
-   Inside the `setUp` function, we deploy the `DeployRaffle` contract then we use it to deploy the `Raffle` and `HelperConfig` contracts;
-   We `deal` the `PLAYER` the defined `STARTING_USER_BALANCE`;
-   We call `helperConfig.activeNetworkConfig` to get the Raffle configuration parameters.

Amazing! With all these done let's write a small test to ensure our `setUp` is functioning properly.

First, we need a getter function to retrieve the raffle state. Put the following towards the end of the `Raffle.sol`:

```solidity
function getRaffleState() public view returns (RaffleState) {
    return s_raffleState;
}
```

Inside `RaffleTest.t.sol` paste the following test:

```solidity
function testRaffleInitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
}
```

**Note**: we used `Raffle.RaffleState.OPEN` to get the value attributed to `OPEN` inside the `RaffleState` enum. This is possible because `RaffleState` is considered a [type](https://docs.soliditylang.org/en/latest/types.html#enums). So we can access that by calling the type `RaffleState` inside a `Raffle` contract to retrieve the `OPEN` value.

Great! Let's run the test and see how it goes:

`forge test --mt testRaffleInitializesInOpenState -vv`

The output being:

```Solidity
Ran 1 test for test/unit/RaffleTest.t.sol:RaffleTest
[PASS] testRaffleInitializesInOpenState() (gas: 7707)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 12.42ms (51.80µs CPU time)

Ran 1 test suite in 2.25s (12.42ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

## Deploy Script

Let's begin by creating a new file in the `/script` directory called `DeployRaffle.sol` and importing the `Raffle` contract.

```solidity
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
```

> 🗒️ **NOTE**:br
> There are two ways to import files in Solidity: using a direct path or a relative path. In this example, we are using a relative path, where the `Raffle.sol` file is inside the `src` directory but one level up (`..`) from the current file's location.

### The `deployContract` Function

Next, let's define a function called `deployContract` to handle the **deployment process**. This function will be similar to the one we used in the `FundMe` contract.

```solidity
contract DeployRaffle is Script {
    function run() external {
        deployContract();
    }

    function deployContract() internal returns (Raffle, HelperConfig) {
        // Implementation will go here
    }
}
```

To deploy our contract, we need various parameters required by the `Raffle` contract, such as `entranceFee`, `interval`, `vrfCoordinator`, `gasLane`, `subscriptionId`, and `callbackGasLimit`. The values for these parameters will vary _depending on the blockchain network we deploy to_. Therefore, we should create a `HelperConfig` file to specify these values based on the target deployment network.

### The `HelperConfig.s.sol` Contract

To retrieve the correct network configuration, we can create a new file in the same directory called `HelperConfig.s.sol` and define a **Network Configuration Structure**:

```solidity
contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
    }
}
```

We'll then define two functions that return the _network-specific configuration_. We'll set up these functions for Sepolia and a local network.

```solidity
function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
        entranceFee: 0.01 ether, // 1e16
        interval: 30, // 30 seconds
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        callbackGasLimit: 500000, // 500,000 gas
        subscriptionId: 0
    });
}

function getLocalConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
        entranceFee: 0.01 ether,
        interval: 30, // 30 seconds
        vrfCoordinator: address(0),
        gasLane: "",
        callbackGasLimit: 500000,
        subscriptionId: 0
    });
}
```

We will then create an abstract contract `CodeConstants` where we define some network IDs. The `HelperConfig` contract will be able to use them later through inheritance.

```solidity
abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
```

These values can be used inside the `HelperConfig` constructor:

> 👀❗**IMPORTANT**:br
> We are choosing the use of **constants** over magic numbers

```solidity
constructor() {
    networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
}
```

We also have to build a function to fetch the appropriate configuration based on the actual chain ID. This can be done first by verifying that a VRF coordinator exists. In case it does not and we are not on a local chain, we'll revert.

```solidity
function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
    if (networkConfigs[chainId].vrfCoordinator != address(0)) {
        return networkConfigs[chainId];
    } else if (chainId == LOCAL_CHAIN_ID) {
        return getOrCreateAnvilEthConfig();
    } else {
        revert HelperConfig__InvalidChainId();
    }
}
```

In case we are on a local chain but the VRF coordinator has already been set, we should use the existing configuration already created.

```solidity
function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    // Check to see if we set an active network config
    if (localNetworkConfig.vrfCoordinator != address(0)) {
        return localNetworkConfig;
}
```

This approach ensures that we have a robust configuration mechanism that adapts to the actual deployment environment

## Deploy a mock Chainlink VRF

A mock contract is a type of smart contract used in testing and development environments to simulate the behavior of real contracts. It allows us to create controlled and predictable scenarios for testing purposes without relying on actual external contracts or data sources. Moreover, it facilitates testing using Anvil, which is extremely fast and practical in comparison to a testnet.

In the last lesson, we stopped on `HelperConfig.s.sol`:

```solidity
function getOrCreateAnvilEthConfig()
    public
    returns (NetworkConfig memory anvilNetworkConfig)
{
    // Check to see if we set an active network config
    if (activeNetworkConfig.vrfCoordinator != address(0)) {
        return activeNetworkConfig;
    }
}
```

We need to treat the other side of the `(activeNetworkConfig.vrfCoordinatorV2 != address(0))` condition. What happens if that is false?

If that is false we need to deploy a mock vrfCoordinatorV2_5 and pass its address inside a `NetworkConfig` that will be used on Anvil.

Please use your Explorer on the left side to access the following path:

`foundry-smart-contract-lottery-cu/lib/chainlink/contracts/src/v0.8/vrf/`

Inside you'll find multiple folders, one of which is called `mocks`. Inside that folder, you can find the `VRFCoordinatorV2_5Mock` mock contract created by Chainlink.

Add the following line in the imports section of `HelperConfig.s.sol`:

```solidity
import {VRFCoordinatorV2_5Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
```

Now let's keep on working on the `getOrCreateAnvilEthConfig` function. We need to deploy the `vrfCoordinatorV2Mock`, but if we open it we'll see that its constructor requires some parameters:

```solidity
contract VRFCoordinatorV2_5Mock is SubscriptionAPI, IVRFCoordinatorV2Plus {
    uint96 public immutable i_base_fee;
    uint96 public immutable i_gas_price;
    int256 public immutable i_wei_per_unit_link;
}
```

The `i_base_fee` is the flat fee that VRF charges for the provided randomness. `i_gas_price` which is the gas consumed by the VRF node when calling your function. `i_wei_per_unit_link` is the LINK price in ETH in wei units. Given the way it's structured the callback gas is paid initially by the node which needs to be reimbursed.

We add the following lines to the `getOrCreateAnvilEthConfig` function:

```solidity
/* VRF Mock Values */
uint96 public constant MOCK_BASE_FEE = 0.25 ether;
uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

vm.startBroadcast();
VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
    MOCK_BASE_FEE,
    MOCK_GAS_PRICE_LINK,
    MOCK_WEI_PER_UNIT_LINK,
);
vm.stopBroadcast();
```

Now that we have everything we need, let's perform the return, similar to what we did in `getSepoliaEthConfig`.

```solidity
return NetworkConfig({
    entranceFee: 0.01 ether,
    interval: 30, // 30 seconds
    vrfCoordinator: address(vrfCoordinatorMock),
    // gasLane value doesn't matter.
    gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
    subscriptionId: 0,
    callbackGasLimit: 500_000,
});
```

## Test and deploy the lottery smart contract pt.2

We've written some amazing code, but you know our job here is not done! We need to test it. Let's be smart about testing, what do we need to be able to properly test the contract and what kind of tests shall we do?

**Plan:**

1. Write deploy scripts
2. Write tests
    1. Local chain
    2. Forked Testnet
    3. Forked Mainnet
3. Maybe deploy and run on Sepolia?

### Deployment scripts

Please create a new file called `DeployRaffle.s.sol` inside the `script` folder.

And now you know the drill, go write as much of it as you can! After you get stuck or after you finish come back and check it against the version below:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {

    function run() external returns (Raffle) {

    }
}
```

We've started with the traditional `SPDX` declaration, then specified the `pragma solidity` version. We imported the `Script` from Foundry and the `Raffle` contract because we want to do a Raffle deployment script, declared the contract's name and made it inherit `Script` and created the `run` function which will return our `Raffle` contract deployment. Great!

Let's work smart, looking again over the plan we see that we'll have to deploy the Raffle contract on at least 3 different chains. Let's stop here with the deployment script and work on the `HelperConfig`.

Create a new file called `HelperConfig.s.sol` in the `script` folder.

Inside let's create the `HelperConfig` contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

}
```

We start with the `SPDX ` and `pragma solidity` declarations. Then, we import `Script` from Foundry, name the contract and make it inherit `Script`. Cool! Now what do we need to deploy the `Raffle` contract? That information can be easily found in the `Raffle` contract's constructor:

`constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit)`

We created a new struct called `NetworkConfig` and we matched its contents with the Raffle's constructor input.

Great! Now let's design a function that returns the proper config for Sepolia:

```solidity
function getSepoliaEthConfig()
    public
    pure
    returns (NetworkConfig memory)
{
    return NetworkConfig({
        entranceFee: 0.01 ether,
        interval: 30, // 30 seconds
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        subscriptionId: 0, // If left as 0, our scripts will create one!
        callbackGasLimit: 500000, // 500,000 gas
    });
}
```

The function above returns a `NetworkConfig` struct with data taken from [here](https://docs.chain.link/vrf/v2-5/supported-networks#sepolia-testnet). The `interval`, `entranceFee` and `callbackGasLimit` were selected by Patrick.

Ok, we need a couple more things. We need a constructor that checks what blockchain we are on and attributes a state variable, let's call it `activeNetworkConfig`, the proper config for the chain used.

```solidity
NetworkConfig public activeNetworkConfig;
constructor() {
    if (block.chainid == 11155111) {
        activeNetworkConfig = getSepoliaEthConfig();
    } else {
        activeNetworkConfig = getOrCreateAnvilEthConfig();
    }
}
```

Good, we only missing the `getOrCreateAnvilEthConfig` function.

For now, let's create only a part of it:

```solidity
function getOrCreateAnvilEthConfig()
    public
    returns (NetworkConfig memory anvilNetworkConfig)
{
    // Check to see if we set an active network config
    if (activeNetworkConfig.vrfCoordinator != address(0)) {
        return activeNetworkConfig;
    }
}
```

We check if the `activeNetworkConfig` is populated, and if is we return it. If not we need to deploy some mocks. But more on that in the next lesson.

## Setup the tests

Let's jump straight into testing! But where do we start?

Easy! Let's call `forge coverage`:

```Solidity
Analysing contracts...
Running tests...
| File                      | % Lines       | % Statements   | % Branches    | % Funcs       |
| ------------------------- | ------------- | -------------- | ------------- | ------------- |
| script/DeployRaffle.s.sol | 100.00% (7/7) | 100.00% (9/9)  | 100.00% (0/0) | 100.00% (1/1) |
| script/HelperConfig.s.sol | 0.00% (0/9)   | 0.00% (0/13)   | 0.00% (0/2)   | 0.00% (0/2)   |
| src/Raffle.sol            | 2.94% (1/34)  | 2.33% (1/43)   | 0.00% (0/8)   | 7.69% (1/13)  |
| Total                     | 16.00% (8/50) | 15.38% (10/65) | 0.00% (0/10)  | 12.50% (2/16) |
```

These numbers are weak! Let's improve them!

Open the `RaffleTest.t.sol` inside the `test/unit` folder.

In my opinion, when one needs to decide where to start testing there are two sensible approaches one could take:

1. Easy to Complex - start with view functions, then with smaller functions and advance to the more complex functions;
2. From the main entry point(s) to the periphery - what is the main functionality that the external user needs to call in order to interact with your contract;

Patrick chose number 2. So what is the main entry point of our Raffle contract? The `enterRaffle` function.

Let's look closely at it:

```solidity
function enterRaffle() external payable {
    if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
    if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

    s_players.push(payable(msg.sender));
    emit EnteredRaffle(msg.sender);
}
```

1. We check if the `msg.value` is high enough;
2. We check if the `RaffleState` is `OPEN`;
3. If all of the above are `true` then the `msg.sender` should be pushed in the `s_players` array;
4. Our function emits the `EnteredRaffle` event.

Let's test point 1:

```solidity
function testRaffleRevertsWHenYouDontPayEnough() public {
    // Arrange
    vm.prank(PLAYER);
    // Act / Assert
    vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
    raffle.enterRaffle();
}
```

We call `vm.prank(PLAYER)` to configure the fact that the next transaction will be called by the `PLAYER`. [Refresher](https://book.getfoundry.sh/cheatcodes/prank?highlight=prank#prank)

After that we use the `vm.expectRevert` [cheatcode](https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert#expectrevert) to test if the next call will revert. We also have the option to specify the error message. You can do that by calling the `errorName.selector` as input of the `vm.expectRevert` cheatcode. Following that we call the `enterRaffle` without specifying the `value` of the transaction.

Run the test using `forge test --mt testRaffleRevertsWHenYouDontPayEnought`.

```Solidity
Ran 1 test for test/unit/RaffleTest.t.sol:RaffleTest
[PASS] testRaffleRevertsWHenYouDontPayEnought() (gas: 10865)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.99ms (161.70µs CPU time)
```

We will skip point 2 for now, let's go straight to point 3:

But before being able to test if a player is properly recorded in the `s_players` array we first need a view function to access the players in the `s_players`:

```solidity
function getPlayer(uint256 index) public view returns (address) {
    return s_players[index];
}
```

Now that we have all the tools we need:

```solidity
function testRaffleRecordsPlayerWhenTheyEnter() public {
    // Arrange
    vm.prank(PLAYER);
    // Act
    raffle.enterRaffle{value: entranceFee}();
    // Assert
    address playerRecorded = raffle.getPlayer(0);
    assert(playerRecorded == PLAYER);
}
```

We start by pranking the PLAYER, then properly calling the `enterRaffle` function specifying the correct `value`. We call the new `getPLayer` function to copy the player recorded at index 0 in memory. Then we compare that value to the `PLAYER` address to ensure they match.

Test it with the following command: `forge test --mt testRaffleRecordsPlayerWhenTheyEnter`.

Amazing work! Let's continue in the next lesson! We are going to learn how to test events in Foundry.

## Headers

To effortlessly create elegant **function** or **section headers** in your contract, you can use the [headers tool](https://github.com/transmissions11/headers) from transmission11. This tool generates code such as:

```js
/*//////////////////////////////////////////////////////////////
                           ENTER RAFFLE
//////////////////////////////////////////////////////////////*/
```

## Adding more tests

Welcome back! Let's continue testing our `Raffle` contract.

We should test if the check upkeep returns false if the contract has no balance. Open your `RaffleTest.t.sol` and write the following:

```solidity
function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
    // Arrange
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    // Act
    (bool upkeepNeeded, ) = raffle.checkUpkeep("");

    // Assert
    assert(!upkeepNeeded);
}
```

We use `warp` and `roll` to set the `block.timestamp` in the future. We call `checkUpkeep` and record its return in memory. We check it returned `false`.

**Note:** `!upkeepNeeded` means `not upkeepNeeded` meaning if `upkeepNeeded` is `false` that expression would read `not false` and `not false` is `true`.

Run the test using `forge test --mt testCheckUpkeepReturnsFalseIfItHasNoBalance`.

It passes, amazing!

What else? We should test if the check upkeep function returns false if the raffle is not Open. Paste the following inside `RaffleTest.t.sol`:

```solidity
function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    // Act
    (bool upkeepNeeded, ) = raffle.checkUpkeep("");
    // Assert
    assert(raffleState == Raffle.RaffleState.CALCULATING);
    assert(upkeepNeeded == false);
}
```

We start by pranking the `PLAYER`. Then we enter the `raffle` using the correct `entranceFee`. After that, we use `warp` and `roll` to set `block.timestamp` in the future. We call `performUpkeep`. This will modify the `RaffleState` into `CALCULATING`. We then call `checkUpkeep` and record its return in memory. We check it returned `false`. We also check that the `RaffleState` is indeed `CALCULATING`.

Run the test using: `forge test --mt testCheckUpkeepReturnsFalseIfRaffleIsntOpen`.

It passes, great!

So testing goes amazing, but how do we know what's left to test? Let's run the following command in the CLI:

`forge coverage --report debug > coverage.txt`

We are interested in the `Raffle.sol` file for now. You can search for that and see an output like this:

```Solidity
Uncovered for src/Raffle.sol:
- Function "" (location: source ID 37, line 53, chars 1729-2253, hits: 0)
- Line (location: source ID 37, line 54, chars 1913-1940, hits: 0)
- Statement (location: source ID 37, line 54, chars 1913-1940, hits: 0)
- Line (location: source ID 37, line 55, chars 1950-1971, hits: 0)
- Statement (location: source ID 37, line 55, chars 1950-1971, hits: 0)
- Line (location: source ID 37, line 56, chars 1981-2014, hits: 0)
- Statement (location: source ID 37, line 56, chars 1981-2014, hits: 0)
- Line (location: source ID 37, line 57, chars 2024-2056, hits: 0)
- Statement (location: source ID 37, line 57, chars 2024-2056, hits: 0)
- Line (location: source ID 37, line 59, chars 2067-2127, hits: 0)
- Statement (location: source ID 37, line 59, chars 2067-2127, hits: 0)
- Line (location: source ID 37, line 60, chars 2137-2156, hits: 0)
- Statement (location: source ID 37, line 60, chars 2137-2156, hits: 0)
- Line (location: source ID 37, line 61, chars 2166-2199, hits: 0)
- Statement (location: source ID 37, line 61, chars 2166-2199, hits: 0)
- Line (location: source ID 37, line 62, chars 2209-2246, hits: 0)
- Statement (location: source ID 37, line 62, chars 2209-2246, hits: 0)
- Branch (branch: 2, path: 0) (location: source ID 37, line 97, chars 3717-3918, hits: 0)
- Branch (branch: 2, path: 1) (location: source ID 37, line 97, chars 3717-3918, hits: 0)
- Line (location: source ID 37, line 98, chars 3750-3907, hits: 0)
[...]
```

You can follow the locations indicated to find the lines not covered by tests. For example, in my `Raffle.sol` the code block starting on line 97 is this:

```solidity
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
@>      if (!upkeepNeeded) {
@>          revert Raffle__UpkeepNotNeeded(
@>              address(this).balance,
@>              s_players.length,
@>              uint256(s_raffleState)
@>          );
        }
```

And the output is right, we never tested this `if + revert` block inside `performUpkeep`.

But beware! This is not entirely accurate. For example, `checkUpkeep` doesn't appear in the report anymore, but we didn't test every single line out of it. We never tested if the upkeep returns false if enough time hasn't passed, we also never checked if the upkeep returns true when everything is alright.

Try writing these two tests yourself and then compare them against what [Patrick wrote](https://github.com/Cyfrin/foundry-smart-contract-lottery-f23/blob/d106fe245e0e44239dae2479b63545351ed1236a/test/unit/RaffleTest.t.sol).

Great job! Let's keep going!

## Testing events

Picking up from where we left in the previous lesson. The only point left is:

`` 4. Our function emits the `EnteredRaffle` event. ``

Before jumping into the test writing we need to look a bit into the cheatcode that we can use in Foundry to test events: [expectEmit](https://book.getfoundry.sh/cheatcodes/expect-emit?highlight=expectEm#expectemit).

The first step is to declare the event inside your test contract.

So, inside `RaffleTest.t.sol` declare the following event:

`event EnteredRaffle(address indexed player);`

Then we proceed to the test:

```solidity
function testEmitsEventOnEntrance() public {
    // Arrange
    vm.prank(PLAYER);

    // Act / Assert
    vm.expectEmit(true, false, false, false, address(raffle));
    emit EnteredRaffle(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
}
```

-   We prank the `PLAYER`
-   We call the `expectEmit` cheatcode - `vm.expectEmit(true, false, false, false, address(raffle));`
    I know this looks a bit weird. But let's look at what `expectEmit` expects:
    ```solidity
    function expectEmit(
      bool checkTopic1,
      bool checkTopic2,
      bool checkTopic3,
      bool checkData,
      address emitter
    ) external;
    ```
    The `checkTopic` 1-3 corresponds to the `indexed` parameters we are using inside our event. The `checkData` corresponds to any unindexed parameters inside the event, and, finally, the `expectEmit` expects the address that emitted the event. It looks like this `vm.expectEmit(true, false, false, false, address(raffle));` because we only have one indexed parameter inside the event.
-   We need to manually emit the event we expect to be emitted. That's why we declared it earlier;
-   We make the function call that should emit the event.

Run the test using the following command: `forge test --mt testEmitsEventOnEntrance`

Everything passes, amazing!

## Using vm.roll and vm.warp

In lesson 19, we skipped testing one of the four steps of `enterRaffle`: `` 2. We check if the `RaffleState` is `OPEN`; ``

To rephrase it, a user should not be able to enter if the `RaffleState` is `CALCULATING`.

```solidity
function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    // Act / Assert
    vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
}
```

We start our test exactly like the others. We `prank` the `PLAYER` and we call `enterRaffle` specifying the appropriate `msg.value` so our user registers properly.

The following step involves calling two new cheatcodes:

-   [vm.warp](https://book.getfoundry.sh/cheatcodes/warp?highlight=warp#warp) which sets the `block.timestamp`;
-   [vm.roll](https://book.getfoundry.sh/cheatcodes/roll?highlight=roll#roll) which sets the `block.number`;

Even though we don't use them here it's important to know that there are other `block.timestamp` manipulation cheatcodes that you'll encounter in your development/security path.

-   [skip](https://book.getfoundry.sh/reference/forge-std/skip) which skips forward the `block.timestamp` by the specified number of seconds;
-   [rewind](https://book.getfoundry.sh/reference/forge-std/rewind) which is the antonym of `skip`, i.e. it rewinds the `block.timestamp` by a specified number of seconds;

So we use the `vm.warp` and `vm.roll` to push the `block.timestamp` and `block.number` in the future.

We call `performUpkeep` to change the `RaffleState` to `CALCULATING`.

Following that we call the `vm.expectRevert` cheatcode, expecting to revert the next call with the `Raffle__RaffleNotOpen` error.

The last step is pranking the `PLAYER` again and calling `enterRaffle` to check if it reverts as it should.

Run the test using `forge test --mt testDontAllowPlayersToEnterWhileRaffleIsCalculating`

```Solidity
Ran 1 test for test/unit/RaffleTest.t.sol:RaffleTest
[FAIL. Reason: InvalidConsumer()] testDontAllowPlayersToEnterWhileRaffleIsCalculating() (gas: 101956)
Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 2.70ms (206.20µs CPU time)
```

OH NO! `[FAIL. Reason: InvalidConsumer()]` ... we gonna fix this one soon, I promise!

## Creating a subscription

Picking up from where we left in the previous lesson. Our test failed pointing to some error named `InvalidConsumer()`. Let's rerun the test with verbosity to see where is the problem:

`forge test --mt testDontAllowPlayersToEnterWhileRaffleIsCalculating -vvvvv`

At the end, we see this:

```Solidity
    ├─ [31556] Raffle::performUpkeep(0x)
    │   ├─ [5271] VRFCoordinatorV2Mock::requestRandomWords(0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, 0, 3, 500000 [5e5], 1)
    │   │   └─ ← [Revert] InvalidConsumer()
    │   └─ ← [Revert] InvalidConsumer()
    └─ ← [Revert] InvalidConsumer()
```

It looks like when we call `performUpkeep` it internally calls `requestRandomWords`, and somewhere inside we hit an error.

Go to `HelperConfig.s.sol` and try to follow the path of the `VRFCoordinatorV2Mock`. Inside we can see why our function failed:

```solidity
modifier onlyValidConsumer(uint64 _subId, address _consumer) {
    if (!consumerIsAdded(_subId, _consumer)) {
        revert InvalidConsumer();
    }
    _;
}

```

This modifier checks if our consumer is added to the `subscriptionId` we've provided. We didn't do that and that's why it fails.

If you remember, we did this using the Chainlink UI in [Lesson 6](https://updraft.cyfrin.io/courses/foundry/smart-contract-lottery/solidity-random-number-chainlink-vrf). But we are developers, we need to do this programmatically.

We need to update the deployment script to make sure we can run the failing test.

Open `DeployRaffle.s.sol`.

The first order of business is to ensure we have a valid `subscriptionId`. If we have one, our test should pick it up, if we don't have one then we should create one.

Inside the `script` folder create a new file called `Interactions.sol`. This is where we'll take care of the subscription creation.

Let's start with the basics:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

contract CreateSubscription is Script {

}
```

Every script needs a `run` function. Inside the `run` function we will call the `createSubscriptionUsingConfig`.

```solidity
function createSubscriptionUsingConfig() public returns (uint64) {
}

function run() external returns (uint64) {
    return createSubscriptionUsingConfig();
}
```

Let's pause and talk about what we are doing and what we need to make things happen. Thinking back about what we did in Lesson 6. We created a subscription, we added a consumer and we funded the subscription. Open the `VRFCoordinatorV2Mock` and let's look for functions that we need to do it programmatically:

```solidity
function createSubscription() external override returns (uint64 _subId) {
    s_currentSubId++;
    s_subscriptions[s_currentSubId] = Subscription({owner: msg.sender, balance: 0});
    emit SubscriptionCreated(s_currentSubId, msg.sender);
    return s_currentSubId;
}

[...]

function addConsumer(uint64 _subId, address _consumer) external override onlySubOwner(_subId) {
    if (s_consumers[_subId].length == MAX_CONSUMERS) {
        revert TooManyConsumers();
    }

    if (consumerIsAdded(_subId, _consumer)) {
        return;
    }

    s_consumers[_subId].push(_consumer);
    emit ConsumerAdded(_subId, _consumer);
}

[...]

function fundSubscription(uint64 _subId, uint96 _amount) public {
    if (s_subscriptions[_subId].owner == address(0)) {
        revert InvalidSubscription();
    }
    uint96 oldBalance = s_subscriptions[_subId].balance;
    s_subscriptions[_subId].balance += _amount;
    emit SubscriptionFunded(_subId, oldBalance, oldBalance + _amount);
}
```

Great! Now we need to call all of them, but before that, we first need to pull the VRFv2 address, available in the `HelperConfig`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            ,
            ,
        ) = helperConfig.activeNetworkConfig();

        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64) {}


    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}
```

As we said above, we created a `run` function that calls `createSubscriptionUsingConfig`. This function deploys the `HelperConfig` to grab the `vrfCoordinator` and inside the return statement, we call the `createSubscription` function. For that to work, we need to define the `createSubscription` function, which takes the `vrfCoordinator` address as an input. This is where we create the actual subscription.

Amazing! Let's work on the `createSubscription` function. We need to import some things to make it work. First, let's update the contract in order to import `console`, to log a message every time we create a subscription. Second, let's import the `VRFCoordinatorV2Mock` to be able to call the functions we specified above.

```solidity
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
```

Perfect, not let's finish the `createSubscription`:

```solidity
function createSubscription(
    address vrfCoordinator
) public returns (uint64) {
    console.log("Creating subscription on ChainID: ", block.chainid);
    vm.startBroadcast();
    uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
    vm.stopBroadcast();
    console.log("Your sub Id is: ", subId);
    console.log("Please update subscriptionId in HelperConfig!");
    return subId;
}
```

First, we log the `Creating subscription` message. Then, we encapsulate the `VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();` call inside the `vm.startBroadcast` and `vm.stopBroadcast` block. We assign the return of the `VRFCoordinatorV2Mock(vrfCoordinator).createSubscription` call to `uint64 subId` variable. Then we log the `subId` and return it to end the function.

Amazing work! Coming back to `DeployRaffle.s.sol`, we should create a subscription if we don't have one, like this:

```solidity
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        (
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);
        }


        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
```

We import the newly created `CreateSubscription` contract from `Interactions.s.sol`. After the `helperConfig` definition, we check if our `subscriptionId` is 0. If that yields true then we don't have a `subscriptionId` and we need to create one. We use the new functions inside the `CreateSubscription` to get an appropriate `subscriptionId`.

## Creating a subscription using the UI

Let's learn how to create a subscription using the Chainlink UI.

First, you need to access this link: <https://vrf.chain.link/sepolia>

Click on `Create Subscription`. On the next page, it's not necessary to put in any email address or project name. Click again on `Create Subscription`. Your Metamask will pop up, click on approve to approve the subscription creation. Wait to receive the confirmation then sign the message. After everything is confirmed you will be prompted to add funds, but let's not do that right now.

Access the [first link](https://vrf.chain.link/sepolia) again. In this dashboard, you will see your new subscription in the `My Subscriptions` section. You could add this in your `HelperConfig` in the Sepolia section and everything would work.

Click on the id. On this page, you can see various information about your subscription like Network, ID, admin address, registered consumers and balance. As you can see the balance is 0, thus, we need to fund it with LINK.

Before going on with that we need to make sure we have Sepolia LINK in our wallet. Please visit the <https://faucets.chain.link/> link and request some testnet funds. Tick both LINK and Sepolia ETH. Make sure to log in using your GitHub to pass Chainlink's verification. Click on `Send request` and wait for the funds to arrive.

Follow Patrick's guidance to add LINK token to your wallet on Sepolia testnet.

Back on the subscription tab, click on the top-right button called `Actions` then click on `Fund Subscription`. Select `LINK`, enter the `Amount to fund` and click on `Confirm`. Wait for the funds to arrive.

This process was simple, but we can make it even smoother via forge scripts.

## Funding a subscription programmatically

In the previous lessons, we learned how to create a subscription using both the Chainlink UI and programmatically. Let's see how we can fund the subscription programmatically.

This is what the subscription creation snippet from `DeployRaffle` looks like:

```solidity
if (subscriptionId == 0) {
    CreateSubscription createSubscription = new CreateSubscription();
    (subscriptionId, vrfCoordinator) = createSubscription.createSubscription(vrfCoordinator);
}
```

Below the `subscriptionId` line, we need to continue with the funding logic.

For that let's open the `Interactions.s.sol` and below the existing contract create another contract called `FundSubscription`:

```solidity
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
```

I know this step looks very similar to what we did in the subscription creation lesson. That is completely fine and desirable!

One thing we need and we currently don't have configured is the LINK token. If you remember in the previous lesson, we funded our subscription with LINK, and we need to do the same thing here.

What do we need:

1. Sepolia testnet has already a LINK contract deployed, we need to have that address easily accessible inside our `HelperConfiguration`. To always make sure you get the correct LINK contract access the following [link](https://docs.chain.link/resources/link-token-contracts?parent=vrf).
2. Anvil doesn't come with a LINK contract deployed. We need to deploy a mock LINK token contract and use it to fund our subscription.

Let's start modifying our `HelperConfig.s.sol`:

```solidity
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
    }
[...]

    function getSepoliaEthConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, // 30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0, // If left as 0, our scripts will create one!
            callbackGasLimit: 500000, // 500,000 gas
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }
```

We've added the LINK address in the `NetworkConfig` struct and hardcoded it in the `getSepoliaEthConfig` function. This modification also requires some adjustments in the `Interactions.s.sol`:

Now the fun part! Patrick conveniently provided us with a mock LINK token contract. You can access it [here](https://github.com/Cyfrin/foundry-smart-contract-lottery-cu/blob/efac6e2a5c2df6d1936d117f40f93575d25cf694/test/mocks/LinkToken.sol).

Inside the `test` folder, create a new folder called `mocks`. Inside that, create a new file called `LinkToken.sol`. Copy Patrick's contract in the new file. Looking through it, we can see that it imports ERC20 from a library called Solmate which self-describes itself as a `Modern, opinionated, and gas optimized building blocks for smart contract development`. We need to install it with the following command:

`forge install transmissions11/solmate --no-commit`

Add the following line inside your `remappings.txt`:

`@solmate/=lib/solmate/src`

Back in our `HelperConfig.s.sol` we need to import the LinkToken:

```solidity
import {LinkToken} from "test/mocks/LinkToken.sol";
```

And now, with this new import, we can deploy the token in case we use Anvil like so:

```solidity
function getOrCreateAnvilEthConfig() internal returns (NetworkConfig memory) {
    // Check to see if we set an active network config
    if (localNetworkConfig.vrfCoordinator != address(0)) {
        return localNetworkConfig;
    }

    // Deploy mocks, etc
    vm.startBroadcast();
    VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
        MOCK_BASE_FEE,
        MOCK_GAS_PRICE_LINK,
        MOCK_WEI_PER_UNIT_LINK
    );
    LinkToken linkToken = new LinkToken();
    vm.stopBroadcast();

    localNetworkConfig = NetworkConfig({
        entranceFee: 0.01 ether,
        interval: 30, // 30 seconds
        vrfCoordinator: address(vrfCoordinatorMock),
        // Doesn't matter for the gasLane value
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        subscriptionId: 0,
        callbackGasLimit: 500_000,
        linkToken: address(linkToken)
    });

    return localNetworkConfig;
}
```

Amazing work!

Now we need to look through our code and make sure we have enough fields everywhere we use the `NetworkConfig` struct, which increased from 6 fields to 7 fields because we've added the link address.

Most people don't remember all the places, and that's alright. Run `forge build`.

It should look something like this:

```Solidity
[⠒] Solc 0.8.24 finished in 1.34s
Error:
Compiler run failed:
Error (7364): Different number of components on the left hand side (6) than on the right hand side (7).
  --> script/DeployRaffle.s.sol:12:9:
   |
12 |         (
   |         ^ (Relevant source part starts here and spans across multiple lines).

Error (7407): Type tuple(uint256,uint256,address,bytes32,uint64,uint32,address) is not implicitly convertible to expected type tuple(uint256,uint256,address,bytes32,uint64,uint32).
  --> test/unit/RaffleTest.t.sol:42:13:
   |
42 |         ) = helperConfig.localNetworkConfig();
   |             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Even if this looks scary, it tells you where you need to perform the changes.

Control + Click the paths (`script/DeployRaffle.s.sol:12:9:`) to go to the broken code and fix it by making sure it takes the newly added `address linkToken` parameter.

Inside the `Raffle.t.sol` make sure to define the `address linkToken` in the state variables section. Then add it in here as well:

```solidity
HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
entranceFee = config.entranceFee;
interval = config.interval;
vrfCoordinator = config.vrfCoordinator;
gasLane = config.gasLane;
subscriptionId = config.subscriptionId;
callbackGasLimit = config.callbackGasLimit;
linkToken = LinkToken(config.linkToken);
```

And then, import our mock Link token contract:

```solidity
import {LinkToken} from "test/mocks/LinkToken.sol";
```

Take care of both the places where we call `HelperConfig()` to set our config inside `Interactions.s.sol`:

```solidity
function fundSubscriptionUsingConfig() public {
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
    uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
    address linkToken = helperConfig.getConfig().linkToken;

    fundSubscription(vrfCoordinator, subscriptionId, linkToken);
}
```

```solidity
function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
    console.log("Funding subscription: ", subscriptionId);
    console.log("Using vrfCoordinator: ", vrfCoordinator);
    console.log("On chainId: ", block.chainid);

    if(block.chainid == ETH_ANVIL_CHAIN_ID) {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
        vm.stopBroadcast();
    } else {
        console.log(LinkToken(linkToken).balanceOf(msg.sender));
        console.log(msg.sender);
        console.log(LinkToken(linkToken).balanceOf(address(this)));
        console.log(address(this));
        vm.startBroadcast();
        LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
        vm.stopBroadcast();
    }
}
```

Try another `forge build`. This time it compiled on my side, but if it didn't compile on your side just keep control clicking through the errors and fixing them. If you get stuck please come on Cyfrin Discord in the Updraft section and ask for help.

Great! Now our script uses the right LINK address when we work on Sepolia, and deploys a new LinkToken when we work on Anvil.

Let's come back to `Interactions.s.sol` and finish our `FundSubscription` contract:

```solidity
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().linkToken;

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subscriptionId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log("New SubId Created! ", subscriptionId, "VRF Address: ", vrfCoordinator);
        }

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chainId: ", block.chainid);

        if(block.chainid == ETH_ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(linkToken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(linkToken).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}
```

This seems like a lot, but it isn't, let's go through it step by step:

-   Like any other Script our's has a `run` function that gets executed
-   Inside we call the `fundSubscriptionUsingConfig` function
-   Inside the `fundSubscriptionUsingConfig` function we get the `activeNetworkConfig` that provides the chain-appropriate `vrfCoordinator`, `subscriptionId` and `link` token address
-   At the end of `fundSubscriptionUsingConfig` we call the `fundSubscription`, a function that we are going to define
-   We define `fundSubscription` as a public function that takes the 3 parameters as input
-   We console log some details, this will help us debug down the road
-   Then using an `if` statement we check if we are using Anvil, if that's the case we'll use the `fundSubscription` method found inside the `VRFCoordinatorV2_5Mock`
-   If we are not using Anvil, it means we are using Sepolia. The way we fund the Sepolia `vrfCoordinator` is by using the LINK's `transferAndCall` function.

**Note:** The `transferAndCall` function is part of the `ERC-677 standard`, which extends the `ERC-20` token standard by adding the ability to execute a function call in the recipient contract immediately after transferring tokens. This feature is particularly useful in scenarios where you want to atomically transfer tokens and trigger logic in the receiving contract within a single transaction, enhancing efficiency and reducing the risk of reentrancy attacks. In the context of Chainlink, the LINK token implements the `transferAndCall` function. When a smart contract wants to request data from a Chainlink oracle, it uses this function to send LINK tokens to the oracle's contract address while simultaneously encoding the request details in the \_data parameter. The oracle's contract then decodes this data to understand what service is being requested.

Don't worry! You'll get enough opportunities to understand these on the way to becoming the greatest Solidity dev/auditor!

For now, let's run a `forge build`. Everything compiles, great!

Take a break and continue watching Patrick running the newly created script to fund the subscription he created via the UI in the past lesson.

## Adding a consumer

Remember how everything started from a simple and inoffensive `InvalidConsumer()` error? Now it's the moment we finally fix it!

Open `Interactions.s.sol` and create a new contract:

```solidity
contract AddConsumer is Script {
    function run() external {

    }
}
```

To be able to add a consumer we need the most recent deployment of the `Raffle` contract. To grab it we need to install the following:

`forge install Cyfrin/foundry-devops --no-commit`

Import it at the top of the `Interactions.s.sol`:

`import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";`

Update the `run` function to get the address and call `addConsumerUsingConfig(raffle)`:

```solidity
    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("MyContract", block.chainid);
        addConsumerUsingConfig(raffle);
    }
```

And right about now, everything should feel extremely familiar. Let's define `addConsumerUsingConfig` and all the rest:

```Solidity
contract AddConsumer is Script {

    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionId) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using VRFCoordinator: ", vrfCoordinator);
        console.log("On chain id: ", block.chainid);

        vm.startBroadcast();
        VRFCoordinacontractToAddToVrftorV2Mock(vrfCoordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
        ) = helperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subscriptionId);

    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("MyContract", block.chainid);
        addConsumerUsingConfig(raffle);
    }

}
```

So... what happened here?

1. We used `DevOpsTools` to grab the last deployment of the `Raffle` contract inside the `run` function;
2. We also call `addConsumerUsingConfig` inside the `run` function;
3. We define `addConsumerUsingConfig` as a public function taking an address as an input;
4. We deploy a new `HelperConfig` and call `activeNetworkConfig` to grab the `vrfCoordinato` and `subscriptionId` addresses;
5. We call the `addConsumer` function;
6. We define `addConsumer` as a public function taking 3 input parameters: address of the `raffle` contract, address of `vrfCoordinator` and `subscriptionId`;
7. We log some things useful for debugging;
8. Then, inside a `startBroadcast`- `stopBroadcast` block we call the `addConsumer` function from the `VRFCoordinatorV2Mock` using the right input parameters;

Try a nice `forge build` and check if everything is compiling. Perfect!

Let's go back to `DeployRaffle.s.sol` and import the thing we added in `Interactions.s.sol`:

`import {CreateSubscription, FundSubscription, AddConsummer} from "./Interactions.s.sol";`

Now let's integrate the `FundSubscription` with the `CreateSubscription` bit:

```solidity
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link);
        }
```

So we created a subscription and funded it. Following on the `DeploymentRaffle` script deploys the `Raffle` contract. Now, that we have its address, we can add it as a consumer.

Great work!

Remember what got us on this path. All we wanted to do was call the `testDontAllowPlayersToEnterWhileRaffleIsCalculating` test from `RaffleTest.t.sol`. Let's try that again now:

`forge test --mt testDontAllowPlayersToEnterWhileRaffleIsCalculating -vv`

```Solidity
Ran 1 test for test/unit/RaffleTest.t.sol:RaffleTest
[PASS] testDontAllowPlayersToEnterWhileRaffleIsCalculating() (gas: 151240)
Logs:
  Creating subscription on ChainID:  31337
  Your sub Id is:  1
  Please update subscriptionId in HelperConfig!
  Funding subscription:  1
  Using vrfCoordinator:  0x90193C961A926261B756D1E5bb255e67ff9498A1
  On ChainID:  31337
  Adding consumer contract:  0x50EEf481cae4250d252Ae577A09bF514f224C6C4
  Using VRFCoordinator:  0x90193C961A926261B756D1E5bb255e67ff9498A1
  On chain id:  31337

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 11.06ms (102.80µs CPU time)
```

Amazing work!

There is a lot more to do in this section, but you are a true hero for reaching this point, take a well-deserved break! See you in the next one!

## Event More Tests

In this lesson we are going to build a couple more tests. If we check our code coverage with `forge coverage`, the terminal will show that we are only at around 53% coverage for the `Raffle.sol` contract. Code coverage refers to the percentage of lines of code that have been tested.

> 💡 **TIP**:br
> Achieving 100% coverage isn't always required, but it is a recommended target.

### `checkUpkeep` tests

To improve our coverage, we need to write additional tests. For example we can address the `checkUpkeep` function, to ensure it really executes as intended under various circumstances.

1. Let’s start by ensuring that `checkUpkeep` returns `false` when there is no balance. We’ll do this by setting up our test environment similarly to previous tests but without entering the raffle. Here’s the code:

    ```solidity
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
            // Arrange
            vm.warp(block.timestamp + automationUpdateInterval + 1);
            vm.roll(block.number + 1);

            // Act
            (bool upkeepNeeded,) = raffle.checkUpkeep("");

            // Assert
            assert(!upkeepNeeded);
     }
    ```

2. Next, we want to assert that `checkUpkeep` returns `false` when the raffle is in a _not open_ state. To do this, we can use a setup similar to our previous test:

    ```solidity
    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
            // Arrange
            vm.prank(PLAYER);
            raffle.enterRaffle{value: raffleEntranceFee}();
            vm.warp(block.timestamp + automationUpdateInterval + 1);
            vm.roll(block.number + 1);
            raffle.performUpkeep("");
            Raffle.RaffleState raffleState = raffle.getRaffleState();

            // Act
            (bool upkeepNeeded,) = raffle.checkUpkeep("");

            // Assert
            assert(raffleState == Raffle.RaffleState.CALCULATING);
            assert(upkeepNeeded == false);
     }
    ```

### Conclusion

By writing these additional tests, we enhance our test coverage rate, improve the reliability of our `Raffle.sol` contract, and check that `checkUpkeep` behaves correctly under various conditions.

## Coverage Report

To better identify which lines of code are covered, we can generate a detailed coverage report.

The following command will create a file called `coverage.txt`, containing the specific lines of code that have not been covered yet.

```bash
forge coverage --report debug > coverage.txt
```

Looking into this file, we can see all specific areas that require test coverage. For example, at line 65, we need to verify if all parameters in the constructor are set correctly. Similarly, line 73 lacks a check for the entrance fee value. Line 129 indicates that we also need to verify the `upkeepNotNeeded` revert statement.By systematically addressing these uncovered lines, we can significantly enhance our test coverage.

We should improve our test suite by writing additional tests. Here are some specific tests you might want to write yourself:

* [testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed](https://github.com/Cyfrin/foundry-smart-contract-lottery-cu/blob/083ebe5843573edfaa52fb002613b87d36d0d466/test/unit/RaffleTest.t.sol#L140)
* [testCheckUpkeepReturnsTrueWhenParametersGood](https://github.com/Cyfrin/foundry-smart-contract-lottery-cu/blob/083ebe5843573edfaa52fb002613b87d36d0d466/test/unit/RaffleTest.t.sol#L153C14-L153C58)

> 🗒️ **NOTE**:br
> You don't need to submit a pull request or make any course-related updates. This exercise is for your benefit to increase your testing skills.

## Testing and refactoring the performUpkeep

Let's give some love to `performUpkeep`, starting with some tests.

Starting light, open the `RaffleTest.t.sol` and paste the following:

```solidity
function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
    // Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    // Act / Assert
    // It doesnt revert
    raffle.performUpkeep("");
}
```

We prank the `PLAYER` address, then use it to call `enterRaffle` with the correct `entranceFee`. We use the `warp` and `roll` to set `block.timestamp` into the future. Lastly, we call `performUpkeep`.

As you've figured out, we are not running any asserts here. But that is ok because if `performUpkeep` had a reason to fail, then it would have reverted and our `forge test` would have caught it.

Run the test using: `forge test --mt testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue`

It passes, amazing!

Keep going! Let's test if `performUpkeep` reverts in case `checkUpkeep` is false:

```solidity
function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
    // Arrange
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.getRaffleState();
    // Act / Assert
    vm.expectRevert(
        abi.encodeWithSelector(
            Raffle.Raffle__UpkeepNotNeeded.selector,
            currentBalance,
            numPlayers,
            rState
        )
    );
    raffle.performUpkeep("");
}
```

This can be understood easier if we start from the end. We want to call `performUpkeep` and we expect it to revert. For that, we use the `vm.expectRevert` to indicate that we expect the next call to revert. If we access [this link](https://book.getfoundry.sh/cheatcodes/expect-revert) we can see that in case we use a custom error with parameters we can specify them as follows:

```solidity
vm.expectRevert(
    abi.encodeWithSelector(CustomError.selector, 1, 2)
);
```

In our case the custom error has 3 parameters:

```solidity
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);
```

First parameter: `Raffle.Raffle__UpkeepNotNeeded.selector`;
Second parameter: `currentBalance`;
Third parameter: `numPlayers`;
Fourth parameter: `raffleState`;

Out of all of them, the only one available is the first. We define a `currentBalance` and `numPlayers` and assign them both 0. To get the `raffleState` we can use the `getRaffleState` view function.

Run the test using: `forge test --mt testPerformUpkeepRevertsIfCheckUpkeepIsFalse`

Everything passes, great!

I know some concepts haven't been explained. I'm referring to `encodeWithSelector` and the general concept of function selectors. These will be introduced in the next sections.

Great work! Now let's further explore events.

## Refactoring events data

In this lesson, we will learn how to access event data inside our tests.
Let's create a new event and emit it in `performUpkeep` to test something.
Inside `Raffle.sol` in the events section create a new event:
`event RequestedRaffleWinner(uint256 indexed requestId);`
Emit the event at the end of the `performUpkeep` function:

```solidity
function performUpkeep(bytes calldata /* performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    // require(upkeepNeeded, "Upkeep not needed");
    if (!upkeepNeeded) {
        revert Raffle__UpkeepNotNeeded(
            address(this).balance,
            s_players.length,
            uint256(s_raffleState)
        );
    }
    s_raffleState = RaffleState.CALCULATING;
    VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
        keyHash: i_keyHash,
        subId: i_subscriptionId,
        requestConfirmations: REQUEST_CONFIRMATIONS,
        callbackGasLimit: i_callbackGasLimit,
        numWords: NUM_WORDS,
        extraArgs: VRFV2PlusClient._argsToBytes(
            // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
        )
    });
    uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

    emit RequestedRaffleWinner(requestId);
}
```

At this point in the video, Patrick asks the audience if this event is redundant. This is an amazing question to ask yourself every time you do something in Solidity because as you know, everything costs gas. Another absolute truth about this environment is that no one wants to pay gas. So we, as developers, need to write efficient code.

To answer Patrick's question: Yes it's redundant, inside the `VRFCoordinatorV2Mock` you'll find that the `requestRandomWords` emits a giant event called `RandomWordsRequested` that contains the `requestId` we are also emitting in our new event. You'll see this a lot in smart contracts that involve transfers. But more on that in future sections.

We will keep the event for now for testing purposes.

It is important to test events! You might see them as a nice feature to examine what happened more easily using etherscan, but that's not all they are for. For example, the request for randomness is 100% reliant on events, because when `requestRandomWords` emits the `RandomWordsRequested` event, that gets picked up by the Chainlink nodes and the nodes use the information to provide the randomness service to you by calling back your `fulfillRandomWords`. **In the absence of the event, they wouldn't know where and what to send.**

Let's write a test that checks if `performUpkeep` updates the raffle state and emit the event we created:

Add `import {Vm} from "forge-std/Vm.sol";` inside the import sections of `RaffleTest.t.sol`.

We decided to include the `PLAYER` entering the raffle and setting `block.timestamp` into the future inside a modifier. That way we can easily use that everywhere, without typing the same 4 rows of code over and over again.

```solidity
modifier raffleEntredAndTimePassed() {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    _
}


function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntredAndTimePassed {
    // Act
    vm.recordLogs();
    raffle.performUpkeep(""); // emits requestId
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    // Assert
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    // requestId = raffle.getLastRequestId();
    assert(uint256(requestId) > 0);
    assert(uint(raffleState) == 1); // 0 = open, 1 = calculating
}
```

Let's analyze the test line by line. We start by calling `vm.recordLogs()`. You can read more about this one [here](https://book.getfoundry.sh/cheatcodes/record-logs). This cheatcode starts recording all emitted events inside an array. After that, we call `performUpkeep` which emits both the events we talked earlier about. We can access the array where all the emitted events were stored by using `vm.getRecordedLogs()`. It usually takes some trial and error, or `forge debug` to know where the event that interests us is stored. But we can cheat a little bit. We know that the big event from the vrfCoordinator is emitted first, so our event is second, i.e. entries\[1] (because the index starts from 0). Looking further in the examples provided [here](entries\[1]), we see that the first topic, stored at index 0, is the name and output of the event. Given that our event only emits one parameter, the `requestId`, then we are aiming for `entries[1].topics[1]`.

Moving on, we get the raffle state using the `getRaffleState` view function. We assert the `requestId` is higher than 0, meaning it exists, we also assert that `raffleState` is equal to 1, i.e. CALCULATING.

Run the test using `forge test --mt testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId`.

It passes, great job!

## Fuzz testing

Generally, fuzz testing, also known as fuzzing, is an automated software testing technique that involves injecting invalid, malformed, or unexpected inputs into a system to identify software defects and vulnerabilities. This method helps in revealing issues that may lead to crashes, security breaches, or performance problems. Fuzz testing operates by feeding a program with large volumes of random data (referred to as "fuzz") to observe how the system handles such inputs. If the system crashes or exhibits abnormal behavior, it indicates a potential vulnerability or defect that needs to be addressed.

How can we apply this in Foundry?

Let's find out by testing the fact that `fulfillRandomWords` can only be called after the upkeep is performed.

Open `RaffleTest.t.sol` and add the following:

`import {VRFCoordinatorV2_5Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";` in the import section.

```solidity
function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
    public
    raffleEntredAndTimePassed
{
    // Arrange
    // Act / Assert
    vm.expectRevert("nonexistent request");
    // vm.mockCall could be used here...
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        0,
        address(raffle)
    );

}
```

So we define the function and use the modifier we created in the previous lesson to make `PLAYER` enter the raffle and set `block.timestamp` into the future. We use the `expectRevert` because we expect the next call to revert with the `"nonexistent request"` message. How do we know that? Simple, inside the `VRFCoordinatorV2Mock` we can see the following code:

```solidity
function fulfillRandomWords(uint256 _requestId, address _consumer) external nonReentrant {
fulfillRandomWordsWithOverride(_requestId, _consumer, new uint256[](0));
}

/**
* @notice fulfillRandomWordsWithOverride allows the user to pass in their own random words.
*
* @param _requestId the request to fulfill
* @param _consumer the VRF randomness consumer to send the result to
* @param _words user-provided random words
*/
function fulfillRandomWordsWithOverride(uint256 _requestId, address _consumer, uint256[] memory _words) public {
uint256 startGas = gasleft();
if (s_requests[_requestId].subId == 0) {
    revert("nonexistent request");
}
```

If the `requestId` is not registered, then the `if (s_requests[_requestId].subId == 0)` check would revert using the desired message.

Moving on, we called `vm.expectRevert` then we called `fulfillRandomWords` with an invalid `requestId`, i.e. requestId = 0. But why only 0, what if it works with other numbers? How can we test the same thing with 1000 different inputs to make sure that this is more relevant?

Here comes Foundry fuzzing:

```solidity
function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
    public
    raffleEntredAndTimePassed
{
    // Arrange
    // Act / Assert
    vm.expectRevert("nonexistent request");
    // vm.mockCall could be used here...
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        randomRequestId,
        address(raffle)
    );
}
```

If we specify an input parameter in the test function declaration, Foundry will provide random values wherever we use that parameter inside our test function.

This was just a small taste. Foundry fuzzing has an enormous testing capability. We will discuss more about them in the next sections.

## One Big Test

### The biggest test you ever wrote

You are a true hero for reaching this lesson! Let's finalize the testing with a big function.

Up until now, we've tested parts of the contract with a focus on checks that should revert in certain conditions. We never fully tested the happy case. We will do that now.

Open your `RaffleTest.t.sol` and add the following function:

```solidity
function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnteredAndTimePassed {
    // Arrange

    uint256 additionalEntrants = 3;
    uint256 startingIndex = 1;

    for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
        address player = address(uint160(i));
        hoax(player, 1 ether);
        raffle.enterRaffle{value: entranceFee}();
    }
}
```

This is not the whole function but we break it to not overwhelm you.

1. We define the function, make it public and apply the `raffleEnteredAndTimePassed` modifier;
2. We define two new variables `additionalEntrants` and `startingIndex`;
3. We assign `1` to `startingIndex` because we don't want to start with `index 0`, you will see why in a moment;
4. We use a for loop that creates 5 addresses. If we started from `index 0` then the first created address would have been `address(0)`. `address(0)` has a special status in the Ethereum ecosystem, you shouldn't use it in tests because different systems check against sending to it or against configuring it. Your tests would fail and not necessarily because your smart contract is broken;
5. Inside the loop, we use `hoax` which acts as `deal + prank` to call `raffle.enterRaffle` using each of the newly created addresses. Read more about `hoax` [here](https://book.getfoundry.sh/reference/forge-std/hoax?highlight=hoax#hoax).

Ok, now we need to pretend to be Chainlink VRF and call `fulfillRandomWords`. We will need the `requestId` and the `consumer`. The consumer is simple, it's the address of the `Raffle` contract. How do we get the `requestId`? We did this in the previous lesson!

```solidity
function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnteredAndTimePassed {
    // Arrange

    uint256 additionalEntrants = 333;
    uint256 startingIndex = 1;

    for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
        address player = address(uint160(i));
        hoax(player, 1 ether);
        raffle.enterRaffle{value: entranceFee}();
    }

    vm.recordLogs();
    raffle.performUpkeep(""); // emits requestId
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    // Pretend to be Chainlink VRF
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        uint256(requestId),
        address(raffle)
    );
}
```

1. We copy what we did in the previous lesson to get the `requestId` emitted by the `performUpkeep`;
2. We then use the `VRFCoordinatorV2_5Mock` to call the `fulfillRandomWords` function. This is usually called by the Chainlink nodes but given that we are on our local Anvil chain we need to do that action.
3. `fulfillRandomWords` expects a uint256 `requestId`, so we use `uint256(requestId)` to cast it from `bytes32` to the expected type.

With this last call we've finished the `Arrange` stage of our test. Let's continue with the `Assert` stage.

Before that, we need a couple of view functions in `Raffle.sol`:

```solidity
function getRecentWinner() public view returns (address) {
    return s_recentWinner;
}

function getNumberOfPlayers() public view returns (uint256) {
    return s_players.length;
}

function getLastTimeStamp() public view returns (uint256) {
    return s_lastTimeStamp;
}
```

We'll use this one in testing the recent winner.

```solidity
function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnteredAndTimePassed {
    // Arrange

    uint256 additionalEntrants = 3;
    uint256 startingIndex = 1;

    for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
        address player = address(uint160(i));
        hoax(player, STARTING_USER_BALANCE);
        raffle.enterRaffle{value: entranceFee}();
    }

    uint256 prize = entranceFee * (additionalEntrants + 1);
    uint256 winnerStartingBalance = expectedWinner.balance;

    // Act
    vm.recordLogs();
    raffle.performUpkeep(""); // emits requestId
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    // Pretend to be Chainlink VRF
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
        uint256(requestId),
        address(raffle)
    );

    // Assert
    address recentWinner = raffle.getRecentWinner();
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    uint256 winnerBalance = recentWinner.balance;
    uint256 endingTimeStamp = raffle.getLastTimeStamp();
    uint256 prize = entranceFee * (additionalEntrants + 1);

    assert(expectedWinner == recentWinner);
    assert(uint256(raffleState) == 0);
    assert(winnerBalance == winnerStartingBalance + prize);
    assert(endingTimeStamp > startingTimeStamp);
}
```

1. We've made some changes. Whenever you test things make sure to be consistent and try to avoid using magic numbers. We hoaxed the newly created addresses with `1 ether` for no obvious reason. We should use the `STARTING_USER_BALANCE` for consistency.
2. We created a new variable `previousTimeStamp` to record the previous time stamp, the one before the actual winner picking happened.

Now we are ready to start our assertions.

1. We assert that the raffle state is `OPEN` because that's how our raffle should be after the winner is drawn and the prize is sent;
2. We assert that we have chosen a winner;
3. We assert that the `s_players` array has been properly reset, so players from the previous raffle don't get to participate in the next one without paying;
4. We assert that the `fullfillRandomWords` updates the `s_lastTimeStamp` variable;
5. We assert that the winner receives their ETH prize;

Amazing work, let's try it out with `forge test --mt testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney --vv`.

Aaaaand it failed:

```Solidity
Ran 1 test suite in 2.35s (11.16ms CPU time): 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/unit/RaffleTest.t.sol:RaffleTest
[FAIL. Reason: InvalidRequest()] testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() (gas: 362400)
```

Failing is part of this game, whatever you do, at some point you will fail. The trick is not staying in that situation, let's see why this failure happened and turn it into success.

Can you figure out what is wrong?
If we trace the `InvalidRequest()` error, we see that it is emitted from the
`_chargePayment` function in the `VRFCoordinatorV2_5Mock` contract. It looks
like we have not funded our subscription with enough LINK tokens. Let's fund it
with more by updating our `Interactions.s.sol` where for now, I'll times our
`FUND_AMOUNT` by 100.

```solidity
function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account) public {
    console.log("Funding subscription:\t", subscriptionId);
    console.log("Using vrfCoordinator:\t\t\t", vrfCoordinator);
    console.log("On chainId: ", block.chainid);

    if(block.chainid == ETH_ANVIL_CHAIN_ID) {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
        vm.stopBroadcast();
    } else {
        console.log(LinkToken(linkToken).balanceOf(msg.sender));
        console.log(msg.sender);
        console.log(LinkToken(linkToken).balanceOf(address(this)));
        console.log(address(this));
        vm.startBroadcast(account);
        LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
        vm.stopBroadcast();
    }
}
```

Let's run the test again using `forge test --mt testFulfillRandomWordsPicksAWinnerRestesAndSendsMoney -vvv`.

Run the test with `forge test --mt testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney`.

```Solidity
[⠢] Compiling...
No files changed, compilation skipped

Ran 1 test for test/unit/RaffleTest.t.sol:RaffleTest
[PASS] testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() (gas: 287531)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 2.93ms (250.30µs CPU time)
```

Amazing work! Let's try some forked tests in the next lesson.
