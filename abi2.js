
export const ATOMIC_SWAP_ABI = [
  {
    inputs: [],
    stateMutability: 'nonpayable',
    type: 'constructor',
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: 'bytes32',
        name: 'swapId',
        type: 'bytes32',
      },
      {
        indexed: false,
        internalType: 'address payable',
        name: 'sender',
        type: 'address',
      },
      {
        indexed: false,
        internalType: 'address',
        name: 'recipient',
        type: 'address',
      },
      {
        indexed: false,
        internalType: 'address',
        name: 'tokenAddress',
        type: 'address',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
      {
        indexed: false,
        internalType: 'bytes32',
        name: 'hashLock',
        type: 'bytes32',
      },
      {
        indexed: false,
        internalType: 'uint256',
        name: 'expiration',
        type: 'uint256',
      },
    ],
    name: 'NewSwapInitiated',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: 'bytes32',
        name: 'swapId',
        type: 'bytes32',
      },
    ],
    name: 'SwapClaimed',
    type: 'event',
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: 'bytes32',
        name: 'swapId',
        type: 'bytes32',
      },
    ],
    name: 'SwapRefunded',
    type: 'event',
  },
  {
    inputs: [
      {
        internalType: 'bytes32',
        name: 'swapId',
        type: 'bytes32',
      },
      {
        internalType: 'bytes32',
        name: 'password',
        type: 'bytes32',
      },
    ],
    name: 'claimSwap',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'recipient',
        type: 'address',
      },
      {
        internalType: 'bytes32',
        name: 'hashLock',
        type: 'bytes32',
      },
      {
        internalType: 'uint256',
        name: 'expiration',
        type: 'uint256',
      },
      {
        internalType: 'address',
        name: 'tokenAddress',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
    ],
    name: 'initiateNewSwap',
    outputs: [
      {
        internalType: 'bytes32',
        name: 'swapId',
        type: 'bytes32',
      },
    ],
    stateMutability: 'payable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'bytes32',
        name: 'swapId',
        type: 'bytes32',
      },
    ],
    name: 'refundSwap',
    outputs: [
      {
        internalType: 'bool',
        name: '',
        type: 'bool',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'bytes32',
        name: '',
        type: 'bytes32',
      },
    ],
    name: 'swaps',
    outputs: [
      {
        internalType: 'address',
        name: 'recipient',
        type: 'address',
      },
      {
        internalType: 'address payable',
        name: 'sender',
        type: 'address',
      },
      {
        internalType: 'address',
        name: 'tokenAddress',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
      {
        internalType: 'uint256',
        name: 'expiration',
        type: 'uint256',
      },
      {
        internalType: 'bytes32',
        name: 'hashLock',
        type: 'bytes32',
      },
      {
        internalType: 'bool',
        name: 'refunded',
        type: 'bool',
      },
      {
        internalType: 'bool',
        name: 'claimed',
        type: 'bool',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
    ],
    name: 'widthdraw',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'address',
        name: 'tokenContract',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'amount',
        type: 'uint256',
      },
    ],
    name: 'withdrawToken',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
];