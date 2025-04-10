// SPDX-License-Identifier: MIT
//  https://kopli.reactscan.net/address/0x6f1c4b2bd0489e32af741c405cca696e8a95ce9c/contract/0xa19f4f9459f643520aa92fcfc3cd35f193f311dc
pragma solidity ^0.8.20;

contract RSC_RevealWatcher is AbstractReactive {
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
    uint64 private constant CALLBACK_GAS_LIMIT = 3000000;

    // topic0 хэш события SwapReveal(bytes32,bytes32,bytes32)
    uint256 private constant SWAP_REVEAL = 0xcf2635b4c441ce5b39d1153854964d581f4c7ce76b379d7e283bd88431ca7b2e;
    address private constant atomic_swap_contract = 0x6311AC6F9d2f2E931fC9e8117fCF820eb1861657;

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
            (bytes32 swapId, bytes32 chainSwapId, bytes32 secret) = abi.decode(log.data, (bytes32, bytes32, bytes32));
            bytes memory payload_callback1 = abi.encodeWithSignature(
                "claimSwap(bytes32,bytes32)",
                swapId,
                secret
            );
            emit Callback(
                SEPOLIA_CHAIN_ID,
                atomic_swap_contract,
                CALLBACK_GAS_LIMIT,
                payload_callback1
            );
            bytes memory payload_callback2 = abi.encodeWithSignature(
                "claimSwap(bytes32,bytes32)",
                log.chainSwapId,
                secret
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