// SPDX-License-Identifier: MIT
//  https://kopli.reactscan.net/address/0x6f1c4b2bd0489e32af741c405cca696e8a95ce9c/contract/0x04ce0cbd9052f23bdfb977854b0fedcb591c9eff?screen=transactions
pragma solidity ^0.8.20;

import './lib/reactive-lib/src/abstract-base/AbstractReactive.sol';
import './lib/reactive-lib/src/interfaces/ISubscriptionService.sol';
import './lib/reactive-lib/src/interfaces/IReactive.sol';

contract RSC_RevealWatcher is AbstractReactive {
    uint64 private constant CALLBACK_GAS_LIMIT = 3000000;
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;

    // topic0 хэш события "SwapReveal(bytes32,uint256,address,bytes32,bytes32)"
    uint256 private constant SWAP_REVEAL = 0xdf62986a4c8d8da04625b7d3e3043285e8a4014d751a98d0b7748b5ae41ab345;
    address private constant atomic_swap_contract = 0x04cE0cBd9052f23Bdfb977854B0fEDcb591c9eFf;

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
            (bytes32 swapId, uint256 chainId, address chainContractAddress, bytes32 chainSwapId, bytes32 secret) = abi.decode(
                log.data, (bytes32, uint256, address, bytes32, bytes32));
            bytes memory payload_callback1 = abi.encodeWithSignature("claimSwap(address,bytes32,bytes32)",
                address(0), swapId, secret);
            emit Callback(
                log.chain_id,
                atomic_swap_contract,
                CALLBACK_GAS_LIMIT,
                payload_callback1
            );
            bytes memory payload_callback2 = abi.encodeWithSignature("claimSwap(address,bytes32,bytes32)",
                address(0), chainSwapId, secret);
            emit Callback(
                chainId,
                chainContractAddress,
                CALLBACK_GAS_LIMIT,
                payload_callback2
            );
        }
    }
}