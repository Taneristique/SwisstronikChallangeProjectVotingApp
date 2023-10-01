require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
/*uncomment following lines inside of networks section to be able to execute the unit tests 
   /*localhost: {
      url: "https://json-rpc.testnet.swisstronik.com/",
      accounts: [`0x` + `${process.env.localSecret}`],
}*/
module.exports = {
  solidity: "0.8.18",
  networks: {
    swisstronik: {
      // If you're using local testnet, replace `url` with local json-rpc address
      url: "https://json-rpc.testnet.swisstronik.com/",
      accounts: [`0x` + `${process.env.secret}`],
    },
    /*localhost: {
      url: "https://json-rpc.testnet.swisstronik.com/",
      accounts: [`0x` + `${process.env.localSecret}`],
    }*/
  },
};