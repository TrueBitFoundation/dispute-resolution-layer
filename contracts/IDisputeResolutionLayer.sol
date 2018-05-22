pragma solidity ^0.4.18;

/**
 * @title Dispute resolution layer interface
 */
interface IDisputeResolutionLayer {
    /**
     * @notice Get the status of a verification game
     *
     * @param gameId The game ID
     *
     * @return A status representing the internal state of the game
     */
    function status(bytes32 gameId) external view returns (uint8);

    /**
     * @notice Commit a verifier to a challenge
     *
     * @dev If the verifier doesn't send a query before the response time,
     * they are eligible to be penalized.
     *
     * @param solver The solver
     * @param verifier The verifier
     * @param spec ??? (TODO)
     *
     * @return The game ID
     */
    function commitChallenge(address solver, address verifier, bytes32 spec) external returns (bytes32 gameId);
}
