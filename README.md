# SKeeper

**Token custodian with role-based access and [EIP-1271](https://eips.ethereum.org/EIPS/eip-1271) signature validator**

## Overview

`skeeper` is a Solidity smart contract and Python toolkit for secure DeFi operations that require signature verification and token custody logic.

It enables:

- **EIP-1271** on-chain signature validation
- **Role-based access control** using OpenZeppelin
- **ERC-20 approvals and withdrawals**
- **External signer management** via admin roles
- Python signature composition for signing messages off-chain

## Use case

`skeeper` is designed for Liquidity Providers and Makers participating in Intent-Based Protocols, where off-chain signatures are used to authorize on-chain actions such as quotes, trade intents, or liquidity offers.

It acts as a secure on-chain vault that:

- Holds ERC-20 funds under controlled roles
- Verifies EIP-1271 signatures for quote execution
- Supports role-based approvals and withdrawals

Currently compatible with [Liquorice](https://liquorice.gitbook.io/liquorice-docs/intro/general-flow).
Planned integrations include Bebop, CoW Swap, 1inch Fusion, and UniswapX.

## License

[MIT](LICENSE)