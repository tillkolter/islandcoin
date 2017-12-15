module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*",
      from: "0xda9b1a939350dc7198165ff84c43ce77a723ef73"
    }
  }
};
