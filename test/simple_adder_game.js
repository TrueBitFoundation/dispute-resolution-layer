const TaskManager = artifacts.require("./TaskManager.sol")
const SimpleAdderGame = artifacts.require("./SimpleAdderGame.sol")
const web3 = require('web3')

const toResult = (data) => {
  return {
    state: data[0].toNumber(),
    stateHash: data[1]
  }
}

contract('SimpleAdderGame', function(accounts) {
  let taskManager, simpleAdderGame, taskId, gameId, program, decodedProgram

  before(async () => {
    taskManager = await TaskManager.deployed()
    simpleAdderGame = await SimpleAdderGame.deployed()

    await taskManager.setDisputeResolver(simpleAdderGame.address, {from: accounts[0]})
    program = "0x010203040506070809"
    programLength = (program.length / 2) - 2;
  })

  it("should create a new task", async () => {
    let tx = await taskManager.newTask(program, {from: accounts[0]})
    let createdTask = tx.logs[0].args
    taskId = createdTask.taskId.toNumber()
    
    assert.equal(taskId, 0)
    assert.equal(createdTask.owner, accounts[0])
  })

  it("should post solution", async () => {
    //Figure out why it can only run up to 4
    let result = toResult(await simpleAdderGame.runToStep.call(program, programLength))
    let tx = await taskManager.postSolution(taskId, result.state, result.stateHash, {from: accounts[1]})
    let postedSolution = tx.logs[0].args

    assert.equal(taskId, postedSolution.taskId.toNumber())
    assert.equal(result.state, postedSolution.solution.toNumber())
    assert.equal(accounts[1], postedSolution.solver)
  })

  it("should start verification game", async () => {
    let tx = await taskManager.verifySolution(taskId, {from: accounts[2]})

    let createdGame = tx.logs[0].args
    gameId = createdGame.gameId.toNumber()

    assert.equal(gameId, 0)
  })

  it("should query a step", async () => {
    let step = 3
    let tx = await simpleAdderGame.query(gameId, step, {from: accounts[2]})

    let query = tx.logs[0].args
    assert.equal(query.stepNumber.toNumber(), step)
    assert.equal(query.gameId.toNumber(), gameId)
  })

  it("should respond to query", async () => {
    let result = toResult(await simpleAdderGame.runToStep.call(program, 3))

    let tx = await simpleAdderGame.respond(gameId, result.stateHash, {from: accounts[2]})

    let response = tx.logs[0].args
    assert.equal(response.hash, result.stateHash)
    assert.equal(response.gameId.toNumber(), gameId)
  })
})