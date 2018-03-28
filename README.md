# Dispute Resolution Layer

<p align="center">
  <img src="./Dispute Resolution Layer.jpg"/>
</p>

Codebase to provide ways for different incentive layers and computation layers to interface with a general purpose verification game.

Go [here](https://github.com/TrueBitFoundation/Developer-Resources/blob/master/docs/DisputeResolutionLayer.md) for the Dispute Resolution Layer Overview.

## Installation

Ensure you have truffle and an Ethereum test net like ganache installed
```
npm install -g truffle ganache-cli
```

Then install the package's dependencies
```
npm install
```

## Testing

After following the above installation instructions you can start up the dev blockchain in a separate tab:
```
ganache-cli
```

Then run the tests:

```
truffle test
```