# Dispute Resolution Layer

<p align="center">
  <img src="./Dispute Resolution Layer.jpg"/>
</p>

## Intent

The goal of this repository is to create a discussion around defining a dispute resolution layer protocol that is general enough to work with Truebit General (WASM) and Truebit Lite (scrypt-interactive) mechanisms. Other possibilities may be different types of verification games (Proof of Steak).

The idea is that different types of incentive layers can plug in as well as different computation layers. Benefits  of this approach are upgradeability and flexibility. In case there are bugs in the incentive layer or dispute resolution layer we could swap them out. The other benefit is flexibility to allow other projects to build with the Truebit system.

The initial idea for this is that there currently exist two different implemented dispute resolution layers.

Scrypt-Interactive (Doge-Eth Bridge):
https://github.com/TrueBitFoundation/scrypt-interactive/blob/master/contracts/Verifier.sol

webasm-solidity (General Truebit):
https://github.com/TrueBitFoundation/webasm-solidity/blob/master/contracts/interactive2.sol

## Installation

```
npm install -g truffle ganache-cli
```

## Test

After following the above installation instructions you can start up the dev blockchain in a separate tab:
```
ganache-cli
```

Then run the tests:

```
truffle test
```