// using plugin: buidler-deploy
// reference: https://buidler.dev/plugins/buidler-deploy.html

const {
  txOverrides,
  contractManager,
  toWei,
  toEth,
} = require('../js/deployHelpers')

module.exports = async (bre) => {
  const { ethers, getNamedAccounts, deployments } = bre
  const { log } = deployments
  const _getContract = contractManager(bre)

  // Named accounts, defined in buidler.config.js:
  const { deployer, governor, forwarder, rngInterface } = await getNamedAccounts()

  log("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
  log("PoolTogether Pool - Contract Deploy Script")
  log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")

  const signers = await ethers.getSigners()
  log({signers})

  log("  Using Accounts:")
  log("  - Deployer:  ", deployer)
  log("\n  Using Contracts:")
  log("  - Governor:  ", governor)
  log("  - Forwarder: ", forwarder)
  log("  - RNG:       ", rngInterface)
  log(" ")

  const TicketFactory                           = await _getContract('TicketFactory')
  const ControlledTokenFactory                  = await _getContract('ControlledTokenFactory')
  const CompoundPeriodicPrizePoolFactory        = await _getContract('CompoundPeriodicPrizePoolFactory')
  const SingleRandomWinnerPrizeStrategyFactory  = await _getContract('SingleRandomWinnerPrizeStrategyFactory')
  const PrizePoolBuilder                        = await _getContract('PrizePoolBuilder')
  const SingleRandomWinnerPrizePoolBuilder      = await _getContract('SingleRandomWinnerPrizePoolBuilder')

  log("\n  Initializing...")
  await TicketFactory.initialize()
  await ControlledTokenFactory.initialize()
  await CompoundPeriodicPrizePoolFactory.initialize()
  await SingleRandomWinnerPrizeStrategyFactory.initialize()

  await PrizePoolBuilder.initialize(governor, CompoundPeriodicPrizePoolFactory.address, TicketFactory.address, ControlledTokenFactory.address, forwarder)
  await SingleRandomWinnerPrizePoolBuilder.initialize(PrizePoolBuilder.address, rngInterface, SingleRandomWinnerPrizeStrategyFactory.address)


  // Display Contract Addresses
  log("\n  Contract Deployments Complete!\n\n  Factories:")
  log("  - TicketFactory:                           ", TicketFactory.address)
  log("  - ControlledTokenFactory:                  ", ControlledTokenFactory.address)
  log("  - CompoundPeriodicPrizePoolFactory:        ", CompoundPeriodicPrizePoolFactory.address)
  log("  - SingleRandomWinnerPrizeStrategyFactory:  ", SingleRandomWinnerPrizeStrategyFactory.address)

  log("\n  Builders:")
  log("  - PrizePoolBuilder:                        ", PrizePoolBuilder.address)
  log("  - SingleRandomWinnerPrizePoolBuilder:      ", SingleRandomWinnerPrizePoolBuilder.address)

  log("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n")
}
