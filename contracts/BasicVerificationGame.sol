pragma solidity ^0.4.18;

import "./IComputationLayer.sol";
import "./IDisputeResolutionLayer.sol";

/**
 * @title Verification game for basic examples
 */
contract BasicVerificationGame is IDisputeResolutionLayer {
    /**
     * @notice A challenge has been committed
     */
    event ChallengeCommitted(address solver, address verifier, bytes32 gameId);

    /**
     * @notice A new game has been started
     */
    event NewGame(bytes32 gameId, address solver, address verifier);

    /**
     * @notice A new query has been sent
     */
    event NewQuery(bytes32 gameId, uint stepNumber);

    /**
     * @notice A new response has been sent
     */
    event NewResponse(bytes32 gameId, bytes32 hash);

    /**
     * @notice States of the verification game
     */
    enum State { Uninitialized, Challenged, Unresolved, SolverWon, ChallengerWon }

    struct VerificationGame {
        // Roles
        address solver;
        address verifier;

        // Verification game state
        State state;

        // Verification game layer
        IComputationLayer vm;

        // Immutable session variables
        bytes32 spec;
        bytes32 programMerkleRoot;
        uint responseTime;

        // Mutable session variables
        address lastParticipant;
        uint lastParticipantTime;
        uint lowStep;
        bytes32 lowHash;
        uint medStep;
        bytes32 medHash;
        uint highStep;
        bytes32 highHash;
    }

    /**
     * @notice Game storage
     */
    mapping(bytes32 => VerificationGame) private games;

    /**
     * @notice Incrementing identifier
     */
    uint private uniq;

    /**
     * @notice Special flag to indicate a hash has been queried and is awaiting
     * a response
     */
    bytes32 private constant HASH_AWAITING_RESPONSE = bytes32(0);

    /**
     * @notice Implementation of IDisputeResolutionLayer.commitChallenge()
     */
    function commitChallenge(address solver, address verifier, bytes32 spec) external returns (bytes32 gameId) {
        gameId = keccak256(solver, verifier, spec, uniq);

        VerificationGame storage game = games[gameId];

        // Initialize roles
        game.solver = solver;
        game.verifier = verifier;

        // Initialize verification game state
        game.state = State.Challenged;

        // Initialize immutable session variables
        game.spec = spec;

        uniq++;
        emit ChallengeCommitted(solver, verifier, gameId);
    }

    /**
     * @notice Initialize a new verification game
     *
     * @dev This is Dispute Resolution Layer specific
     */
    function initGame(
        bytes32 gameId,
        bytes32 programMerkleRoot,
        bytes32 finalStateHash,
        uint numSteps,
        uint responseTime,
        IComputationLayer vm
    ) public {
        // Can't play an empty game
        require(numSteps > 0);

        VerificationGame storage game = games[gameId];

        require(game.state == State.Challenged);

        // Initialize verification game layers
        game.vm = vm;

        // Initialize immutable session variables
        game.programMerkleRoot = programMerkleRoot;
        game.responseTime = responseTime;

        // Initialize mutable session variables
        game.state = State.Unresolved;
        game.lastParticipant = game.solver; // If verifier never queries, solver should be able to trigger timeout
        game.lastParticipantTime = block.number;
        //game.lowStep = 0;
        bytes32[3] memory initialState;
        game.lowHash = game.vm.merklizeState(initialState);
        //game.medStep = 0;
        //game.medHash = bytes32(0);
        game.highStep = numSteps;
        game.highHash = finalStateHash;
    }

    /**
     * @notice Implementation of IDisputeResolutionLayer.status()
     */
    function status(bytes32 gameId) external view returns (uint8) {
        return uint8(games[gameId].state);
    }

    /**
     * @notice Get information about a verification game
     *
     * @param gameId The game ID
     *
     * @return low The low step of the binary search
     * @return med The middle step of the binary search
     * @return high The high step of the binary search
     * @return medHash The hash of the middle step
     */
    function gameData(bytes32 gameId) public view returns (uint low, uint med, uint high, bytes32 medHash) {
        VerificationGame storage game = games[gameId];

        low = game.lowStep;
        med = game.medStep;
        high = game.highStep;
        medHash = game.medHash;
    }

    /**
     * @notice Query a step in the verification game
     *
     * @dev Sent by the verifier
     *
     * @param gameId The game ID
     * @param stepNumber The step number to query
     */
    function query(bytes32 gameId, uint stepNumber) public {
        VerificationGame storage game = games[gameId];

        require(msg.sender == game.verifier);
        require(game.state == State.Unresolved);

        // Invariant: if the step has been set but we don't have a hash for it
        bool isFirstStep = game.medStep == 0;
        bool haveMedHash = game.medHash != bytes32(0);
        require(isFirstStep || haveMedHash);

        if (stepNumber == game.lowStep && stepNumber + 1 == game.medStep) {
            // Final step of the binary search (lower end)
            game.highHash = game.medHash;
            game.highStep = stepNumber + 1;
        } else if (stepNumber == game.medStep && stepNumber + 1 == game.highStep) {
            // Final step of the binary search (upper end)
            game.lowHash = game.medHash;
            game.lowStep = stepNumber;
        } else {
            // This next step must be in the correct range
            require(stepNumber > game.lowStep && stepNumber < game.highStep);

            // If this is NOT the first query, update the steps and assign the
            // correct hash. If this IS the first query, we just want to
            // initialize medStep and medHash.
            if (!isFirstStep) {
                if (stepNumber < game.medStep) {
                    // If we're iterating lower, the new highest is the current middle
                    game.highStep = game.medStep;
                    game.highHash = game.medHash;
                } else if (stepNumber > game.medStep) {
                    // If we're iterating upwards, the new lowest is the current middle
                    game.lowStep = game.medStep;
                    game.lowHash = game.medHash;
                } else {
                    // And if we're requesting the midStep that we've already requested,
                    // revert to prevent replay
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

    /**
     * @notice Respond to a query
     *
     * @dev Sent by the solver
     *
     * @param gameId The game ID
     * @param stepNumber The step number in the verification game
     * @param hash The resulting hash
     */
    function respond(bytes32 gameId, uint stepNumber, bytes32 hash) public {
        VerificationGame storage game = games[gameId];

        require(msg.sender == game.solver);
        require(game.state == State.Unresolved);

        // Require step to avoid replay problems
        require(stepNumber == game.medStep);

        // Provided hash cannot be special flag
        require(hash != HASH_AWAITING_RESPONSE);

        // record the claimed hash
        require(game.medHash == bytes32(0));
        game.medHash = hash;

        game.lastParticipantTime = block.number;
        game.lastParticipant = game.solver;

        emit NewResponse(gameId, hash);
    }

    /**
     * @notice TODO: Document
     *
     * @param gameId The game ID
     */
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

    /**
     * @notice Check Merkle proof
     *
     * @dev See https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
     *
     * @param proof The proof
     * @param root The Merkle root
     * @param hash The resulting hash
     * @param index The index into the Merkle structure
     *
     * @return True if the proof is correct, false otherwise
     */
    function checkProofOrdered(bytes proof, bytes32 root, bytes32 hash, uint256 index) public pure returns (bool) {
        // Use the index to determine the node ordering (index ranges 1 to n)

        bytes32 el;
        bytes32 h = hash;
        uint256 remaining;

        for (uint256 j = 32; j <= proof.length; j += 32) {
            assembly {
                el := mload(add(proof, j))
            }

            // Calculate remaining elements in proof
            remaining = (proof.length - j + 32) / 32;

            // We don't assume that the tree is padded to a power of 2. If the index
            // is odd then the proof will start with a hash at a higher layer, so we
            // have to adjust the index to be the index at that layer.
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

    /**
     * @notice Perform verification of a single step
     *
     * @dev Sent by the solver
     *
     * @param gameId The game ID
     * @param lowStepState The state of the game at the lower step
     * @param highStepState The state of the state at the upper step
     * @param nextInstruction The input used to go from the lower step to the upper step
     * @param proof The Merkle proof
     */
    function performStepVerification(
        bytes32 gameId,
        bytes32[3] lowStepState,
        bytes32[3] highStepState,
        bytes32 nextInstruction,
        bytes proof
    ) public {
        VerificationGame storage game = games[gameId];

        require(game.state == State.Unresolved);
        require(msg.sender == game.solver);

        // Must be at the end of the binary search according to the smart contract
        require(game.lowStep + 1 == game.highStep);

        require(game.vm.merklizeState(lowStepState) == game.lowHash);
        require(game.vm.merklizeState(highStepState) == game.highHash);

        // Require that the next action be included in the action Merkle root
        require(checkProofOrdered(proof, game.programMerkleRoot, keccak256(nextInstruction), game.highStep));

        bytes32[3] memory newState = game.vm.runStep(lowStepState, nextInstruction);

        if (game.vm.merklizeState(newState) == game.highHash) {
            game.state = State.SolverWon;
        } else {
            game.state = State.ChallengerWon;
        }
        //FinalData(stepOutput, keccak256(stepOutput));
    }
}
