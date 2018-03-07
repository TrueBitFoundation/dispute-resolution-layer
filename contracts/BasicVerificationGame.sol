pragma solidity ^0.4.18;

import './IComputationLayer.sol';

//TODO: implement interface???. currently gas issue when deploying
contract SimpleAdderGame {

  uint numGames = 0;

  event NewGame(uint gameId, address solver, address verifier);
  event NewQuery(uint gameId, uint stepNumber);
  event NewResponse(uint gameId, bytes32 hash);

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

  mapping(uint => VerificationGame) private games;

  //TODO: should restrict who can create newGame
  function newGame(address solver, address verifier, bytes input, bytes32 outputHash, uint numSteps, IComputationLayer vm) public returns(uint gameId) {
    VerificationGame storage game = games[numGames];
    game.solver = solver;
    game.verifier = verifier;
    game.input = input;
    game.outputHash = outputHash;
    game.numSteps = numSteps;
    game.vm = vm;
    gameId = numGames;
    numGames = numGames + 1;
    NewGame(gameId, solver, verifier);
  }

  function query(uint gameId, uint stepNumber) public {
    VerificationGame storage game = games[gameId];
    require(msg.sender == game.verifier);
    game.currentStep = stepNumber;
    NewQuery(gameId, stepNumber);
  }

  function respond(uint gameId, bytes32 hash) public {
    VerificationGame storage game = games[gameId];
    game.lastHash = hash;
    NewResponse(gameId, hash);
  }
 
  function timeout(uint gameId) public returns (bool) {
    VerificationGame storage game = games[gameId];
    return (block.number > game.currentTime);
  }

  //TODO: Fix function modifiers
  function performStepVerification(uint gameId, bytes preState, bytes nextInstruction, bytes proof) public returns (bool) {
    VerificationGame storage game = games[gameId];
    bytes32 stepOutput = game.vm.runStep(preState, nextInstruction);
    uint output = uint(stepOutput[0]);
    return (keccak256(output) == game.outputHash);
  }
}