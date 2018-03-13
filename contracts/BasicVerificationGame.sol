pragma solidity ^0.4.18;

import './IComputationLayer.sol';
import './IDisputeResolutionLayer.sol';

contract BasicVerificationGame {

  event NewGame(bytes32 gameId, address solver, address verifier);
  event NewQuery(bytes32 gameId, uint stepNumber);
  event NewResponse(bytes32 gameId, bytes32 hash);

  enum State { Unresolved, SolverWon, ChallengerWon }

  struct VerificationGame {
    address solver;
    address verifier;
    uint numSteps;
    bytes input;
    bytes32 outputHash;
    uint currentTime;
    uint currentStep;
    uint lastStep;
    bytes32 lastHash;
    address lastParticipant;
    IComputationLayer vm;
    State state;
    uint responseTime;
  }

  mapping(bytes32 => VerificationGame) private games;

  //TODO: should restrict who can create newGame
  function newGame(address solver, address verifier, bytes input, bytes32 outputHash, uint numSteps, uint responseTime, IComputationLayer vm) public returns(bytes32 gameId) {
    gameId = keccak256(solver, verifier, outputHash);
    VerificationGame storage game = games[gameId];
    game.solver = solver;
    game.verifier = verifier;
    game.input = input;
    game.outputHash = outputHash;
    game.numSteps = numSteps;
    game.vm = vm;
    game.state = State.Unresolved;
    game.responseTime = responseTime;
    NewGame(gameId, solver, verifier);
  }

  function query(bytes32 gameId, uint stepNumber) public {
    VerificationGame storage game = games[gameId];

    require(msg.sender == game.verifier);
    require(game.state == State.Unresolved);

    game.currentStep = stepNumber;
    game.currentTime = block.number;
    game.lastParticipant = game.verifier;
    NewQuery(gameId, stepNumber);
  }

  function respond(bytes32 gameId, bytes32 hash) public {
    VerificationGame storage game = games[gameId];

    require(msg.sender == game.solver);
    require(game.state == State.Unresolved);

    game.lastHash = hash;
    game.lastStep = game.currentStep;
    game.currentTime = block.number;
    game.lastParticipant = game.solver;
    NewResponse(gameId, hash);
  }
 
  function timeout(bytes32 gameId) public {
    VerificationGame storage game = games[gameId];

    require(block.number > game.currentTime + game.responseTime);
    require(game.state == State.Unresolved);

    if (game.lastParticipant == game.solver) {
      game.state = State.SolverWon;
    } else {
      game.state = State.ChallengerWon;
    }
  }

  function performStepVerification(bytes32 gameId, bytes preState, bytes nextInstruction, bytes proof) public returns (bool) {
    VerificationGame storage game = games[gameId];

    require(game.state == State.Unresolved);
    require(msg.sender == game.solver);
    require(game.currentStep + 1 == game.lastStep);

    bytes32 stepOutput = game.vm.runStep(preState, nextInstruction);
    if (keccak256(stepOutput) == game.outputHash) {
      game.state = State.SolverWon;
    } else {
      game.state = State.ChallengerWon;
    }
  }

  function status(bytes32 gameId) public view returns (uint8) {
    return uint8(games[gameId].state);
  }
}