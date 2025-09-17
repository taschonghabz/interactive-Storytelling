# 📚 Interactive Storytelling Smart Contract

A Clarity smart contract that enables token-based voting on plot directions for web series and animations. Token holders can influence story outcomes through democratic voting mechanisms.

## 🌟 Features

- 🎭 **Story Creation**: Create and manage interactive stories
- 🗳️ **Token-Based Voting**: Vote on plot directions using story tokens
- 📖 **Chapter Management**: Track story progression and chapter content
- 🏆 **Winning Outcomes**: Automatically execute winning plot decisions
- 💰 **Token Economy**: Fungible tokens for voting power
- 🔄 **Refund System**: Winners get tokens back, losers contribute to story pool

## 🚀 Quick Start

### Prerequisites
- Clarinet CLI installed
- Stacks wallet or testing environment

### Deploy Contract
```bash
clarinet deploy
```

## 📋 Core Functions

### 🎯 Story Management

**Create Story**
```clarity
(contract-call? .interactive-storytelling create-story "My Epic Adventure")
```

**Add Chapter Content**
```clarity
(contract-call? .interactive-storytelling add-chapter-content u1 u1 "The hero stands at a crossroads...")
```

### 🗳️ Voting System

**Create Plot Vote**
```clarity
(contract-call? .interactive-storytelling create-plot-vote 
  u1 u1 
  "Go left through the forest"
  "Go right to the mountain"
  "Stay and make camp"
  u1440) ;; 1440 blocks ≈ 1 week
```

**Vote on Plot Direction**
```clarity
(contract-call? .interactive-storytelling vote-on-plot u1 u1 u100) ;; Vote option 1 with 100 tokens
```

**Execute Vote Results**
```clarity
(contract-call? .interactive-storytelling execute-vote-result u1)
```

### 💎 Token Management

**Initialize Tokens** (Owner only)
```clarity
(contract-call? .interactive-storytelling initialize-tokens u1000000)
```

**Transfer Tokens**
```clarity
(contract-call? .interactive-storytelling transfer-tokens u500 'SP1ABCD...)
```

**Claim Vote Refund** (Winners only)
```clarity
(contract-call? .interactive-storytelling claim-vote-refund u1)
```

## 🔍 Read-Only Functions

### Get Story Information
```clarity
(contract-call? .interactive-storytelling get-story u1)
```

### Check Vote Results
```clarity
(contract-call? .interactive-storytelling get-vote-results u1)
```

### View Token Balance
```clarity
(contract-call? .interactive-storytelling get-token-balance tx-sender)
```

### Check Voting Status
```clarity
(contract-call? .interactive-storytelling is-voting-active u1)
```

## 🏗️ Contract Structure

### Data Maps
- **stories**: Story metadata and status
- **plot-votes**: Voting sessions with options and results
- **user-votes**: Individual user voting records
- **user-token-balance**: Token balances for each user
- **story-chapters**: Chapter content and choices

### Key Constants
- **Voting Options**: 1, 2, 3 (corresponding to option A, B, C)
- **Token Supply**: 1,000,000 initial tokens
- **Voting Duration**: Set per vote (in blocks)

## 🎮 Usage Example

1. **Story Creator** deploys contract and creates a story
2. **Token Distribution** to community members
3. **Chapter Creation** with plot decision points
4. **Community Voting** on story directions using tokens
5. **Result Execution** implements winning choice
6. **Story Progression** continues with new chapters

## ⚡ Voting Mechanics

- **Token Weight**: More tokens = more voting power
- **One Vote Per User**: Per voting session
- **Time Limits**: Voting ends after specified block duration
- **Winner Takes All**: Winning voters get tokens refunded
- **Automatic Execution**: Results applied to story progression

## 🛡️ Security Features

- Owner-only story management functions
- Vote timing validation
- Double-voting prevention
- Token balance verification
- Execution state tracking

## 📊 Monitoring

Track your interactive stories with:
- Total story count
- Active voting sessions
- Token distribution
- Chapter progression
- Community participation

## 🤝 Contributing

This contract enables decentralized storytelling governance. Feel free to extend functionality for your specific use case!

## 📄 License

Built for the Stacks ecosystem. Use responsibly and have fun creating interactive stories! 🎨✨
