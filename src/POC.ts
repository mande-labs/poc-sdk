import { createPublicClient, createWalletClient, http, stringToHex, PublicClient, Address, WalletClient } from 'viem';
import { privateKeyToAccount } from 'viem/accounts'
import { scrollSepolia } from 'viem/chains';
import { reputationRegistryAbi } from './abis/reputationRegistry';

export class POC {
    private client: PublicClient;
    private reputationRegistryAddress: Address; // Replace with the deployed contract address

    constructor() {
    	this.reputationRegistryAddress = "0x0e41057b1dfb745949d147dfc79448e2994d5a37";
        this.client = createPublicClient({
            chain: scrollSepolia,
            transport: http(),
        });
    }

    public async init(dappName: string, deployerPrivateKey: string): Promise<void> {
    	const walletClient: WalletClient = createWalletClient({
		  account: privateKeyToAccount(`0x${deployerPrivateKey}`),
		  chain: scrollSepolia,
		  transport: http(),
		});
    	const bytes32DappName = stringToHex(dappName, {size: 32});

        if (!dappName || !deployerPrivateKey) {
            throw new Error("Invalid parameters: dappName and deployerPrivateKey are required.");
        }

        try {

            // TODO: Execute hardhat task for deployment of barebone dummy reputation system

	        // TODO: fix simulateContract for proper error handling
            // const result = await this.client.simulateContract({
			//   account: privateKeyToAccount(`0x${deployerPrivateKey}`),
			//   address: this.reputationRegistryAddress,
			//   abi: reputationRegistryAbi,
			//   functionName: 'registerDapp',
			//   args: [bytes32DappName, this.reputationRegistryAddress],
			// })
			// const tx = await walletClient.writeContract(result?.request)

            const hash = await walletClient.writeContract({
                address: this.reputationRegistryAddress,
                abi: reputationRegistryAbi,
                functionName: 'registerDapp',
                account: privateKeyToAccount(`0x${deployerPrivateKey}`),
                args: [bytes32DappName, this.reputationRegistryAddress],
                chain: scrollSepolia
            })
			await this.client.waitForTransactionReceipt({
                hash,
            });
            console.log(`Tx successful with hash: ${hash}`);
		} catch (error) {
            console.error('Error registering dApp:', error);
        }
    }

    // Additional methods and logic for the POC class can be added here
}
