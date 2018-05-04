pragma solidity ^0.4.18;

import "./IComputationLayer.sol";
import "./IDisputeResolutionLayer.sol";

contract BasicVerificationGame is IDisputeResolutionLayer {

    event ChallengeCommitted(address solver, address verifier, bytes32 gameId);
    event NewGame(bytes32 gameId, address solver, address verifier);
    event NewQuery(bytes32 gameId, uint stepNumber);
    event NewResponse(bytes32 gameId, bytes32 hash);

    enum State { Uninitialized, Challenged, Unresolved, SolverWon, ChallengerWon }

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
        bytes32 spec;
    }

    mapping(bytes32 => VerificationGame) private games;

    uint uniq;

    //This commits a verifier to a challenge, if they dont send a query before the response time they are eligible to be penalized.
    function commitChallenge(address solver, address verifier, bytes32 spec) external returns (bytes32 gameId) {
        gameId = keccak256(solver, verifier, spec, uniq);

        VerificationGame storage game = games[gameId];
        game.solver = solver;
        game.verifier = verifier;
        game.state = State.Challenged;
        game.spec = spec;

        uniq++;
        emit ChallengeCommitted(solver, verifier, gameId);
    }

    // This is Dispute Resolution Layer specific
    function initGame(
        bytes32 gameId, 
        bytes32 programMerkleRoot, 
        bytes32 finalStateHash, 
        uint numSteps, 
        uint responseTime, 
        IComputationLayer vm
    ) public {
        VerificationGame storage game = games[gameId];

        require(game.state == State.Challenged);

        game.state = State.Unresolved;
        game.programMerkleRoot = programMerkleRoot;
        game.vm = vm;
        game.responseTime = responseTime;
        game.lastParticipant = game.solver;//if verifier never queries, solver should be able to trigger timeout
        game.lastParticipantTime = block.number;

        //Initialize game session and 
        game.highHash = finalStateHash;
        game.highStep = numSteps;
        //game.medHash = bytes32(0);
        //game.medStep = 0;

        bytes32[3] memory initialState = [bytes32(0), bytes32(0), bytes32(0)];
        game.lowHash = game.vm.merklizeState(initialState);
        //game.lowStep = 0;
    }

    function status(bytes32 gameId) external view returns (uint8) {
        return uint8(games[gameId].state);
    }

    function gameData(bytes32 gameId) public view returns (uint low, uint med, uint high, bytes32 medHash) {
        VerificationGame storage game = games[gameId];
        low = game.lowStep;
        med = game.medStep;
        high = game.highStep;
        medHash = game.medHash;
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
                    // the new highest is the current middle
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

        emit NewQuery(gameId, stepNumber);
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

        emit NewResponse(gameId, hash);
    }
 
    function timeout(bytes32 gameId) public {
        VerificationGame storage game = games[gameId];

        require(block.number > game.lastParticipantTime + game.responseTime);
        require(game.state == State.Unresolved || game.state == State.Challenged);

        if (game.lastParticipant == game.solver) {
            game.state = State.SolverWon;
        } else {
            game.state = State.ChallengerWon;
        }
    }

    //https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
    function checkProofOrdered(bytes proof, bytes32 root, bytes32 hash, uint256 index) public pure returns (bool) {
        // use the index to determine the node ordering
        // index ranges 1 to n

        bytes32 el;
        bytes32 h = hash;
        uint256 remaining;

        for (uint256 j = 32; j <= proof.length; j += 32) {
            assembly {
                el := mload(add(proof, j))
            }

            // calculate remaining elements in proof
            remaining = (proof.length - j + 32) / 32;

            // we don't assume that the tree is padded to a power of 2
            // if the index is odd then the proof will start with a hash at a higher
            // layer, so we have to adjust the index to be the index at that layer
            while (remaining > 0 && index % 2 == 1 && index > 2 ** remaining) {
                index = uint(index) / 2 + 1;
            }

            if (index % 2 == 0) {
                h = keccak256(el, h);
                index = index / 2;
            } else {
                h = keccak256(h, el);
                index = uint(index) / 2 + 1;
            }
        }

        return h == root;
    }


    //Should probably replace preValue and postValue with preInstruction and postInstruction
    function performStepVerification(bytes32 gameId, bytes32[3] lowStepState, bytes32[3] highStepState, bytes proof) public {
        VerificationGame storage game = games[gameId];

        require(game.state == State.Unresolved);
        require(msg.sender == game.solver);

        require(game.lowStep + 1 == game.highStep);
        // ^ must be at the end of the binary search according to the smart contract

        require(game.vm.merklizeState(lowStepState) == game.lowHash);
        require(game.vm.merklizeState(highStepState) == game.highHash);

        //require that the next instruction be included in the program merkle root
        require(checkProofOrdered(proof, game.programMerkleRoot, keccak256(highStepState[0]), game.highStep));

        bytes32[3] memory newState = game.vm.runStep(lowStepState, game.highStep, highStepState[0]);

        if (game.vm.merklizeState(newState) == game.highHash) {
            game.state = State.SolverWon;
        } else {
            game.state = State.ChallengerWon;
        }
        //FinalData(stepOutput, keccak256(stepOutput));
    }
}