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

Let's focus on points 1 and 2. In the previous lesson, we learned that we need to request a `randomWord` and Chainlink needs to callback one of our functions to answer the request. Let's copy the `requestId` line from the [Chainlink VRF docs](https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number#analyzing-the-contract) example inside our `pickWinner` function and start fixing the missing dependencies.

```solidity
function pickWinner() external {
    // check to see if enough time has passed
    if (block.timestamp - s_lastTimeStamp < i_interval) revert();

    uint256 requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
    );
}
```

You know the `keyHash`, `subId`, `requestConfirmations`, `callbackGasLimit` and `numWords` from our previous lesson.

Ok, starting from the beginning what do we need?

1. We need to establish the fact that our `Raffle` contract is a consumer of Chainlink VRF;
2. We need to take care of the VRF Coordinator, define it as an immutable variable and give it a value in the constructor;

Let's add the following imports:

```solidity
import {VRFCoordinatorV2Interface} from "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
```

Let's make our contract inherit the `VRFConsumerBaseV2`:

```solidity
contract Raffle is VRFConsumerBaseV2
```

Add a new immutable variable:

```solidity
// Chainlink VRF related variables
address immutable i_vrfCoordinator;
```

I've divided the `Raffle` variables from the `Chainlink VRF` variables to keep the contract tidy.

Adjust the constructor to accommodate all the new variables and imports:

```solidity
constructor(uint256 entranceFee, uint256 interval, addsress vrfCoordinator) {
    i_entranceFee = entranceFee;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;

    i_vrfCoordinator = vrfCoordinator;
}
```

For our imports to work we need to install the Chainlink library, and run the following command in your terminal:

```bash
forge install smartcontractkit/chainlink@42c74fcd30969bca26a9aadc07463d1c2f473b8c --no-commit
```

_P.S. I know it doesn't look amazing, bear with me._

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

If you got the error above, then `forge` was not able to find out the contracts we imported. Run the following command in your terminal:

```Solidity
forge remappings>remappings.txt
```

This will create a new file that contains your project remappings:

```toml
chainlink/=lib/chainlink/contracts/
forge-std/=lib/forge-std/src/
```

This is to be read as follows: `chainlink/` in your imports becomes `lib/chainlink/contracts/` behind the stage. We need to make sure that if we apply that change to our import the resulting **PATH is correct**.

`chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol` becomes `lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol`, which is correct. Sometimes some elements of the PATH are either missing or doubled, as follows:

`lib/chainlink/contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol`

or

`lib/chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol`

Both these variants are **incorrect**. You need to always be able to access the PATH in your explorer window on the left, if you can't then you need to adjust the remappings to match the lib folder structure.

Great, now that we were successfully able to run the imports let's continue fixing the missing variables.

Don't ever be afraid of calling `forge build` even if you know your project won't compile. Our contract lacks some variables that are required inside the `pickWinner` function. Call `forge build`.

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

At least now we know what's left \:smile:

Let's add the above-mentioned variables inside the VRF state variables block:

```solidity
// Chainlink VRF related variables
VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
bytes32 private immutable i_gasLane;
uint64 private immutable i_subscriptionId;
uint16 private constant REQUEST_CONFIRMATIONS = 3;
uint32 private immutable i_callbackGasLimit;
uint32 private constant NUM_WORDS = 1;
```

We have changed the `keyHash` name to `i_gasLane` which is more descriptive for its purpose. Also, we've changed the type of `i_vrfCoordinator`. For our `pickWinner` function to properly call `uint256 requestId = i_vrfCoordinator.requestRandomWords(` we need that `i_vrfCoordinator` to be a contract, specifically the `VRFCoordinatorV2Interface` contract that we've imported.

For simplicity we request only 1 word, thus we make that variable constant. The same goes for request confirmations, this number can vary depending on the blockchain we chose to deploy to but for mainnet 3 is perfect. Cool!

The next step is to attribute values inside the constructor:

```solidity
constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
    i_entranceFee = entranceFee;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;

    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
}
```

Ok, breathe, it's a lot but it's not complicated, let's go through it together:

-   First, we need to initiate the VRFConsumerBaseV2 using our constructor `VRFConsumerBaseV2(vrfCoordinator)`;
-   We are providing the `gasLane`, `subscriptionId` and `callbackGasLimit` in our input section of the constructor;
-   We are assigning the inputted values to the state variables we defined at an earlier point;
-   We are casting the `vrfCoordinator` address as `VRFCoordinatorV2Interface` to be able to call it inside the `pickWinner` function.

The last step is to create a new function:

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {}
```

This will be called by the `vrfCoordinator` when it sends back the requested `randomWords`. This is also where we'll select our winner!

Call the `forge build` again.

```Solidity
[⠒] Compiling...
[⠔] Compiling 9 files with Solc 0.8.25
[⠒] Solc 0.8.25 finished in 209.77ms
Compiler run successful with warnings:
Warning (2072): Unused local variable.
  --> src/Raffle.sol:61:9:
   |
61 |         uint256 requestId = i_vrfCoordinator.requestRandomWords(
   |         ^^^^^^^^^^^^^^^^^

```

Perfect! Don't worry. We will use that `requestId` in a future lesson.

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

Enough theory, let's implement it in code!

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
    if (!success) {
        revert Raffle__TransferFailed();
    }
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

**How can we use enums in our Project?**

Let's think about all the possible states of our Raffle. We deploy the contract and the raffle is started, the participants buy a ticket to register. Let's call this state `OPEN`. After this, we have a period when we need to wait at least 3 blocks for Chainlink VRF to send us the random number this means that we have at least 36 seconds (12 seconds/block) of time when our Raffle is processing the winner. Let's call this state `CALCULATING`.

Let's code all these!

Paste the following code between the errors definition section and the state variables section:

```solidity
// Type declarations
enum RaffleState {
    OPEN,           // 0
    CALCULATING     // 1
}

// Put this one in `Raffle related variables`
RaffleState private s_raffleState;
```

Amazing, let's default our raffle state to open inside the constructor.

Add the following inside your constructor:

```solidity
s_raffleState = RaffleState.OPEN;
```

Amazing! But what's the reason we did all this? Security! The thing we love the most!

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

I know you thought about it: `But why are we opening the Raffle again? We've selected a winner but the s_players array is still full!` And you are right!

We will take care of this in the next lesson!

## Lottery restart - Resetting an Array

Continuing from where we left in the last lesson. We've picked the winner, we've opened the lottery and ... what do we do with the players already in the array? They've had their chance to win and they didn't.

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

## Tutorials vs Real-World Smart-Contract Building

When it comes to building solidity projects, things may seem a bit too linear or straightforward when you watch a demo or read a tutorial. Looking at a video where Patrick streamlines a project from start to finish and his code compiling from the first try 99.9% of the time might give you the wrong idea of how this process normally goes.

Keep in mind that Patrick built this project or a close version of it using Solidity + Brownie, Solidity + Hardhat and now Solidity + Foundry and probably updated them multiple times to adjust for different changes in Solidity versions, VRF versions and so on. When building something completely new, Patrick, like any other smart contract developer, doesn't do it seamlessly or in one go.

Normally, when you start building a new project, you will write 1-2 functions and then try to compile it ... and BAM, it doesn't compile, you go and fix that and then you write a couple of tests to ensure the functionality you intend is there ... and some of these tests fail. Why do they fail? You go back to the code, make some changes, compile it again, test it again and hopefully everything passes. Amazing, you just wrote your first 1-2 functions, your project will most likely need 10 more. This might look cumbersome, but it's the best way to develop a smart contract, far better than trying to punch in 10 functions and then trying to find out where's the bug that prevents the contract from compiling. The reason why Patrick is not testing every single thing on every single step is, as you've guessed, the fact that the contract will be refactored over and over again, and testing a function that will be heavily modified two lessons from now is not that efficient.

**_You won't develop smart contracts without setbacks. And that is ok!_**

**_Setbacks are not indicators of failure, they are signs of growth and learning._**

## The Checks-Effects-Interactions (CEI) Pattern

A very important thing to note. When developing this contract Patrick is using a style called Checks-Effects-Interactions or CEI.

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

Amazing work! Our project starts looking good!

Looking through it we can see that there's an obvious problem. For the winner to be picked we need someone to call `pickWinner`. Manually calling this day after day is not optimal, and we, as engineers, need to come up with a better solution! Let's discuss Chainlink Automation!

**Chainlink Automation** is a decentralized service designed to automate key functions and DevOps tasks within smart contracts in a highly reliable, trust-minimized, and cost-efficient manner. It allows smart contracts to automatically execute transactions based on predefined conditions or schedules.

This lesson will be centered on creating a time-based automation using Chainlink's UI. The relevant section in the documentation starts [here](https://docs.chain.link/chainlink-automation/guides/compatible-contracts) and [here](https://docs.chain.link/chainlink-automation/guides/job-scheduler).

In this video, Richard provides a walkthrough on Chainlink’s Keepers, starting with how to connect a wallet from the Chainlink Keepers UI, registering a new upkeep, and implementing time-based trigger mechanisms.

Let's open the contract available [here](https://docs.chain.link/chainlink-automation/guides/compatible-contracts#example-automation-compatible-contract-using-custom-logic-trigger) in Remix by pressing the `Open in Remix` button.

Following Richard's tutorial let's delete the `is AutomationCompatibleInterface` inheritance, both the `interval` and `lastTimeStamp` variables, adjust the constructor and delete both available functions. Create a new function called `count` which increments the `counter` state variable. It should look like this:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


contract Counter {

    uint256 public counter;

    constructor() {
        counter = 0;
    }

    function count() external {
        counter = counter + 1;
    }

}
```

Wow! This is all we need!

Let's deploy this contract on Sepolia. If you are brave enough follow Richard and deploy it to Fuji Avalanche.

Amazing! Check if the counter is 0 by clicking on it! Also check if the `count` function works by clicking it, signing the transaction and then clicking `counter` again.

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

I've configured mine to work every two minutes: `*/2 * * * *`.

After you provide the Cron expression press `Next`.

Now we got to the `Upkeep details` section. Give it a name. The `Admin Address` should be defaulted to the address you used to deploy the contract. You should have some test LINK there. If you don't have any pick some up from [here](https://faucets.chain.link/sepolia). You have the option of specifying a `Gas limit`. Specify a `Starting balance`, I've used 10 LINK. You don't need to provide a project name or email address.

Click on `Register Upkeep` and sign the transactions that pop up.

I had to sign 3 transactions, after that let's click on `View Upkeep`.

In the `History` section, you can see the exact date and tx hash of the automated call. Make sure you fund the upkeep to always be above the `Minimum Balance`. You can fund your upkeep using the blue `Actions` button. Use the same button to edit your upkeep, change the frequency, or the gas limit, pause the upkeep or cancel it.

From time to time go back to Remix and check the `counter` value. You'll see it incremented with a number corresponding to the number of calls visible in the `History` we talked about earlier.

Ok, this was fun, let's pause/cancel the upkeep to save some of that sweet testnet LINK.

## Implementing Chainlink Automation

Remember how Richard deleted the `performUpkeep` and `checkUpkeep` in the previous videos ... we gonna need those if we want to use the Chainlink Automation without interacting with Chainlink's front-end. We are engineers, we do not use front-ends!

For this to work we need to refactor the `pickWinner` function. That functionality needs to be part of the `performUpkeep` if we want the Chainlink node to call it for us. But before that, let's create the `checkUpkeep` function:

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
    bool isOpen = RaffleState.OPEN == s_raffleState;
    bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
    bool hasPlayers = s_players.length > 0;
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
    return (upkeepNeeded, "0x0");
}
```

Again, a lot of things up there, but fear not, we are going to explain everything.

Going back to the [Chainlink Automation tutorial](https://docs.chain.link/chainlink-automation/guides/compatible-contracts) we see that `checkUpkeep` can use onchain data and a specified `checkData` parameter to perform complex calculations offchain and then send the result to `performUpkeep` as `performData`. But in our case, we don't need that `checkData` parameter. If a function expects an input, but we are not going to use it we can comment it out like this: `/* checkData */`. Ok, moving on, we'll make `checkUpkeep` public view and we match the expected returns of `(bool upkeepNeeded, bytes memory /* performData */)` commenting out that `performData` because we aren't going to use it.

You are amazing! Keep going!

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

Amazing!

Chainlink nodes will call this `checkUpkeep` function. If the return `upkeepNeeded` is true, then they will call `performUpkeep` ... which in our case is the `pickWinner` function. Let's refactor it a little bit:

```solidity
// 1. Get a random number
// 2. Use the random number to pick a player
// 3. Automatically called
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
    uint256 requestId = i_vrfCoordinator.requestRandomWords(
        i_gasLane,
        i_subscriptionId,
        REQUEST_CONFIRMATIONS,
        i_callbackGasLimit,
        NUM_WORDS
    );
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
if (!upkeepNeeded) {
    revert Raffle__UpkeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_raffleState)
    );
}
```

Let's define it at the top of the contract, next to the other errors:

```solidity
error Raffle__UpkeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 raffleState
);
```

This is the first time when we provided some parameters to the error. Think about them as extra info you get when you receive the error.

**Note: you can do both** **`uint256 raffleState`** **or** **`RaffleState raffleState`** **because these are directly convertible.**

We leave the rest of the function intact.

Another thing that we should do is to import the `AutomationCompatibleInterface`:

```solidity
import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
```

and let's make our contract inherit it:

```solidity
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
```

Now let's call a `forge build` to see if everything is ok.

## Custom Error with parameters

Using a basic `revert()` statement may not provide evidence on why a transaction failed. A better approach is to define custom errors by combining the **contract name** with a **description**, such as `Raffle__UpkeepNotNeeded()`. Additionally, including **parameters** can offer more detailed information about the cause of the transaction failure.

```Solidity
Raffle__UpkeepNotNeeded(address balance, uint256 length, uint256 raffleState);
```

## Quick recap

Congratulations, we wrote a bunch of great code!

What did we do?

* We implemented Chainlink VRF to get a random number
* We defined a couple of variables that we need both for Raffle operation and for Chainlink VRF interaction
* We have a not-so-small constructor
* We created a method for the willing participants to enter the Raffle
* Then made the necessary integrations with Chainlink Automation to automatically draw a winner when the time is right.
* When the time is right and after the Chainlink nodes perform the call then Chainlink VRF will provide the requested randomness inside `fulfillRandomWords`
* The randomness is used to find out who won, the prize is sent, raffle is reset.

And that's all! Take a break, take a walk and come back for more fun activities. Next, we'll have deploying, testing and many refactorings!

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

* We made `RaffleTest` contract inherit `Test` to enable the testing functionality;
* We've defined a `raffle` and `helperConfig` variables to store the contracts;
* Next, we defined the variables required for the deployment;
* Then, we created a new user called `PLAYER` and defined how many tokens they should receive;
* Inside the `setUp` function, we deploy the `DeployRaffle` contract then we use it to deploy the `Raffle` and `HelperConfig` contracts;
* We `deal` the `PLAYER` the defined `STARTING_USER_BALANCE`;
* We call `helperConfig.activeNetworkConfig` to get the Raffle configuration parameters.

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

Ok, so our Raffle starts in an OPEN state. Exactly like we coded it!

Great job! We started testing, let's see what we can do next!

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

If that is false we need to deploy a mock vrfCoordinatorV2\_5 and pass its address inside a `NetworkConfig` that will be used on Anvil.

Please use your Explorer on the left side to access the following path:

`foundry-smart-contract-lottery-cu/lib/chainlink/contracts/src/v0.8/vrf/`

Inside you'll find multiple folders, one of which is called `mocks`. Inside that folder, you can find the `VRFCoordinatorV2_5Mock` mock contract created by Chainlink.

Add the following line in the imports section of `HelperConfig.s.sol`:

```solidity
import {VRFCoordinatorV2_5Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
```

Amazing! Now let's keep on working on the `getOrCreateAnvilEthConfig` function. We need to deploy the `vrfCoordinatorV2Mock`, but if we open it we'll see that its constructor requires some parameters:

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

Amazing! Now that we have everything we need, let's perform the return, similar to what we did in `getSepoliaEthConfig`.

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

Great! Now this is fixed let's continue testing and deploying our Raffle contract.

## Test and deploy the lottery smart contract pt.2

Great! We've written some amazing code, but you know our job here is not done! We need to test it. Let's be smart about testing, what do we need to be able to properly test the contract and what kind of tests shall we do?

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
        uint64 subscriptionId;
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
