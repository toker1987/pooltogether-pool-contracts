const {TASK_COMPILE_GET_COMPILER_INPUT} = require('@nomiclabs/buidler/builtin-tasks/task-names');

task(TASK_COMPILE_GET_COMPILER_INPUT).setAction(async (_, __, runSuper) => {
  const input = await runSuper();
  input.settings.metadata.useLiteralContent = false;
  return input;
})

usePlugin('@nomiclabs/buidler-waffle');
usePlugin('buidler-gas-reporter');
usePlugin('solidity-coverage');
usePlugin('@nomiclabs/buidler-etherscan');
usePlugin('buidler-deploy');

module.exports = {
  solc: {
    version: '0.6.4',
    optimizer: {
      enabled: true,
      runs: 200
    },
    evmVersion: 'istanbul'
  },
  paths: {
    artifacts: './build',
    deploy: './deploy',
    deployments: './deployments'
  },
  networks: {
    buidlerevm: {
      blockGasLimit: 200000000,
      allowUnlimitedContractSize: true
    },
    coverage: {
      url: 'http://127.0.0.1:8555',
      blockGasLimit: 200000000,
      allowUnlimitedContractSize: true
    },
    local: {
      url: 'http://127.0.0.1:' + process.env.LOCAL_BUIDLEREVM_PORT || '8545',
      blockGasLimit: 200000000
    }
  },
  gasReporter: {
    currency: 'CHF',
    gasPrice: 21,
    enabled: (process.env.REPORT_GAS) ? true : false
  },
  namedAccounts: {
    deployer: {
      default: 0, // local; Account 1
      1: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // mainnet
      3: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // ropsten
      42: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // kovan
    },
    forwarder: {
      default: 9, // local; Account 10
      1: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // mainnet
      3: '0xcC87aa60a6457D9606995C4E7E9c38A2b627Da88', // ropsten
      42: '0x6453D37248Ab2C16eBd1A8f782a2CBC65860E60B', // kovan
    },
    governor: {
      default: 10, // local; Account 11
      1: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // mainnet
      3: '0xD215CF8D8bC151414A9c5c145fE219E746E5cE80', // ropsten
      42: '0x2f935900D89b0815256a3f2c4c69e1a0230b5860', // kovan
    },
    rngInterface: {
      default: 11, // local; Account 12
      1: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // mainnet
      3: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // ropsten
      42: '0x1337c0d31337c0D31337C0d31337c0d31337C0d3', // kovan
    }
  }
};
