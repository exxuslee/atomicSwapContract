// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RSC_RevealWatcher is AbstractReactive {
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
    uint64 private constant CALLBACK_GAS_LIMIT = 3000000;

    // topic0 хэш события SwapReveal(bytes32,bytes32,bytes32)
    uint256 private constant SWAP_REVEAL = 0x8eeb5c6c938e6f7c75f7341e1bdb1e55a2848917eeb93b9cd6c128ef3142dc33;
    address private constant atomic_swap_contract = 0x6311ac6f9d2f2e931fc9e8117fcf820eb1861657;

    event SubscriptionStatus(bool success);

    constructor() {
        if (!vm) {
            try service.subscribe(
                SEPOLIA_CHAIN_ID,
                atomic_swap_contract,
                SWAP_REVEAL,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            ) {
                emit SubscriptionStatus(true);
            } catch {
                emit SubscriptionStatus(false);
            }
        }
    }

    function react(LogRecord calldata log) external override vmOnly {
        if (log.topic_0 == SWAP_REVEAL) {
            bytes memory payload_callback1 = abi.encodeWithSignature(
                "claimSwap(bytes32,bytes32)",
                log.topic_1,  // swapId
                log.topic_3   // secret
            );
            emit Callback(
                SEPOLIA_CHAIN_ID,
                atomic_swap_contract,
                CALLBACK_GAS_LIMIT,
                payload_callback1
            );
            bytes memory payload_callback2 = abi.encodeWithSignature(
                "claimSwap(bytes32,bytes32)",
                log.topic_2,  // chainSwapId
                log.topic_3   // secret
            );
            emit Callback(
                SEPOLIA_CHAIN_ID,
                atomic_swap_contract,
                CALLBACK_GAS_LIMIT,
                payload_callback2
            );
        }
    }
}