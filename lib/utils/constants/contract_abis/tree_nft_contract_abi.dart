// ignore: constant_identifier_names
const String TreeNftContractABI = '''[
    {
      "type": "constructor",
      "inputs": [
        {
          "name": "_careTokenContract",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "_planterTokenContract",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "_verifierTokenContract",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "_legacyTokenContract",
          "type": "address",
          "internalType": "address"
        }
      ],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "approve",
      "inputs": [
        {
          "name": "to",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "balanceOf",
      "inputs": [
        {
          "name": "owner",
          "type": "address",
          "internalType": "address"
        }
      ],
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
      "name": "careTokenContract",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "contract CareToken"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getAllNFTs",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "tuple[]",
          "internalType": "struct Tree[]",
          "components": [
            {
              "name": "id",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "latitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "longitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planting",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "death",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "species",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "imageUri",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "qrIpfsHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "metadata",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "photos",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "geoHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "ancestors",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "lastCareTimestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careCount",
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
      "name": "getApproved",
      "inputs": [
        {
          "name": "tokenId",
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
      "name": "getNFTsByUser",
      "inputs": [
        {
          "name": "user",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "tuple[]",
          "internalType": "struct Tree[]",
          "components": [
            {
              "name": "id",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "latitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "longitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planting",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "death",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "species",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "imageUri",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "qrIpfsHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "metadata",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "photos",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "geoHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "ancestors",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "lastCareTimestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careCount",
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
      "name": "getNFTsByUserPaginated",
      "inputs": [
        {
          "name": "user",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "offset",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "limit",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "trees",
          "type": "tuple[]",
          "internalType": "struct Tree[]",
          "components": [
            {
              "name": "id",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "latitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "longitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planting",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "death",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "species",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "imageUri",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "qrIpfsHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "metadata",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "photos",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "geoHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "ancestors",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "lastCareTimestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careCount",
              "type": "uint256",
              "internalType": "uint256"
            }
          ]
        },
        {
          "name": "totalCount",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getRecentTreesPaginated",
      "inputs": [
        {
          "name": "offset",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "limit",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "paginatedTrees",
          "type": "tuple[]",
          "internalType": "struct Tree[]",
          "components": [
            {
              "name": "id",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "latitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "longitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planting",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "death",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "species",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "imageUri",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "qrIpfsHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "metadata",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "photos",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "geoHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "ancestors",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "lastCareTimestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careCount",
              "type": "uint256",
              "internalType": "uint256"
            }
          ]
        },
        {
          "name": "totalCount",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "hasMore",
          "type": "bool",
          "internalType": "bool"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getTreeDetailsbyID",
      "inputs": [
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "tuple",
          "internalType": "struct Tree",
          "components": [
            {
              "name": "id",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "latitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "longitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planting",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "death",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "species",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "imageUri",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "qrIpfsHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "metadata",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "photos",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "geoHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "ancestors",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "lastCareTimestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careCount",
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
      "name": "getTreeNftVerifiers",
      "inputs": [
        {
          "name": "_tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "tuple[]",
          "internalType": "struct TreeNftVerification[]",
          "components": [
            {
              "name": "verifier",
              "type": "address",
              "internalType": "address"
            },
            {
              "name": "timestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "proofHashes",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "description",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "isHidden",
              "type": "bool",
              "internalType": "bool"
            },
            {
              "name": "treeNftId",
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
      "name": "getTreeNftVerifiersPaginated",
      "inputs": [
        {
          "name": "_tokenId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "offset",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "limit",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "verifications",
          "type": "tuple[]",
          "internalType": "struct TreeNftVerification[]",
          "components": [
            {
              "name": "verifier",
              "type": "address",
              "internalType": "address"
            },
            {
              "name": "timestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "proofHashes",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "description",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "isHidden",
              "type": "bool",
              "internalType": "bool"
            },
            {
              "name": "treeNftId",
              "type": "uint256",
              "internalType": "uint256"
            }
          ]
        },
        {
          "name": "totalCount",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "visiblecount",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getUserProfile",
      "inputs": [
        {
          "name": "userAddress",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "userDetails",
          "type": "tuple",
          "internalType": "struct UserDetails",
          "components": [
            {
              "name": "userAddress",
              "type": "address",
              "internalType": "address"
            },
            {
              "name": "profilePhotoIpfs",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "name",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "dateJoined",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "verificationsRevoked",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "reportedSpam",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "verifierTokens",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planterTokens",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "legacyTokens",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careTokens",
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
      "name": "getVerifiedTreesByUser",
      "inputs": [
        {
          "name": "verifier",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "tuple[]",
          "internalType": "struct Tree[]",
          "components": [
            {
              "name": "id",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "latitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "longitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planting",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "death",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "species",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "imageUri",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "qrIpfsHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "metadata",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "photos",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "geoHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "ancestors",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "lastCareTimestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careCount",
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
      "name": "getVerifiedTreesByUserPaginated",
      "inputs": [
        {
          "name": "verifier",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "offset",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "limit",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "trees",
          "type": "tuple[]",
          "internalType": "struct Tree[]",
          "components": [
            {
              "name": "id",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "latitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "longitude",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "planting",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "death",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "species",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "imageUri",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "qrIpfsHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "metadata",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "photos",
              "type": "string[]",
              "internalType": "string[]"
            },
            {
              "name": "geoHash",
              "type": "string",
              "internalType": "string"
            },
            {
              "name": "ancestors",
              "type": "address[]",
              "internalType": "address[]"
            },
            {
              "name": "lastCareTimestamp",
              "type": "uint256",
              "internalType": "uint256"
            },
            {
              "name": "careCount",
              "type": "uint256",
              "internalType": "uint256"
            }
          ]
        },
        {
          "name": "totalCount",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "isApprovedForAll",
      "inputs": [
        {
          "name": "owner",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "operator",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "bool",
          "internalType": "bool"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "isVerified",
      "inputs": [
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "verifier",
          "type": "address",
          "internalType": "address"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "bool",
          "internalType": "bool"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "legacyToken",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "contract LegacyToken"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "markDead",
      "inputs": [
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "minimumTimeToMarkTreeDead",
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
      "name": "mintNft",
      "inputs": [
        {
          "name": "latitude",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "longitude",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "species",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "imageUri",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "qrIpfsHash",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "metadata",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "geoHash",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "initialPhotos",
          "type": "string[]",
          "internalType": "string[]"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "name",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "string",
          "internalType": "string"
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
      "name": "ownerOf",
      "inputs": [
        {
          "name": "tokenId",
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
      "name": "ping",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "string",
          "internalType": "string"
        }
      ],
      "stateMutability": "pure"
    },
    {
      "type": "function",
      "name": "planterTokenContract",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "contract PlanterToken"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "registerUserProfile",
      "inputs": [
        {
          "name": "_name",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "_profilePhotoHash",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "removeVerification",
      "inputs": [
        {
          "name": "_verificationId",
          "type": "uint256",
          "internalType": "uint256"
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
      "name": "safeTransferFrom",
      "inputs": [
        {
          "name": "from",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "to",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "safeTransferFrom",
      "inputs": [
        {
          "name": "from",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "to",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "data",
          "type": "bytes",
          "internalType": "bytes"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "setApprovalForAll",
      "inputs": [
        {
          "name": "operator",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "approved",
          "type": "bool",
          "internalType": "bool"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "supportsInterface",
      "inputs": [
        {
          "name": "interfaceId",
          "type": "bytes4",
          "internalType": "bytes4"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "bool",
          "internalType": "bool"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "symbol",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "string",
          "internalType": "string"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "tokenURI",
      "inputs": [
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [
        {
          "name": "",
          "type": "string",
          "internalType": "string"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "transferFrom",
      "inputs": [
        {
          "name": "from",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "to",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
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
      "name": "updateUserDetails",
      "inputs": [
        {
          "name": "_name",
          "type": "string",
          "internalType": "string"
        },
        {
          "name": "_profilePhotoHash",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "verifierTokenContract",
      "inputs": [],
      "outputs": [
        {
          "name": "",
          "type": "address",
          "internalType": "contract VerifierToken"
        }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "verify",
      "inputs": [
        {
          "name": "_tokenId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "_proofHashes",
          "type": "string[]",
          "internalType": "string[]"
        },
        {
          "name": "_description",
          "type": "string",
          "internalType": "string"
        }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "event",
      "name": "Approval",
      "inputs": [
        {
          "name": "owner",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "approved",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "indexed": true,
          "internalType": "uint256"
        }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "ApprovalForAll",
      "inputs": [
        {
          "name": "owner",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "operator",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "approved",
          "type": "bool",
          "indexed": false,
          "internalType": "bool"
        }
      ],
      "anonymous": false
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
      "type": "event",
      "name": "Transfer",
      "inputs": [
        {
          "name": "from",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "to",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "indexed": true,
          "internalType": "uint256"
        }
      ],
      "anonymous": false
    },
    {
      "type": "event",
      "name": "VerificationRemoved",
      "inputs": [
        {
          "name": "verificationId",
          "type": "uint256",
          "indexed": true,
          "internalType": "uint256"
        },
        {
          "name": "treeNftId",
          "type": "uint256",
          "indexed": true,
          "internalType": "uint256"
        },
        {
          "name": "verifier",
          "type": "address",
          "indexed": true,
          "internalType": "address"
        }
      ],
      "anonymous": false
    },
    {
      "type": "error",
      "name": "ERC721IncorrectOwner",
      "inputs": [
        {
          "name": "sender",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        },
        {
          "name": "owner",
          "type": "address",
          "internalType": "address"
        }
      ]
    },
    {
      "type": "error",
      "name": "ERC721InsufficientApproval",
      "inputs": [
        {
          "name": "operator",
          "type": "address",
          "internalType": "address"
        },
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ]
    },
    {
      "type": "error",
      "name": "ERC721InvalidApprover",
      "inputs": [
        {
          "name": "approver",
          "type": "address",
          "internalType": "address"
        }
      ]
    },
    {
      "type": "error",
      "name": "ERC721InvalidOperator",
      "inputs": [
        {
          "name": "operator",
          "type": "address",
          "internalType": "address"
        }
      ]
    },
    {
      "type": "error",
      "name": "ERC721InvalidOwner",
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
      "name": "ERC721InvalidReceiver",
      "inputs": [
        {
          "name": "receiver",
          "type": "address",
          "internalType": "address"
        }
      ]
    },
    {
      "type": "error",
      "name": "ERC721InvalidSender",
      "inputs": [
        {
          "name": "sender",
          "type": "address",
          "internalType": "address"
        }
      ]
    },
    {
      "type": "error",
      "name": "ERC721NonexistentToken",
      "inputs": [
        {
          "name": "tokenId",
          "type": "uint256",
          "internalType": "uint256"
        }
      ]
    },
    {
      "type": "error",
      "name": "InvalidCoordinates",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidInput",
      "inputs": []
    },
    {
      "type": "error",
      "name": "InvalidTreeID",
      "inputs": []
    },
    {
      "type": "error",
      "name": "MinimumMarkDeadTimeNotReached",
      "inputs": []
    },
    {
      "type": "error",
      "name": "NotTreeOwner",
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
    },
    {
      "type": "error",
      "name": "PaginationLimitExceeded",
      "inputs": []
    },
    {
      "type": "error",
      "name": "TreeAlreadyDead",
      "inputs": []
    },
    {
      "type": "error",
      "name": "UserAlreadyRegistered",
      "inputs": []
    },
    {
      "type": "error",
      "name": "UserNotRegistered",
      "inputs": []
    }
  ]''';

const String TreeNFtContractAddress =
    "0xD0B9957663a7d6bA29638Ef3067d54f832E0f0ED";
