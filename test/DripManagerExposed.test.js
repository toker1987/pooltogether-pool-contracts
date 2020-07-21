const { deployContract, deployMockContract } = require('ethereum-waffle')
const DripManagerExposed = require('../build/DripManagerExposed.json')
const ERC20Mintable = require('../build/ERC20Mintable.json')

const { ethers } = require('./helpers/ethers')
const { expect } = require('chai')
const buidler = require('./helpers/buidler')
const { AddressZero } = require('ethers/constants')

const toWei = ethers.utils.parseEther

const debug = require('debug')('ptv3:DripManagerExposed.test')

let overrides = { gasLimit: 20000000 }

describe('DripManagerExposed', function() {

  let dripExposed

  let measure, drip1, drip2

  beforeEach(async () => {
    [wallet, wallet2, wallet3, wallet4] = await buidler.ethers.getSigners()
    
    dripExposed = await deployContract(wallet, DripManagerExposed, [], overrides)

    debug({ dripExposed: dripExposed.address })

    measure = await deployContract(wallet, ERC20Mintable, [], overrides)
    drip1 = await deployContract(wallet, ERC20Mintable, [], overrides)
    drip2 = await deployContract(wallet, ERC20Mintable, [], overrides)
  })

  describe('addDripToken()', () => {
    it('should add a drip token', async () => {
      await dripExposed.addDripToken(measure.address, drip1.address, toWei('0.001'), '1')
      expect(await dripExposed.hasDripToken(measure.address, drip1.address)).to.be.true
    })

    it('should not add a drip token twice', async () => {
      await dripExposed.addDripToken(measure.address, drip1.address, toWei('0.001'), '1')
      await expect(dripExposed.addDripToken(measure.address, drip1.address, toWei('0.001'), '2')).to.be.revertedWith('DripManager/drip-exists')
    })
  })

  describe('setDripRate()', () => {
    it('should allow the drip rate to be changed', async () => {
      await dripExposed.addDripToken(measure.address, drip1.address, toWei('0.001'), '1')
      await dripExposed.setDripRate(measure.address, drip1.address, toWei('0.1'))

      let detail = await dripExposed.getDrip(measure.address, drip1.address)

      expect(detail.dripRatePerBlock).to.equal(toWei('0.1'))
    })
  })

  describe('updateDrips()', () => {
    it('should allow a user that has accrued to claim their tokens', async () => {
      await dripExposed.addDripToken(measure.address, drip1.address, toWei('0.001'), '1')

      // give the dripExposed some tokens to distribute
      await drip1.mint(dripExposed.address, toWei('1000'))

      // give the wallet some of the measured tokens
      await measure.mint(wallet._address, toWei('100'))

      // first drip should do nothing
      await dripExposed.updateDrips(measure.address, wallet._address, '2')
      // user should not have accrued
      expect(await dripExposed.balanceOfDrip(wallet._address, measure.address, drip1.address)).to.equal(toWei('0'))

      // next drip should accrue their max share
      await dripExposed.updateDrips(measure.address, wallet._address, '3')
      // user should accrue the total per block
      expect(await dripExposed.balanceOfDrip(wallet._address, measure.address, drip1.address)).to.equal(toWei('0.001'))

      // give someone else half the measured tokens
      await measure.mint(wallet2._address, toWei('100'))

      // next drip should accrue *half* of whats available
      await dripExposed.updateDrips(measure.address, wallet._address, '4')
      expect(await dripExposed.balanceOfDrip(wallet._address, measure.address, drip1.address)).to.equal(toWei('0.0015'))
    })
  })

  describe('claimDrip()', () => {
    it('should allow a user to transfer tokens to themselves', async () => {
      await dripExposed.addDripToken(measure.address, drip1.address, toWei('0.001'), '1')
      // give the dripExposed some tokens to distribute
      await drip1.mint(dripExposed.address, toWei('1000'))

      // give the wallet some of the measured tokens
      await measure.mint(wallet._address, toWei('100'))

      // first drip should do nothing
      await dripExposed.updateDrips(measure.address, wallet._address, '2')
      // next drip should accrue their max share
      await dripExposed.updateDrips(measure.address, wallet._address, '3')
      // user should accrue the total per block
      expect(await dripExposed.balanceOfDrip(wallet._address, measure.address, drip1.address)).to.equal(toWei('0.001'))

      await dripExposed.claimDrip(wallet._address, measure.address, drip1.address)

      expect(await drip1.balanceOf(wallet._address)).to.equal(toWei('0.001'))
      expect(await dripExposed.balanceOfDrip(wallet._address, measure.address, drip1.address)).to.equal(toWei('0'))
    })
  })

});
