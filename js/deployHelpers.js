
const toWei = ethers.utils.parseEther
const toEth = ethers.utils.formatEther

const txOverrides = (options = {}) => ({gas: 4000000, ...options})

const contractManager = (bre) => async (contractName, overrides = {}) => {
  const { ethers, deployments } = bre
  const { deployIfDifferent, log } = deployments

  const [ deployer ] = await ethers.getSigners()
  overrides.from = overrides.from || deployer._address

  let contract = await deployments.getOrNull(contractName)
  if (!contract) {
    log(`  Deploying ${contractName}...`)
    const deployResult = await deployIfDifferent(['data'], contractName, txOverrides(overrides), contractName)
    contract = await deployments.get(contractName)
    if (deployResult.newlyDeployed) {
      log(`  - deployed at ${contract.address} for ${deployResult.receipt.gasUsed} WEI`)
    }
  }

  //  Return an Ethers Contract instance with the "deployer" as Signer
  return new ethers.Contract(contract.address, contract.abi, deployer)
}


module.exports = {
  txOverrides,
  contractManager,
  toWei,
  toEth,
}
