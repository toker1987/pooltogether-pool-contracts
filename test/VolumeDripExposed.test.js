const { deployContract, deployMockContract } = require('ethereum-waffle')
const VolumeDripExposed = require('../build/VolumeDripExposed.json')
const ERC20Mintable = require('../build/ERC20Mintable.json')

const { ethers } = require('./helpers/ethers')
const { expect } = require('chai')
const buidler = require('./helpers/buidler')
const { AddressZero } = require('ethers/constants')

const toWei = ethers.utils.parseEther

const debug = require('debug')('ptv3:VolumeDripExposed.test')

let overrides = { gasLimit: 20000000 }

describe('VolumeDripExposed', function() {

  let volumeDrip

  beforeEach(async () => {
    [wallet, wallet2, wallet3, wallet4] = await buidler.ethers.getSigners()
    
    volumeDrip = await deployContract(wallet, VolumeDripExposed, [], overrides)

    debug({ volumeDrip: volumeDrip.address })
  })

  describe('initialize()', async () => {

    

  })

});
