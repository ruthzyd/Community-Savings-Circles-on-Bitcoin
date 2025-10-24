# 💰 Community Savings Circles on Bitcoin

A decentralized savings circle (ROSCA) implementation on Stacks blockchain, enabling groups to pool funds and receive automated payouts based on a rotating schedule.

## 🌟 Overview

Community Savings Circles bring traditional rotating savings and credit associations (ROSCAs) to the blockchain. Members contribute equal amounts to a shared pool, and each member receives the full pool amount on their designated turn according to a predetermined rotation schedule.

## ✨ Features

- 🔄 **Automated Rotation**: Structured payout schedule based on block height
- 👥 **Group Management**: Create and join savings circles with defined parameters
- 💵 **Fixed Contributions**: Equal contribution amounts from all members
- ⏰ **Time-Locked Payouts**: Payouts release automatically based on block intervals
- 🔐 **Trustless Execution**: Smart contract ensures fair distribution
- 📊 **Transparent Tracking**: All contributions and payouts recorded on-chain

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd Community-Savings-Circles-on-Bitcoin
clarinet check
```

## 📖 Usage

### Creating a Savings Circle

The circle creator defines the parameters:

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin create-circle 
  u5          ;; max-members: 5 people
  u1000000    ;; contribution-amount: 1 STX per round
  u144        ;; payout-interval: ~1 day (144 blocks)
)
```

### Joining a Circle

Members can join before the circle activates:

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin join-circle u1)
```

### Activating the Circle

Once all positions are filled, the creator activates:

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin activate-circle u1)
```

### Contributing to the Pool

Each round, members contribute their share:

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin contribute u1)
```

### Claiming Your Payout

When it's your turn and the time arrives:

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin claim-payout u1)
```

## 🔍 Read-Only Functions

### Get Circle Information

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin get-circle u1)
```

Returns circle details including members, contribution amount, and status.

### Check Member Info

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin get-member-info u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### View Next Payout Block

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin get-next-payout-block u1)
```

### Check Circle Balance

```clarity
(contract-call? .Community-Savings-Circles-on-Bitcoin get-circle-balance u1)
```

## 🎯 How It Works

1. **Creation**: A circle creator sets the number of members, contribution amount, and payout interval
2. **Joining**: Members join and receive position numbers (0, 1, 2, etc.)
3. **Activation**: When full, the creator activates the circle
4. **Round 0**: All members contribute; member at position 0 claims the full pool
5. **Round 1**: All members contribute again; member at position 1 claims
6. **Continues**: Process repeats until all members have received their payout

## 📊 Example Scenario

**5-Member Circle with 1 STX contribution:**

- Member A (position 0): Contributes 1 STX, receives 5 STX in Round 0
- Member B (position 1): Contributes 1 STX, receives 5 STX in Round 1
- Member C (position 2): Contributes 1 STX, receives 5 STX in Round 2
- Member D (position 3): Contributes 1 STX, receives 5 STX in Round 3
- Member E (position 4): Contributes 1 STX, receives 5 STX in Round 4

Each member contributes 5 STX total and receives 5 STX back.

## 🛡️ Security Features

- Position-based payout validation
- Block-height time locks
- Contribution tracking per round
- Duplicate contribution prevention
- Membership verification

## ⚠️ Error Codes

- `u100`: Owner only operation
- `u101`: Circle not found
- `u102`: Already a member
- `u103`: Not a member
- `u104`: Circle full
- `u105`: Circle not active
- `u106`: Insufficient contribution
- `u107`: Already contributed this round
- `u108`: Not payout time yet
- `u109`: Already received payout
- `u110`: Circle already active
- `u111`: Invalid parameters
- `u112`: Payout failed

## 🧪 Testing

```bash
clarinet test
```

## 📝 License

MIT

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## 💡 Use Cases

- 🏘️ Community savings groups
- 👨‍👩‍👧‍👦 Family savings pools
- 🏢 Business credit circles
- 🌍 Cross-border savings groups
- 📚 Educational savings funds

---

Built with ❤️ on Stacks blockchain
