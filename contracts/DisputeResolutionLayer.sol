pragma solidity 0.4.19;

contract DisputeResolutionLayer {

  struct Session {
    bytes data;
    bytes32 dataHash;
    address creator;
    uint numBlocksTimeout;
    bytes32 lastResponse;
    uint lastStep;
  }

  function DisputeResolutionLayer() public {

  }

  function query() public {

  }

  function respond() public {

  }

  function checkProof() public {

  }

}