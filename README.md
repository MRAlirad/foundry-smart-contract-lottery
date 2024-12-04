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
