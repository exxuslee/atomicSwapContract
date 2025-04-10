// SPDX-License-Identifier: GPL-3.0
// https://sepolia.etherscan.io/address/0x6311ac6f9d2f2e931fc9e8117fcf820eb1861657

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './lib/reactive-lib/src/abstract-base/AbstractCallback.sol';

contract DextradeAtomicSwap is AbstractCallback {
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
        bool revealed;
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
    event SwapReveal(bytes32 swapId, uint256 chainId, address chainContractAddress, bytes32 chainSwapId, bytes32 secret);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier ensureOwner() {
        require(msg.sender == contractOwner, "Caller is not owner");
        _;
    }

    modifier ensureAllowance(address token, address owner, uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        if (token != address(0)) {
            require(IERC20(token).allowance(owner, address(this)) >= amount, "Allowance must be greater than 0");
        }
        _;
    }

    modifier ensureFutureExpiration(uint256 time) {
        require(time > block.timestamp, "Expiration time must be in the future");
        _;
    }

    modifier canClaim(bytes32 swapId) {
//        require(swaps[swapId].recipient == msg.sender, "Not the intended recipient");
        require(!swaps[swapId].claimed, "Already claimed");
        require(!swaps[swapId].refunded, "Already refunded");
        _;
    }

    modifier validHashLock(bytes32 swapId, bytes32 password) {
        require(swaps[swapId].hashLock == sha256(abi.encodePacked(password)), "Incorrect password");
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
        require(swaps[swapId].expiration <= block.timestamp, "Expiration time has not yet passed");
        _;
    }

    modifier canReveal(bytes32 swapId) {
        require(swaps[swapId].sender == msg.sender, "Only the sender can Reveal");
        require(!swaps[swapId].refunded, "Already refunded");
        require(!swaps[swapId].claimed, "Already claimed");
        require(!swaps[swapId].revealed, "Already revealed");
        require(swaps[swapId].expiration > block.timestamp, "Time refund it");
        _;
    }

    function initiateNewSwap(
        address recipient,
        bytes32 hashLock,
        uint256 expiration,
        address tokenAddress,
        uint256 amount
    )
    external
    payable
    ensureAllowance(tokenAddress, msg.sender, amount)
    returns (bytes32 swapId)
    {
        swapId = sha256(
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
            expiration: block.timestamp + expiration,
            hashLock: hashLock,
            refunded: false,
            claimed: false,
            revealed: false
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
            require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        }
    }

    function swapWithdraw(SwapDetails storage swap, address payable withdrawalAddress) private {
        if (swap.tokenAddress == address(0)) {
            withdrawalAddress.transfer(swap.amount);
        } else {
            IERC20(swap.tokenAddress).transfer(withdrawalAddress, swap.amount);
        }
    }

    function claimSwap(address /*spender*/, bytes32 swapId, bytes32 password)
    external
    canClaim(swapId)
    validHashLock(swapId, password)
    swapExists(swapId)
    returns (bool)
    {
        SwapDetails storage swap = swaps[swapId];
        swap.hashLock = password;
        swap.claimed = true;
        swap.revealed = true;
        swapWithdraw(swap, payable(swap.recipient));
        emit SwapClaimed(swapId);
        return true;
    }

    function revealSwap(bytes32 swapId, uint256 chainId, address chainContract, bytes32 chainSwapId, bytes32 password)
    external
    validHashLock(swapId, password)
    canReveal(swapId)
    swapExists(swapId)
    returns (bool)
    {
        SwapDetails storage swap = swaps[swapId];
        swap.hashLock = password;
        swap.revealed = true;
        emit SwapReveal(swapId, chainId, chainContract, chainSwapId, password);
        return true;
    }

    function claimSwapOwner(bytes32 swapId, bytes32 password, uint256 fee)
    external
//    ensureOwner
    canClaim(swapId)
    validHashLock(swapId, password)
    swapExists(swapId)
    returns (bool)
    {
        SwapDetails storage swap = swaps[swapId];
        require(fee > 0 && fee < swap.amount, "Invalid fee");
        swap.amount -= fee;
        swap.hashLock = password;
        swap.claimed = true;
        swap.revealed = true;
        swapWithdraw(swap, payable(swap.recipient));
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
        swapWithdraw(swap, swap.sender);
        emit SwapRefunded(swapId);
        return true;
    }

    function swapPresent(bytes32 swapId) internal view returns (bool) {
        return swaps[swapId].sender != address(0);
    }

    function withdraw(uint256 amount) external ensureOwner {
        payable(contractOwner).transfer(amount);
    }

    function withdrawToken(address tokenContract, uint256 amount) external ensureOwner {
        IERC20(tokenContract).transfer(msg.sender, amount);
    }
}
