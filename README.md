# 🌐 CommInternet - Community-Owned Internet Infrastructure DAO

A decentralized autonomous organization (DAO) built on Stacks blockchain for funding and managing local, community-owned internet infrastructure.

## 🎯 Overview

CommInternet enables communities to collectively fund, vote on, and manage local internet infrastructure projects. Members contribute funds, participate in governance, and share in the network's profits through smart contract automation.

## ✨ Features

- 🏛️ **DAO Membership**: Join with STX stake, gain voting power proportional to contribution
- 📊 **Governance**: Create and vote on infrastructure proposals
- 💰 **Funding**: Pool community funds for infrastructure projects
- 🏗️ **Infrastructure Management**: Track and manage local internet projects
- 💸 **Profit Sharing**: Distribute network revenues to DAO members
- 🔒 **Smart Contract Security**: All operations secured by Clarity contracts

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- STX tokens for membership and operations

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/community-owned-internet-infrastructure.git
cd community-owned-internet-infrastructure
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
clarinet test
```

## 📖 Usage

### Joining the DAO

To become a member, call the `join-dao` function with a minimum stake:

```clarity
(contract-call? .CommInternet join-dao u100000000) ;; 1 STX minimum
```

### Creating Proposals

Members can create proposals for infrastructure funding:

```clarity
(contract-call? .CommInternet create-proposal 
  "Fiber Network Expansion"
  "Install fiber optic cables in downtown area"
  u500000000000  ;; 5000 STX
  'SP1PRINCIPAL... ;; recipient address
  "infrastructure")
```

### Voting on Proposals

Vote on active proposals with your voting power:

```clarity
(contract-call? .CommInternet vote-proposal u1 true) ;; Vote FOR proposal #1
```

### Managing Infrastructure

Add new infrastructure projects (owner only):

```clarity
(contract-call? .CommInternet add-infrastructure
  "Downtown District"
  "Fiber Optic Network"
  u500000000000
  'SP1MANAGER...)
```

### Claiming Profit Share

Members can claim their share of network profits:

```clarity
(contract-call? .CommInternet claim-profit-share)
```

## 🏗️ Smart Contract Architecture

### Core Functions

- **join-dao**: Become a DAO member with STX stake
- **leave-dao**: Leave DAO and receive partial refund
- **add-funds**: Increase your stake and voting power
- **create-proposal**: Submit funding proposals
- **vote-proposal**: Cast votes on active proposals
- **execute-proposal**: Execute approved proposals
- **add-infrastructure**: Add infrastructure projects
- **distribute-profits**: Add profits to distribution pool
- **claim-profit-share**: Claim your profit distribution

### Key Parameters

- **Minimum Membership Fee**: 1 STX (100,000,000 microSTX)
- **Voting Period**: 144 blocks (~24 hours)
- **Minimum Quorum**: 51% of total voting power

## 🔍 Read-Only Functions

Query contract state without transactions:

```clarity
;; Get member information
(contract-call? .CommInternet get-member-info 'SP1MEMBER...)

;; Get proposal details
(contract-call? .CommInternet get-proposal u1)

;; Get DAO statistics
(contract-call? .CommInternet get-dao-stats)

;; Check voting status
(contract-call? .CommInternet has-voted u1 'SP1VOTER...)
```

## 🛠️ Development

### Testing

Run the test suite:

```bash
clarinet test
```

### Deployment

Deploy to testnet:

```bash
clarinet deploy --testnet
```

Deploy to mainnet:

```bash
clarinet deploy --mainnet
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🌟 Roadmap

- [ ] Mobile app integration
- [ ] Multi-token support
- [ ] Advanced governance mechanisms
- [ ] Infrastructure performance metrics
- [ ] Integration with existing ISPs

## 💡 Support

For questions or support, please open an issue on GitHub or reach out to the community.

---

**Built with ❤️ for community-owned internet infrastructure**
