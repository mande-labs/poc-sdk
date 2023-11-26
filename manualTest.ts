import { POC } from './src/POC';

const poc = new POC();

// Test initialization
try {
    poc.init('MyDapp', '0x123...');
    poc.printDappName();  // This will print: The dApp name is: MyDapp
} catch (error) {
    console.error('Initialization failed:', error.message);
}

// Add more test scenarios here