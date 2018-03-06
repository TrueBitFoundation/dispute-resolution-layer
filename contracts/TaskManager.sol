pragma solidity ^0.4.18;

import './IDisputeResolutionLayer.sol';

//This is a basic task manager contract used for testing the dispute resolution layer interface

contract TaskManager {

  // IDisputeResolutionLayer disputeResolver;

  // function setDisputeResolver(IDisputeResolutionLayer _disputeResolver) public {
  //   disputeResolver = _disputeResolver;
  // }

  // struct Task {
  //   address owner;
  //   address solver;
  //   address verifier;
  //   bytes taskInput;
  //   uint solution;
  //   bytes32 solutionHash;
  //   uint gameId;
  // }

  // mapping(uint => Task) tasks;
  // uint numTasks = 0;

  // event TaskCreated(uint taskId, address owner);
  // event SolutionPosted(uint taskId, uint solution, address solver);
  // event GameStarted(uint gameId);

  // function newTask(bytes _taskInput) public {
  //   Task storage t = tasks[numTasks];
  //   t.owner = msg.sender;
  //   t.taskInput = _taskInput;
  //   numTasks = numTasks + 1;
  //   TaskCreated(numTasks-1, msg.sender);
  // }

  // function getTaskInput(uint taskId) public view returns(bytes) {
  //   return tasks[taskId].taskInput;
  // }

  // function postSolution(uint taskId, uint solution, bytes32 solutionHash) {
  //   Task storage t = tasks[taskId];
  //   require(t.solver == 0x0);
  //   t.solver = msg.sender;
  //   t.solution = solution;
  //   t.solutionHash = solutionHash;
  //   SolutionPosted(taskId, solution, msg.sender);
  // }

  // function verifySolution(uint taskId) {
  //   Task storage t = tasks[taskId];
  //   t.verifier = msg.sender;

  //   //more thought needs to be given as to what numSteps should be set at
  //   t.gameId = disputeResolver.newGame(taskId, t.solver, t.verifier, t.taskInput, keccak256(t.solution), 100);
  //   GameStarted(t.gameId);
  // }
}