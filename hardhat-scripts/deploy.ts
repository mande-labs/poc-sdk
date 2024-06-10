import hre from "hardhat";

async function main() {
  const reputationRegistry = await hre.viem.deployContract("ReputationRegistry", []);

  console.log(
    `ReputationRegistry deployed to ${reputationRegistry.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
