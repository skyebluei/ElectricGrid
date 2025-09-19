# ElectricGrid Smart Contract

**ElectricGrid** is a synthetic assets smart contract built on the Stacks blockchain that provides exposure to smart grid and energy storage infrastructure. The contract enables users to participate in decentralized energy markets through tokenized grid capacity and energy storage systems.

## Features

- **Grid Node Management**: Create and manage decentralized grid nodes with configurable capacity and efficiency ratings
- **Energy Storage Systems**: Deploy various types of energy storage facilities (battery, pumped-hydro, compressed-air)
- **Dual Token System**:
  - **Grid Tokens**: Represent grid infrastructure capacity
  - **Energy Tokens**: Represent stored energy units
- **Dynamic Trading**: Convert between grid tokens and energy tokens based on market pricing
- **Efficiency-Based Rewards**: Token minting based on capacity and efficiency ratings
- **Ownership Controls**: Full ownership management for grid nodes and storage facilities
- **Administrative Controls**: Contract pause/unpause and price adjustment capabilities

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

### Token Standards
- **Grid Token**: Fungible token representing grid infrastructure capacity
- **Energy Token**: Fungible token representing stored energy units

### Capacity Limits
- **Minimum Grid Capacity**: 1,000 units
- **Maximum Grid Capacity**: 1,000,000 units
- **Base Energy Rate**: 100 microSTX per MWh

## Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm (for testing)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd ElectricGrid
```

2. Navigate to the contract directory:
```bash
cd ElectricGrid_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Creating a Grid Node

```clarity
;; Create a grid node with 50,000 capacity, 85% efficiency in New York
(contract-call? .ElectricGrid create-grid-node u50000 u85 "New York")
```

### Creating Energy Storage

```clarity
;; Create a battery storage facility with 25,000 capacity and 90% efficiency
(contract-call? .ElectricGrid create-energy-storage u25000 "battery" u90)
```

### Storing Energy

```clarity
;; Store 1,000 units of energy in storage facility ID 1
(contract-call? .ElectricGrid store-energy u1 u1000)
```

### Trading Tokens

```clarity
;; Trade 5,000 grid tokens for energy tokens
(contract-call? .ElectricGrid trade-grid-for-energy u5000)
```

## Contract Functions Documentation

### Public Functions

#### Grid Management
- **`create-grid-node(capacity, efficiency-rating, location)`**
  - Creates a new grid node with specified parameters
  - Mints grid tokens based on capacity
  - Returns node ID

- **`update-node-status(node-id, is-active)`**
  - Updates the active status of a grid node
  - Only callable by node owner

#### Energy Storage
- **`create-energy-storage(capacity, storage-type, efficiency)`**
  - Creates an energy storage facility
  - Supports: "battery", "pumped-hydro", "compressed-air"
  - Mints energy tokens based on capacity and efficiency

- **`store-energy(storage-id, amount)`**
  - Stores energy in a storage facility
  - Accounts for efficiency losses
  - Mints energy tokens for stored energy

- **`release-energy(storage-id, amount)`**
  - Releases energy from storage
  - Burns corresponding energy tokens

#### Trading
- **`trade-grid-for-energy(grid-amount)`**
  - Converts grid tokens to energy tokens
  - Uses current energy price rate

#### Administrative
- **`update-energy-price(new-price)`** (Owner only)
  - Updates the energy price per MWh

- **`set-contract-pause(paused)`** (Owner only)
  - Pauses or unpauses contract operations

### Read-Only Functions

- **`get-grid-node(node-id)`** - Retrieve grid node information
- **`get-energy-storage(storage-id)`** - Retrieve storage facility information
- **`get-user-balance(user)`** - Get user's token balances
- **`get-total-grid-capacity()`** - Get total grid capacity
- **`get-total-energy-stored()`** - Get total stored energy
- **`get-energy-price()`** - Get current energy price
- **`get-contract-status()`** - Get contract status and metrics
- **`calculate-grid-efficiency(node-id)`** - Calculate node efficiency
- **`get-storage-utilization(storage-id)`** - Get storage utilization percentage

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --mainnet
```

## Security Notes

### Access Controls
- **Contract Owner**: Can update energy prices and pause/unpause the contract
- **Node/Storage Owners**: Can only modify their own assets
- **Public Functions**: All core functionality is publicly accessible

### Error Handling
The contract implements comprehensive error handling with specific error codes:
- `u100`: Owner-only function called by non-owner
- `u101`: Resource not found
- `u102`: Insufficient funds
- `u103`: Invalid amount
- `u104`: Resource already exists
- `u105`: Unauthorized access
- `u999`: Contract is paused

### Data Validation
- Capacity limits enforced for grid nodes
- Efficiency ratings capped at 100%
- Storage type validation for supported types
- Ownership verification for all modifications

### Best Practices
- Always check function return values
- Verify ownership before calling modification functions
- Monitor contract status before executing transactions
- Use appropriate error handling in client applications

## Testing

Run the test suite:
```bash
npm test
```

Run tests with coverage and cost analysis:
```bash
npm run test:report
```

Watch mode for development:
```bash
npm run test:watch
```

## License

ISC License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

---

**Note**: This smart contract is designed for educational and experimental purposes. Conduct thorough testing and security audits before deploying to mainnet.