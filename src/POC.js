"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.POC = void 0;
var POC = /** @class */ (function () {
    function POC() {
        this.dappName = "";
        this.deployerPrivateKey = "";
    }
    POC.prototype.init = function (dappName, deployerPrivateKey) {
        if (!dappName || !deployerPrivateKey) {
            throw new Error("Invalid parameters: dappName and deployerPrivateKey are required.");
        }
        this.dappName = dappName;
        this.deployerPrivateKey = deployerPrivateKey;
        // Initialize the SDK with the specified dApp name and deployer's private key
        // Add any additional setup logic here
        console.log("SDK initialized for dApp: ".concat(this.dappName));
    };
    POC.prototype.printDappName = function () {
        console.log("The dApp name is: ".concat(this.dappName));
    };
    return POC;
}());
exports.POC = POC;
