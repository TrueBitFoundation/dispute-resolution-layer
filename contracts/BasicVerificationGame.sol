pragma solidity ^0.4.18;

import './IComputationLayer.sol';
import './IDisputeResolutionLayer.sol';

contract BasicVerificationGame {

  event NewGame(bytes32 gameId, address solver, address verifier);
  event NewQuery(bytes32 gameId, uint stepNumber);
  event NewResponse(bytes32 gameId, bytes32 hash);
  event FinalData(bytes32 output, bytes32 outputHash);

  enum State { Unresolved, SolverWon, ChallengerWon }

  struct VerificationGame {
    address solver;
    address verifier;
    address lastParticipant;
    uint lastParticipantTime;
    IComputationLayer vm;
    State state;
    uint responseTime;
    uint lowStep;
    bytes32 lowHash;
    uint medStep;
    bytes32 medHash;
    uint highStep;
    bytes32 highHash;
    bytes32 programMerkleRoot;
    bytes32 lastInstructionHash;
  }

  mapping(bytes32 => VerificationGame) private games;

  uint uniq;

  //TODO: should restrict who can create newGame
  function newGame(address solver, address verifier, bytes32 programMerkleRoot, bytes32 finalStateHash, uint numSteps, uint responseTime, IComputationLayer vm) public {
    bytes32 gameId = keccak256(solver, verifier, finalStateHash, uniq);

    VerificationGame storage game = games[gameId];
    game.solver = solver;
    game.verifier = verifier;
    game.vm = vm;
    game.state = State.Unresolved;
    game.responseTime = responseTime;
    game.lastParticipant = solver;//if verifier never queries, solver should be able to trigger timeout
    game.lastParticipantTime = block.number;

    game.lowStep = 0;
    game.lowHash = keccak256(0);//initial state hash
    game.medStep = 0;
    game.medHash = bytes32(0);
    game.highStep = numSteps;
    game.highHash = finalStateHash;
    game.programMerkleRoot = programMerkleRoot;

    uniq++;
    NewGame(gameId, solver, verifier);
  }

  function query(bytes32 gameId, uint stepNumber) public {
    VerificationGame storage game = games[gameId];

    require(msg.sender == game.verifier);
    require(game.state == State.Unresolved);

    bool isFirstStep = game.medStep == 0;
    bool haveMedHash = game.medHash != bytes32(0);
    require(isFirstStep || haveMedHash);
    // ^ invariant if the step has been set but we don't have a hash for it

    if (stepNumber == game.lowStep && stepNumber + 1 == game.medStep) {
      // final step of the binary search (lower end)
      game.highHash = game.medHash;
      game.highStep = stepNumber + 1;
    } else if (stepNumber == game.medStep && stepNumber + 1 == game.highStep) {
      // final step of the binary search (upper end)
      game.lowHash = game.medHash;
      game.lowStep = stepNumber;
    } else {
      // this next step must be in the correct range
      //can only query between 0...2049
      require(stepNumber > game.lowStep && stepNumber < game.highStep);

      // if this is NOT the first query, update the steps and assign the correct hash
      // (if this IS the first query, we just want to initialize medStep and medHash)
      if (!isFirstStep) {
        if (stepNumber < game.medStep) {
          // if we're iterating lower,
          //   the new highest is the current middle
          game.highStep = game.medStep;
          game.highHash = game.medHash;
        } else if (stepNumber > game.medStep) {
          // if we're iterating upwards,
          //   the new lowest is the current middle
          game.lowStep = game.medStep;
          game.lowHash = game.medHash;
        } else {
          // and if we're requesting the midStep that we've already requested,
          // revert to prevent replay.
          revert();
        }
      }

      game.medStep = stepNumber;
      game.medHash = bytes32(0);
    }

    game.lastParticipantTime = block.number;
    game.lastParticipant = game.verifier;

    NewQuery(gameId, stepNumber);
  }

  function respond(bytes32 gameId, uint stepNumber, bytes32 hash) public {
    VerificationGame storage game = games[gameId];

    require(msg.sender == game.solver);
    require(game.state == State.Unresolved);

    // Require step to avoid replay problems
    require(stepNumber == game.medStep);

    // provided hash cannot be zero; as that is a special flag.
    require(hash != 0);

    // record the claimed hash
    require(game.medHash == bytes32(0));
    game.medHash = hash;

    game.lastParticipantTime = block.number;
    game.lastParticipant = game.solver;

    NewResponse(gameId, hash);
  }
 
  function timeout(bytes32 gameId) public {
    VerificationGame storage game = games[gameId];

    require(block.number > game.lastParticipantTime + game.responseTime);
    require(game.state == State.Unresolved);

    if (game.lastParticipant == game.solver) {
      game.state = State.SolverWon;
    } else {
      game.state = State.ChallengerWon;
    }
  }

  function merklizeProof(bytes32[] proof) public returns (bytes32 merkleRoot) {
    for (uint i = 0; i < proof.length; i++) {
      if (i == 0) 
        merkleRoot = proof[0];
      else
        merkleRoot = keccak256(merkleRoot, proof[i]);

    }
  }

  //Should probably replace preValue and postValue with preInstruction and postInstruction
  function performStepVerification(bytes32 gameId, bytes32[4] preStepState, bytes32[4] postStepState, bytes32[] proof) public {
    VerificationGame storage game = games[gameId];

    require(game.state == State.Unresolved);
    require(msg.sender == game.solver);

    require(game.lowStep + 1 == game.highStep);
    // ^ must be at the end of the binary search according to the smart contract

    require(game.vm.merklizeState(preStepState) == game.lowHash);
    require(game.vm.merklizeState(postStepState) == game.highHash);

    //require that the next instruction be included in the program merkle root
    require(game.programMerkleRoot == merklizeProof(proof));

    uint currentStep = uint(preStepState[3]);

    bytes32[4] memory newState;
    if (currentStep % 2 == 0) {
      newState = game.vm.runStep(preStepState, proof[0]);//pass in next instruction
    } else {
      newState = game.vm.runStep(preStepState, proof[1]);
    }

    if (game.vm.merklizeState(newState) == game.highHash) {
      game.state = State.SolverWon;
    } else {
      game.state = State.ChallengerWon;
    }
    //FinalData(stepOutput, keccak256(stepOutput));
  }

  function status(bytes32 gameId) public view returns (uint8) {
    return uint8(games[gameId].state);
  }

  function gameData(bytes32 gameId) public view returns (bytes32 lowHash, bytes32 medHash, bytes32 highHash) {
    VerificationGame storage game = games[gameId];
    lowHash = game.lowHash;
    medHash = game.medHash;
    highHash = game.highHash;
  }
}