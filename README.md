# Foundry Smart Contract Lottery

In this lesson, we will cover **events**, **true random numbers**, **modules**, and **automation**. You can preview the final project by cloning the repository and checking the `makefile`, which lists all the specific versions of dependencies needed to compile our contract.

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

Let's dive in and start building this exciting project!

## Project setup

For the project, we'll be working with an advanced lottery or raffle smart contract. This won't just be an exercise in coding, but a chance to learn more about:

-   Events
-   On-chain randomness (done the proper way)
-   Chainlink automation
-   And many more!

Please follow Patrick's presentation on the project we are going to build. Marvel at how good the code looks, pay attention to code structure, Natspec comments and all the other cool features.

Hopefully, that sparked your interest. Now let's get cooking!

### Setup

We are going to start a new foundry project. You already know how to do that, it would be great if you could do this on your own and then come back and compare your work to what's presented below. With that out of the way, please call the following commands in your terminal:

```Solidity
mkdir foundry-smart-contract-lottery-f23
cd foundry-smart-contract-lottery-f23
code .
```

Inside the new VSCode instance, in the terminal, we are going to init our Foundry project:

```Solidity
forge init
```

Please delete all the `Counter` files that are populated by default when we initiate a new Foundry project.

A good practice at this stage in your project is to come up with a plan/blueprint. What do we want to do with this? What is the main functionality of the project? In the root folder create a file called `README.md` (if Foundry created one for you just delete its contents), you obviously know what this file must look like from the previous courses, but before we get there, let's just outline a simple plan.

Open the `README.md`:

```Solidity

# Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery.

## What we want it to do?

1. Users should be able to enter the raffle by paying for a ticket. The ticket fees are going to be the prize the winner receives.
2. The lottery should automatically and programmatically draw a winner after a certain period.
3. Chainlink VRF should generate a provably random number.
4. Chainlink Automation should trigger the lottery draw regularly.
```

We will introduce the Chainlink integrations in future lessons. For now, remember that we will use the Chainlink VRF service to obtain a random number, an operation that is harder than you think in the absence of a Chainlink VRF-like service. We are going to use Chainlink Automation to schedule and trigger the lottery draw programmatically.

**Let the development begin!**

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

Let's think about the structure of our project, what is the main functionality a raffle should have?

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

Did you spot that slick `/** Getter Function */`. To make our contracts extremely tidy and greatly improve readability we should use a Contract Layout. But more about this in the next lesson!

## Solidity style guide

In the previous section we talked a bit about Solidity's style guide, code layouts and naming conventions. However, it's intriguing to note that we didn't fully explore how to properly order our Solidity functions. Solidity docs provide an [Order of Layout](https://docs.soliditylang.org/en/latest/style-guide.html#order-of-layout):

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

Sometimes it's useful to paste this as a comment at the top of your contract to always remember it!

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

We will refactor `enterRaffle`, but before that let's define our custom error. Be mindful of the layout we talked about in the previous lesson

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

You will see that we named the custom error using the `Raffle__` prefix. This is a very good practice that will save you a ton of time when you need to debug a protocol with 20 smart contracts. You will run your tests and then ask yourself `Ok, it failed with this error ... but where does this come from?`. Because you thought ahead and used prefixes in naming your error you won't have that problem! Awesome!

**Note:**

**In Solidity, like in many other programming languages, you can write if statements in a single line for brevity, especially when they are simple and only execute a single statement. This is purely a stylistic choice and does not affect the functionality or performance of the code.**

There is no difference between this:

```solidity
if(msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
```

and this:

```solidity
if(msg.value < i_entranceFee) {
    revert Raffle__NotEnoughEthSent();
}
```

## Smart contracts events

Ok, our user paid the entrance fee, but how do we track his registration? We can't simply take the money and run! We need a storage structure that keeps track of all registered users from where to pick the winner.

Take a moment and decide what would be the best from the following:

1. Mapping
2. Array
3. A bunch of address variables and limit the number of participants

...

Congratulations if you chose the **Array** option! To be more specific, a dynamic array that grows in size with each new participant. Mappings can't be looped through, and a bunch of address variables is not feasible.

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

Great! I know there is a possibility you don't quite understand the importance/usage of this event, but don't worry, we'll get back to it in the testing section.

But before that, let's discuss randomness.

## Random numbers - Block Timestamp

Going back to lesson 1, we established that one of the Raffle contract goals is `...we should be able to automatically pick a winner out of the registered users.`

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

Don't worry! We will create a custom error for that in the next lesson. But before that let's talk randomness.

## Random numbers - Introduction to Chainlink VRF

Chainlink VRF (Verifiable Random Function) is a service provided by the Chainlink network that offers secure and verifiable randomness to smart contracts on blockchain platforms. This randomness is crucial for our Raffle and for any other applications that need a source of randomness.

How does Chainlink VRF work?

Chainlink VRF provides randomness in 3 steps:

1. Requesting Randomness: A smart contract makes a request for randomness by calling the `requestRandomness` function provided by the Chainlink VRF. This involves sending a request to the Chainlink oracle along with the necessary fees.

2. Generating Randomness: The Chainlink oracle node generates a random number off-chain using a secure cryptographic method. The oracle also generates a proof that this number was generated in a verifiable manner.

3. Returning the Result: The oracle returns the random number along with the cryptographic proof to the smart contract. The smart contract can then use the random number, and any external observer can verify the proof to confirm the authenticity and integrity of the randomness.

Let's dive deeper. We will follow the Chainlink tutorial available [here](https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number).

Go to the [Chainlink Faucet](https://faucets.chain.link/sepolia) and grab yourself some test LINK and/or ETH. Make sure you connect your test account using the appropriate Sepolia Chain.

Go [here](https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number) and scroll down and press on the blue button that says `Open the Subscription Manager`.

Press on the blue button that says `Create Subscription`. You don't need to provide a project name or an email address, but you can if you want to.

When you press `Create subscription` you will need to approve the subscription creation. Sign it using your MetaMask and wait until you receive the confirmation. You will be asked to sign the message again. If you are not taken to the `Add Funds` page, go to `My Subscriptions` section and click on the id of the subscription you just created, then click on `Actions` and `Fund subscription`. Proceed in funding your subscription.

The next step is adding consumers. On the same page, we clicked on the `Actions` button you can find a button called `Add consumer`. You will be prompted with an `Important` message that communicates your `Subscription ID`. That is a very important thing that we'll use in our smart contract.

Keep in mind that our smart contract and Chainlink VRF need to be aware of each other, which means that Chainlink needs to know the address that will consume the LINK we provided in our subscription and the smart contract needs to know the Subscription ID.

Go back to the [tutorial page](https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number#create-and-deploy-a-vrf-v2-compatible-contract). Scroll down to the `Create and deploy a VRF v2 compatible contract` section. Read the short description about dependencies and pre-configured values and open the contract in Remix by pressing on `Open in Remix`.

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
