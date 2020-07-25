const { deployContract } = require('ethereum-waffle')
const VolumeDripExposed = require('../build/VolumeDripExposed.json')

const { ethers } = require('./helpers/ethers')
const { expect } = require('chai')
const buidler = require('./helpers/buidler')

const toWei = ethers.utils.parseEther

const debug = require('debug')('ptv3:VolumeDripExposed.test')

let overrides = { gasLimit: 20000000 }

describe('VolumeDripExposed', function() {

  let volumeDrip

  beforeEach(async () => {
    [wallet, wallet2, wallet3, wallet4] = await buidler.ethers.getSigners()
    
    volumeDrip = await deployContract(wallet, VolumeDripExposed, [], overrides)

    debug({ volumeDrip: volumeDrip.address })

    await volumeDrip.initialize(
      100,
      toWei('0.1'),
      1700
    )
  })

  describe('initialize()', async () => {
    it('should initialize the VolumeDrip to the correct parameters', async () => {
      const drip = await volumeDrip.getDrip();

      expect(drip.periodBlocks).to.equal(100)
      expect(drip.periodStartedAt).to.equal(1700)
      expect(drip.dripRatePerBlock).to.equal(toWei('0.1'))
    })
  })

  describe('isPeriodOver()', async () => {
    it('should be true when the period is over', async () => {
      expect(await volumeDrip.isPeriodOver(1799)).to.be.false
      expect(await volumeDrip.isPeriodOver(1800)).to.be.true
    })
  })

  describe('mint()', async () => {
    it('should accrue balance to a user for the current period', async () => {
      await volumeDrip.mint(wallet2._address, toWei('10'), 1701);

      const deposit = await volumeDrip.getDeposit(wallet2._address);

      expect(deposit.balance).to.equal(toWei('10'))
      expect(deposit.period).to.equal(1)
      expect(deposit.accrued).to.equal('0')
    })

    it('should accrue previous balances', async () => {
      await volumeDrip.mint(wallet2._address, toWei('10'), 1701);
      await volumeDrip.mint(wallet2._address, toWei('11'), 1800);

      const deposit = await volumeDrip.getDeposit(wallet2._address);

      expect(deposit.balance).to.equal(toWei('11'))
      expect(deposit.period).to.equal(2)
      expect(deposit.accrued).to.equal(toWei('10'))
    })
  })

  describe('completePeriod()', () => {
    it('should not accrue anything if no one has deposited', async () => {
      await volumeDrip.completePeriod(1900) // 200 blocks
      const period = await volumeDrip.getPeriod(1)
      expect(period.totalSupply).to.equal(0)
      expect(period.totalAccrued).to.equal(0)
    })

    it('should accrue when someone has deposited', async () => {
      await volumeDrip.mint(wallet2._address, toWei('10'), 1701);
      await volumeDrip.completePeriod(1900) // 200 blocks
      const period = await volumeDrip.getPeriod(1)
      expect(period.totalSupply).to.equal(toWei('10'))
      expect(period.totalAccrued).to.equal(toWei('20')) // 200 * 0.1 = 20
    })
  })

  describe('burnDrip()', () => {
    it('should allow a user to burn their accrued drip', async () => {
      await volumeDrip.mint(wallet2._address, toWei('10'), 1701);
      await volumeDrip.mint(wallet2._address, toWei('10'), 1800);

      // notice that two rounds should be available
      let tx = await volumeDrip.burnDrip(wallet2._address, 1900);
      let receipt = await buidler.ethers.provider.getTransactionReceipt(tx.hash)

      let event = volumeDrip.interface.parseLog(receipt.logs[0])

      // they accrued over two periods
      expect(event.values.amount).to.equal(toWei('20'))
    })
  })

});
