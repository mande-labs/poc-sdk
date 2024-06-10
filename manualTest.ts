import { POC } from './src/POC'; // Adjust the path based on your project structure

async function testPOC() {
    // Initialize your POC instance
    const poc = new POC();

    // Set a test dappName and a deployer private key
    // WARNING: Never use real private keys in test scripts, especially not from mainnet accounts
    const testDappName = "TestDapp";
    const testPrivateKey = "badcc5c20a79d5cde5adada2add5e809841d7356341013fe247348f7f6452485"; // Use a test private key

    try {
        // Call the init function
        await poc.init(testDappName, testPrivateKey);
        console.log("POC init function executed successfully.");

        // Add more tests as needed

    } catch (error) {
        console.error("Error during POC test:", error);
    }
}

// Run the test function
testPOC();
