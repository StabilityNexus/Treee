import 'package:flutter_dotenv/flutter_dotenv.dart';

const String organisationFactoryContractAbi = ''' [
    {
      "type": "constructor",
      "inputs": [
        {
          "name": "_treeNFTContract",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "addMemberToOrganisation",
      "inputs": [
        {
          "name": "_member",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "createOrganisation",
      "inputs": [
        {
          "name": "_name",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "_description",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "_photoIpfsHash",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [
        {
          "name": "organisationId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "organisationAddress",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "getAllOrganisationDetails",
      "inputs": [],
      "outputs": [
        {
          "name": "organizationDetails",
          "type": "tuple[]",
          "internalType": "struct OrganisationDetails[]",
          "components": [
            {
              "name": "contractAddress",
              "type": "address",
              "internalType": "address"
            },
            {
              "name": "name",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "description",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "organisationPhoto",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "owners",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "members",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "ownerCount",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "memberCount",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "isActive",
              "type": "bool",
              "internalType": "bool"
            },
            {
              "name": "timeOfCreation",
              "type": "uint256",
              "internalType": "uint256"
            }
          ]
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getAllOrganisations",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address[]",
          "internalType": "address[]"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getMyOrganisations",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address[]",
          "internalType": "address[]"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getOrganisationCount",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getOrganisationInfo",
      "inputs": [
        {
          "name": "_organisationAddress",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "organisationAddress",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "name",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "description",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "photoIpfsHash",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "owners",
          "type": "address[]",
          "internalType": "address[]"
        },
        {
          "name": "members",
          "type": "address[]",
          "internalType": "address[]"
        },
        {
          "name": "timeOfCreation",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getTreeNFTContract",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getUserOrganisations",
      "inputs": [
        {
          "name": "_user",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "address[]",
          "internalType": "address[]"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "owner",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "removeOrganisation",
      "inputs": [
        {
          "name": "_organisationAddress",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "renounceOwnership",
      "inputs": [],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "s_organisationAddressToOrganisation",
      "inputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "contract Organisation"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "s_userToOrganisations",
      "inputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "transferOwnership",
      "inputs": [
        {
          "name": "newOwner",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "treeNFTContract",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "updateTreeNFTContract",
      "inputs": [
        {
          "name": "_newTreeNFTContract",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "event",
      "name": "OwnershipTransferred",
      "inputs": [
        {
          "name": "previousOwner",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "newOwner",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        }
      ],
      "anonymous": false
    },
    {
      "type": "error",
      "name": "InvalidDescriptionInput",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidInput",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidNameInput",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidOrganisation",
      "inputs": []
    },
    {
      "type": "error",
      "name": "OrganisationDoesNotExist",
      "inputs": []
    },
    {
      "type": "error",
      "name": "OwnableInvalidOwner",
      "inputs": [
        {
          "name": "owner",
          "type": "address",
          "internalType": "address"
        }
      ]
    },
    {
      "type": "error",
      "name": "OwnableUnauthorizedAccount",
      "inputs": [
        {
          "name": "account",
          "type": "address",
          "internalType": "address"
        }
      ]
    }
  ]''';
final String organisationFactoryContractAddress =
    dotenv.env['ORGANISATION_FACTORY_CONTRACT_ADDRESS'] ?? '';
