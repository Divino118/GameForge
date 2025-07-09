# GameForge Smart Contract

## Overview

GameForge is a Clarity smart contract designed for gaming currency exchange on the Stacks blockchain. It provides a decentralized platform for gamers to manage gaming coins, exchange currencies, and maintain player profiles within a secure and regulated environment.

## Features

### Core Functionality
- **Player Profile Management**: Create and manage gamer profiles with unique tags and IDs
- **Gaming Coin Wallet**: Load, store, and manage gaming coins
- **Currency Exchange**: Exchange gaming coins between players with configurable fees
- **Coin Withdrawal**: Withdraw gaming coins back to STX
- **Maintenance Mode**: Emergency system shutdown capability

### Administrative Features
- **Rate Management**: Configurable conversion rates managed by authorized moderators
- **Fee Management**: Adjustable exchange fees (basis points)
- **Moderator Management**: Add/remove rate moderators
- **Emergency Controls**: Maintenance mode for system updates

## Contract Constants

### Error Codes
- `u100`: Access violation
- `u101`: Gamer not registered
- `u102`: Insufficient game coins
- `u103`: Invalid coin amount
- `u104`: Coin exchange failed
- `u105`: Operation not allowed
- `u106`: Invalid conversion rate
- `u107`: Gamer already registered
- `u108`: Invalid player data
- `u109`: Exchange maintenance

### Default Settings
- **Exchange Fee**: 1.5% (150 basis points)
- **Maintenance Mode**: Disabled by default
- **Conversion Rate**: 0 (must be set by moderators)

## Data Structures

### Player Profile
```clarity
{
  gamer-tag: (string-ascii 55),    // Display name (1-55 characters)
  player-id: (string-ascii 22)     // Unique identifier (1-22 characters)
}
```

### Storage Maps
- `gaming-coin-wallets`: Maps player addresses to coin balances
- `player-profiles`: Maps player addresses to profile data
- `rate-moderators`: Maps addresses to moderator status

## Public Functions

### Player Functions

#### `create-player-profile`
```clarity
(create-player-profile (gamer-tag (string-ascii 55)) (player-id (string-ascii 22)))
```
Creates a new player profile. Both gamer tag and player ID must be unique and within length limits.

**Requirements:**
- Player must not already have a profile
- Gamer tag: 1-55 characters
- Player ID: 1-22 characters

#### `load-gaming-coins`
```clarity
(load-gaming-coins (amount uint))
```
Adds gaming coins to the sender's wallet balance.

**Requirements:**
- Amount must be greater than 0

#### `exchange-coins`
```clarity
(exchange-coins (recipient principal) (amount uint))
```
Exchanges gaming coins between players with fee deduction.

**Requirements:**
- System not in maintenance mode
- Both sender and recipient must have registered profiles
- Sender must have sufficient balance (amount + fees)
- Valid conversion rate must be set

#### `withdraw-gaming-coins`
```clarity
(withdraw-gaming-coins (amount uint))
```
Withdraws gaming coins from the player's wallet.

**Requirements:**
- Sufficient balance in gaming coin wallet
- Amount must be positive

### Moderator Functions

#### `update-conversion-rate`
```clarity
(update-conversion-rate (new-rate uint))
```
Updates the coin conversion rate.

**Requirements:**
- Caller must be an authorized rate moderator
- New rate must be greater than 0

### Administrative Functions

#### `set-maintenance-mode`
```clarity
(set-maintenance-mode (maintenance-status bool))
```
Enables or disables maintenance mode.

**Requirements:**
- Caller must be the platform master

#### `update-exchange-fee`
```clarity
(update-exchange-fee (new-fee-basis-points uint))
```
Updates the exchange fee percentage.

**Requirements:**
- Caller must be the platform master
- Fee cannot exceed 100% (10,000 basis points)

#### `add-rate-moderator`
```clarity
(add-rate-moderator (gamer principal))
```
Grants rate moderator privileges to an address.

**Requirements:**
- Caller must be the platform master
- Address must not already be a moderator

#### `remove-rate-moderator`
```clarity
(remove-rate-moderator (gamer principal))
```
Revokes rate moderator privileges from an address.

**Requirements:**
- Caller must be the platform master
- Address must be an existing moderator

## Read-Only Functions

### `get-coin-wallet-balance`
```clarity
(get-coin-wallet-balance (gamer principal))
```
Returns the gaming coin balance for a specific player.

### `get-player-profile`
```clarity
(get-player-profile (gamer principal))
```
Returns the player profile information for a specific address.

### `get-current-conversion-rate`
```clarity
(get-current-conversion-rate)
```
Returns the current coin conversion rate.

### `is-rate-moderator`
```clarity
(is-rate-moderator (gamer principal))
```
Checks if an address has rate moderator privileges.

### `is-exchange-in-maintenance`
```clarity
(is-exchange-in-maintenance)
```
Returns the current maintenance mode status.

## Security Features

- **Access Control**: Platform master controls critical functions
- **Profile Validation**: Enforced character limits and uniqueness
- **Balance Verification**: Prevents overdraft and negative balances
- **Emergency Shutdown**: Maintenance mode for system updates
- **Fee Protection**: Maximum fee cap to prevent exploitation

## Usage Examples

### Setting Up a Player
```clarity
;; Create player profile
(contract-call? .gameforge create-player-profile "PlayerOne" "P001")

;; Load gaming coins
(contract-call? .gameforge load-gaming-coins u1000)
```

### Exchanging Coins
```clarity
;; Exchange 100 coins with another player
(contract-call? .gameforge exchange-coins 'ST1PLAYER2ADDRESS u100)
```

### Administrative Setup
```clarity
;; Add a rate moderator
(contract-call? .gameforge add-rate-moderator 'ST1MODERATORADDRESS)

;; Set conversion rate
(contract-call? .gameforge update-conversion-rate u50000000)
```

## Deployment Notes

1. Deploy the contract to the Stacks blockchain
2. The deployer becomes the platform master
3. Set initial conversion rate via rate moderator
4. Configure exchange fees as needed
5. Add trusted rate moderators

