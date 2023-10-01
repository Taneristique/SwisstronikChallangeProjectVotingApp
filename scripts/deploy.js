const { ethers } = require("hardhat");

async function main() {
  const election = await ethers.deployContract("VotingApp");
  console.log(`Election contract was deployed to ${election.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});