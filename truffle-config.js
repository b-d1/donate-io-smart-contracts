var HDWalletProvider = require("truffle-hdwallet-provider");

/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a 
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() { 
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>') 
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*" // Match any network id
        },
        testnet: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*" // Match any network id
        },
        infura: {
            provider: function() {
                return new HDWalletProvider('rabbit deliver lift armed decade danger course adult charge tuna cancel erode tool arrest inmate', "https://ropsten.infura.io/v3/7639deda6f374a59b23a5233702d7afb")
            },
            network_id: 3,
            gas: 4500000

        }
    }
};
