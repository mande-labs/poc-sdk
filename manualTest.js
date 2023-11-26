"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var POC_1 = require("./src/POC");
var poc = new POC_1.POC();
// Test initialization
try {
    poc.init('MyDapp', '0x123...');
    poc.printDappName(); // This will print: The dApp name is: MyDapp
}
catch (error) {
    console.error('Initialization failed:', error.message);
}
// Add more test scenarios here
