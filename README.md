

# XSwapVault – Cross-Chain Atomic Swap Contract

`XSwapVault` is a secure, trust-minimized atomic swap smart contract written in [Clarity](https://docs.stacks.co/docs/clarity-language/overview/). It enables **cross-chain token swaps** (e.g., between Bitcoin, Ethereum, and Stacks) by leveraging **hash time-locked contracts (HTLCs)**. This contract is specifically designed to handle swaps of fungible tokens (FTs) on the Stacks blockchain, ensuring assets are only released when both parties fulfill their obligations.

---

## 📦 Features

* ✅ Cross-chain support for **Bitcoin**, **Ethereum**, and **Stacks**
* ✅ Uses **SHA-256 hash locks** for conditional swaps
* ✅ Time-bound swap expiration with **automatic refunds**
* ✅ Participant registration and preimage validation
* ✅ Robust validation for token contracts, blockchain names, wallet addresses, and amounts
* ✅ Strict error handling and constants for security

---

## 🛠 Functions Overview

### 💡 Read-only Functions

* `get-atomic-swap-details`

  * Returns all stored metadata about a given atomic swap.
* `verify-hash-preimage`

  * Verifies if the given preimage matches the stored hash lock.

---

### 🚀 Public Functions

#### `initialize-atomic-swap(...)`

Initiates a new atomic swap by:

* Locking tokens in the contract
* Storing swap metadata
* Setting an expiration block height

#### `register-swap-participant(...)`

Lets a user register as the participant of an existing swap.

* Allowed only once per swap
* Swap must still be active

#### `redeem-atomic-swap(...)`

Allows the registered participant to redeem tokens if:

* The correct hash preimage is provided
* Swap is still valid (not expired)
* Contract matches the one used in the initialization

#### `process-swap-refund(...)`

Allows the swap initiator to reclaim tokens if:

* The swap has expired
* The participant didn’t redeem in time

---

## ⚙️ Validation Mechanisms

Each function includes strict input validation to prevent misuse or errors:

* **Token Amount:** Must be greater than zero and below max `uint`
* **Swap Duration:** Must be within bounds (`1` to `1440` blocks)
* **Blockchain Name:** Only `"bitcoin"`, `"ethereum"`, or `"stacks"`
* **Wallet Address Prefix:** Must start with `0x`, `bc`, or `SP`
* **Hash Lock:** Cannot be all zeros and must be 32 bytes
* **Contract Interface:** Must follow the `ft-trait` standard

---

## 📁 Storage Structures

### `atomic-swaps` (Map)

Each swap is uniquely identified by a 32-byte hash and stores:

* Initiator & optional participant
* Token contract & amount
* Hash lock & expiration
* Destination blockchain + wallet
* Current status: `"active"`, `"participated"`, `"redeemed"`, `"refunded"`

### `atomic-swap-counter` (Variable)

A counter for generating unique swap identifiers.

---

## 🧪 Error Codes

| Code      | Meaning                    |
| --------- | -------------------------- |
| `err u1`  | Swap expired               |
| `err u2`  | Swap not found             |
| `err u3`  | Unauthorized access        |
| `err u4`  | Swap already finalized     |
| `err u5`  | Invalid token amount       |
| `err u6`  | Insufficient token balance |
| `err u7`  | Invalid contract           |
| `err u8`  | Invalid hash               |
| `err u9`  | Invalid blockchain         |
| `err u10` | Invalid address            |

---

## 🔐 Security Notes

* Tokens are **escrowed** in the contract during swap initialization.
* Redemption requires the **correct preimage**, ensuring atomicity.
* Refunds are **only allowed after expiration**, protecting the initiator.
* Only the **swap creator** can trigger a refund, and only if conditions are met.

---
