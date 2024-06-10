import hre from "hardhat";
import { Address, privateKeyToAccount } from 'viem/accounts'
const { getSelectors, FacetCutAction } = require('./libraries/diamond')

async function deployDiamond() {
  const account = privateKeyToAccount(`0x${process.env.PRIVATE_KEY}` as Address)
  const contractOwner = account.address;

  // deploy DiamondCutFacet
  const diamondCutFacet = await hre.viem.deployContract("DiamondCutFacet", []);
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // deploy Diamond
  const diamond = await hre.viem.deployContract("Diamond", [contractOwner, diamondCutFacet.address]);
  console.log('Diamond deployed:', diamond.address)

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const diamondInit = await hre.viem.deployContract("DiamondInit", []);
  console.log('DiamondInit deployed:', diamondInit.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet'
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const facet = await hre.viem.deployContract(FacetName, []);
    console.log("check facte here - ", JSON.stringify(facet));
    return;
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }
  return;
  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  return diamond.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployDiamond().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

exports.deployDiamond = deployDiamond