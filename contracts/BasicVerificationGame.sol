pragma solidity ^0.4.18;

import './IComputationLayer.sol';

contract BasicVerificationGame {

  event NewGame(bytes32 gameId, address solver, address verifier);
  event NewQuery(bytes32 gameId, uint stepNumber);
  event NewResponse(bytes32 gameId, bytes32 hash);

  struct VerificationGame {
    address solver;
    address verifier;
    uint numSteps;
    bytes input;
    bytes32 outputHash;
    uint currentTime;
    uint lastStep;
    uint currentStep;
    bytes32 lastHash;
    bool solverConvicted;
    bool verifierConvicted;
    IComputationLayer vm;
  }

  mapping(bytes32 => VerificationGame) private games;

  //TODO: should restrict who can create newGame
  function newGame(address solver, address verifier, bytes input, bytes32 outputHash, uint numSteps, IComputationLayer vm) public returns(bytes32 gameId) {
    gameId = keccak256(solver, verifier, outputHash);
    VerificationGame storage game = games[gameId];
    game.solver = solver;
    game.verifier = verifier;
    game.input = input;
    game.outputHash = outputHash;
    game.numSteps = numSteps;
    game.vm = vm;
    NewGame(gameId, solver, verifier);
  }

  function query(bytes32 gameId, uint stepNumber) public {
    VerificationGame storage game = games[gameId];
    require(msg.sender == game.verifier);
    game.currentStep = stepNumber;
    NewQuery(gameId, stepNumber);
  }

  function respond(bytes32 gameId, bytes32 hash) public {
    VerificationGame storage game = games[gameId];
    game.lastHash = hash;
    NewResponse(gameId, hash);
  }
 
  function timeout(bytes32 gameId) public view returns (bool) {
    VerificationGame storage game = games[gameId];
    return (block.number > game.currentTime);
  }

  //TODO: Fix function modifiers
  function performStepVerification(bytes32 gameId, bytes preState, bytes nextInstruction, bytes proof) public returns (bool) {
    VerificationGame storage game = games[gameId];
    bytes32 stepOutput = game.vm.runStep(preState, nextInstruction);
    return (keccak256(stepOutput) == game.outputHash);
  }
}