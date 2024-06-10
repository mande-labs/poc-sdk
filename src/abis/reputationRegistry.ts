export const reputationRegistryAbi = [
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "",
        "type": "bytes32"
      }
    ],
    "name": "dapps",
    "outputs": [
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "reputationSystem",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "dappName",
        "type": "bytes32"
      }
    ],
    "name": "getDappInfo",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "owner",
            "type": "address"
          },
          {
            "internalType": "address",
            "name": "reputationSystem",
            "type": "address"
          }
        ],
        "internalType": "struct ReputationRegistry.DappInfo",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "dappName",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "reputationSystem",
        "type": "address"
      }
    ],
    "name": "registerDapp",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const;