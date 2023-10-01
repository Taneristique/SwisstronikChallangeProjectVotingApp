# Swistronik Voting Dapp Challange

## Contract Address 
Deployed contract can be find in the following address
https://explorer-evm.testnet.swisstronik.com/address/0xB3c509d23D8D221f405dF11f7b1DbC47bb8dfB42


## Introduction 
In this challange, I aimed to create a voting dapp to make elections in blockchain.In this app,only registered users and owner can participate in the elections.Additionaly, owner presents some 
options and users submit one of these options to the blockchain as their vote. For example if the options presented by owner are ["yes","no"] users can only submit yes or no.In that election another vote will be invalid since options are determined as ["yes","no"]. Finally if any user breaks community guidelines, owner has a right to ban that user.
## First Step 
Please provide your swisstronik private key on .env file first otherwise you will not be able to run hardhat. If you don't have a swisstronik account please refer on following documentation provided by Swisstronik : https://swisstronik.gitbook.io/swisstronik-docs/build-on-swisstronik/connect-wallets/metamask-evm-manual
## Important Notes 
1)Please provide your swisstronik private key on .env file first otherwise you will not be able to run hardhat.<br>
2)Do not forget to configure environment file and uncomment codelines start with localhost at hardhat.config.js in network section.Otherwise it is impossible to execute unit tests implemented in Election_test.js.
<br>3.)Additionaly you can find your hardhat private key as running npx hardhat node on console.After finding it write it down to related variable of .env file.
<br>4)If you have any question or problem please report it by issue section.

## QuickStart 
git clone "https://github.com/Taneristique/SwisstronikChallangeProjectVotingApp.git"<br>
npm install 

## Some Hardhat Functions 
Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
