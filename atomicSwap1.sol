// SPDX-License-Identifier: GPL-3.0
// https://bscscan.com/address/0x0de4942c02125f1b6af0d49e20b2aea4823c0ace#events

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DextradeAtomicSwap {
    address private contractOwner;

    struct SwapDetails {
        address recipient;
        address payable sender;
        address tokenAddress;
        uint256 amount;
        uint256 expiration;
        bytes32 hashLock;
        bool refunded;
        bool claimed;
    }

    mapping(address => mapping(address => uint256)) private allowances;
    mapping(bytes32 => SwapDetails) public swaps;

    event NewSwapInitiated(
        bytes32 swapId,
        address payable sender,
        address recipient,
        address tokenAddress,
        uint256 amount,
        bytes32 hashLock,
        uint256 expiration
    );
    event SwapClaimed(bytes32 swapId);
    event SwapRefunded(bytes32 swapId);

    constructor() {
        contractOwner = msg.sender;
    }

// modifier to check if caller is owner
    modifier ensureOwner() {
        require(msg.sender == contractOwner, "Caller is not owner");
        _;
    }

    modifier ensureAllowance(address token, address owner, uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        if (token != address(0)) {
            require(ERC20(token).allowance(owner, address(this)) >= amount, "Allowance must be greater than 0");
        }
        _;
    }

    modifier ensureFutureExpiration(uint256 time) {
        require(time > block.timestamp, "Expiration time must be in the future");
        _;
    }

    modifier canClaim(bytes32 swapId) {
        require(swaps[swapId].recipient == msg.sender, "Not the intended recipient");
        require(!swaps[swapId].claimed, "Already claimed");
        require(!swaps[swapId].refunded, "Already refunded");
        _;
    }

    modifier validHashLock(bytes32 swapId, bytes32 hashLock) {
        require(swaps[swapId].hashLock == keccak256(abi.encodePacked(hashLock)), "Incorrect hash lock");
        _;
    }

    modifier swapExists(bytes32 swapId) {
        require(swapPresent(swapId), "Swap does not exist");
        _;
    }

    modifier canRefund(bytes32 swapId) {
        require(swaps[swapId].sender == msg.sender, "Only the sender can refund");
        require(!swaps[swapId].refunded, "Already refunded");
        require(!swaps[swapId].claimed, "Already claimed");
        require(swaps[swapId].expiration <= /* block.timestamp */ block.number, "Expiration time has not yet passed");
        _;
    }

    function initiateNewSwap(
        address recipient,
        bytes32 hashLock,
        uint256 expiration,
        address tokenAddress,
        uint256 amount
    )
    public
    payable
    ensureAllowance(tokenAddress, msg.sender, amount)
    returns (bytes32 swapId)
    {
        swapId = keccak256(
            abi.encodePacked(
                msg.sender,
                recipient,
                tokenAddress,
                amount,
                hashLock,
                expiration
            )
        );

        if (swapPresent(swapId)) {
            revert("Swap already exists");
        }

        reserve(amount, tokenAddress);

        swaps[swapId] = SwapDetails({
            recipient: recipient,
            sender: payable(msg.sender),
            tokenAddress: tokenAddress,
            amount: amount,
            expiration: /* block.timestamp + */ expiration,
            hashLock: hashLock,
            refunded: false,
            claimed: false
        });

        emit NewSwapInitiated(
            swapId,
            payable(msg.sender),
            recipient,
            tokenAddress,
            amount,
            hashLock,
            expiration
        );
    }


    function reserve(uint256 amount, address tokenAddress) private {
        if (tokenAddress == address(0)) {
            require(amount == msg.value, "Amount must match with value");
        } else {
            require(ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        }
    }

    function swapWidthdraw(SwapDetails storage swap, address payable widthdrawalAddress) private {
        if (swap.tokenAddress == address(0)) {
            widthdrawalAddress.transfer(swap.amount);
        } else {
            ERC20(swap.tokenAddress).transfer(widthdrawalAddress, swap.amount);
        }
    }


    function claimSwap(bytes32 swapId, bytes32 hashLock)
    public
    payable
    canClaim(swapId)
    validHashLock(swapId, hashLock)
    swapExists(swapId)
    returns (bool)
    {
        SwapDetails storage swap = swaps[swapId];
        swap.hashLock = hashLock;
        swap.claimed = true;
        swapWidthdraw(swap, payable(swap.recipient));
        emit SwapClaimed(swapId);
        return true;
    }

    function refundSwap(bytes32 swapId)
    external
    swapExists(swapId)
    canRefund(swapId)
    returns (bool)
    {
        SwapDetails storage swap = swaps[swapId];
        swap.refunded = true;
        swapWidthdraw(swap, swap.sender);
        emit SwapRefunded(swapId);
        return true;
    }

    function swapPresent(bytes32 swapId) internal view returns (bool) {
        return swaps[swapId].sender != address(0);
    }

    function widthdraw(uint256 amount) external ensureOwner {
        payable(contractOwner).transfer(amount);
    }

    function withdrawToken(address tokenContract, uint256 amount) external ensureOwner {
        ERC20(tokenContract).transfer(msg.sender, amount);
    }
}

