const { deployContract, deployMockContract } = require('ethereum-waffle')
const ReferralManagerExposed = require('../build/ReferralManagerExposed.json')
const ERC20Mintable = require('../build/ERC20Mintable.json')

const { ethers } = require('./helpers/ethers')
const { expect } = require('chai')
const buidler = require('./helpers/buidler')
const { AddressZero } = require('ethers/constants')

const toWei = ethers.utils.parseEther

const debug = require('debug')('ptv3:ReferralManagerExposed.test')

let overrides = { gasLimit: 20000000 }

describe('ReferralManagerExposed', function() {

  let referralManager

  beforeEach(async () => {
    [wallet, wallet2, wallet3, wallet4] = await buidler.ethers.getSigners()
    
    referralManager = await deployContract(wallet, ReferralManagerExposed, [], overrides)

    debug({ referralManager: referralManager.address })
  })

  describe('initialize()', async () => {

    

  })

});
