# Google Summer of Code 2025 Final Project Report

## Student Information
**Name:** Aaryan Jain  
**GitHub:** [IronJam11](https://github.com/IronJam11)  
**LinkedIn:** [Aaryan Jain](https://www.linkedin.com/in/aaryan-jain-02b44827a/)  
**Organization:** Australian Open Source Software Innovation and Education (AOSSIE) | Stability Nexus  
**Project:** Tree Planting Protocol - Decentralized Tree Verification Platform



## Abstract

During GSOC 2025, I developed the **Tree Planting Protocol**, a blockchain-based platform for verifiable tree planting and environmental conservation. The platform enables users to mint tree NFTs with geographic verification, create decentralized organizations for collaborative verification, and participate in multi-owner governance systems. The primary technical challenge involved integrating MetaMask wallet connectivity in Flutter—a complex implementation I documented in my [Medium article](https://medium.com/@aaryanjain888/how-i-stopped-worrying-and-learned-to-connect-metamask-to-my-flutter-app-with-walletconnect-a916f77d8cdf).



## Technologies Used

**Frontend:** Flutter, Provider (State Management), Go Router (Navigation)  
**Wallet Integration:** WalletConnect Flutter V2, MetaMask  
**Smart Contracts:** Solidity, Foundry, OpenZeppelin  
**Blockchain:** Ethereum (Mainnet & Sepolia Testnet)  
**Storage:** IPFS (Pinata), Shared Preferences  
**Location Services:** Geolocator, Flutter Map, OpenStreetMap  
**Testing:** Foundry Test Suite  
**CI/CD:** GitHub Actions



## Repositories and other resources 

**Frontend:** [Treee Repository](https://github.com/StabilityNexus/Treee)  
**Smart Contracts:** [Smart Contracts Repository](https://github.com/StabilityNexus/Treee-Solidity)  
**Demo Video:** [Demo Video]()  
**Figma:** [Screen Prototypes](https://www.figma.com/design/OScwToy77aIsgG7S3PBGZB/Tree-Planting-Protocol?node-id=0-1&t=iCNy2XfFIUdkQIai-1)



## Project Description

The Tree Planting Protocol is a decentralized platform that combines blockchain technology with geographic verification to create an immutable record of tree planting efforts. The project consists of three main components:

**Smart Contracts:** Developed using Solidity and Foundry, managing NFT minting, multi-owner organization governance, and democratic verification voting systems.

**Flutter Frontend:** Cross-platform application (Android, iOS, macOS, Linux, Windows, Web) featuring wallet integration, interactive maps, and IPFS storage.

**Decentralized Storage:** IPFS integration via Pinata for storing tree images, verification proofs, and organization metadata. (Looking for better ways to handle decentralised Storage in the future)

The platform supports multiple user types:

- **Tree Planters:** Create tree NFTs with GPS coordinates, species information, and photographic evidence
- **Organization Owners:** Create and manage verification organizations with multi-owner governance
- **Verifiers:** Join organizations, submit verification requests, and vote on tree authenticity
- **Community Members:** View tree portfolios, track environmental impact, and monitor verification status

---

## Key Features

- **Multi-Chain Wallet Integration:** WalletConnect V2 implementation supporting MetaMask
- **Geographic NFT Minting:** Location-based tree registration with geohash encoding and interactive map selection
- **IPFS Storage:** Decentralized image storage for tree photos and verification proofs
- **Organization Governance:** Multi-owner organizations with democratic voting mechanisms
- **Verification System:** Majority-vote based tree verification with on-chain proof storage
- **User Profiles:** Token-based reputation system (Planter, Care, Verifier, Legacy tokens)
- **Comprehensive Theme System:** Light/dark mode support with consistent design language
- **CI/CD Pipeline:** Automated testing, formatting, and build verification

---

## Major Pull Requests

### Frontend Development (Treee Repository)

**[PR #4](https://github.com/StabilityNexus/Treee/pull/4): Complete Architecture Overhaul & Wallet Integration**  
Established foundational architecture with WalletConnect V2. Implemented multi-wallet support, deep linking, multi-chain switching, and Provider-based state management across six platforms.

**[PR #5](https://github.com/StabilityNexus/Treee/pull/5): End-to-End NFT Minting & Location Services**  
Built four-step minting workflow with GPS capture, metadata entry, IPFS upload, and blockchain submission. Integrated maps and smart contract pagination.

**[PR #6](https://github.com/StabilityNexus/Treee/pull/6): Upload Workflow Optimization**  
Streamlined image uploads by enabling direct IPFS integration, reducing memory usage and improving reliability.

**[PR #9](https://github.com/StabilityNexus/Treee/pull/9): User Profile & NFT Portfolio**  
Created user registration with on-chain storage, token displays, and paginated NFT portfolio with interactive tree details.

**[PR #11](https://github.com/StabilityNexus/Treee/pull/11): CI/CD Pipeline & Quality Assurance**  
Established GitHub Actions with Flutter analyze, format checking, and multi-platform builds.

**[PR #13](https://github.com/StabilityNexus/Treee/pull/13): Advanced NFT Details & Verification**  
Built comprehensive tree details with verification management, proof uploads, and paginated verifier lists.

**[PR #15](https://github.com/StabilityNexus/Treee/pull/15): Comprehensive Theme System**  
Implemented centralized light/dark mode theming and configured Android deep linking for wallet integration.

**[PR #16](https://github.com/StabilityNexus/Treee/pull/16): Organization Management System**  
Created organization creation with IPFS logo uploads, member management, and domain-separated contract functions.

### Smart Contract Development (Treee-Solidity Repository)

Here are concise, accurate summaries for all PRs based on the actual GitHub content:

**[PR #4](https://github.com/StabilityNexus/Treee-Solidity/pull/4): Organisation & OrganisationFactory Contracts**
Developed multi-owner governance, join/verification request systems with majority-vote mechanisms, and comprehensive testing with gas optimizations.

**[PR #6](https://github.com/StabilityNexus/Treee-Solidity/pull/6): TreeNFT & Token Integration**
Added TreeNFT and ERC20 token contracts with voting, rewards, and metadata logic. Enhanced modularity, access control, and test coverage.

**[PR #9](https://github.com/StabilityNexus/Treee-Solidity/pull/9): Deployment Scripts**
Introduced Foundry scripts for seamless multi-contract deployment and environment configuration, improving reproducibility and CI integration.

**[PR #10](https://github.com/StabilityNexus/Treee-Solidity/pull/10): Contract Refinements**
Optimized code structure, reduced gas usage, and improved inter-contract coordination with minor logic fixes and cleaner abstractions.

**[PR #11](https://github.com/StabilityNexus/Treee-Solidity/pull/11): Function Paginations & Final Updates**
Implemented pagination across organisation, member, and proposal views; improved role management and verification syncing; finalized testing and documentation.

## Challenges and Solutions

### Challenge 1: Flutter-MetaMask Integration
Connecting MetaMask to Flutter presented significant technical challenges due to limited documentation and platform-specific requirements.

**Solution:** Implemented WalletConnect V2 with custom deep linking, platform-specific intent filters, robust connection state management, and documented the process in a [Medium article](https://medium.com/@aaryanjain888/how-i-stopped-worrying-and-learned-to-connect-metamask-to-my-flutter-app-with-walletconnect-a916f77d8cdf).

### Challenge 2: Multi-Owner Voting Mechanism
Designing a secure voting system for organization-based verification required careful consideration of edge cases and attack vectors.

**Solution:** Implemented majority-threshold voting (>50% approval), double-vote prevention, self-voting restrictions, last-owner protection, and comprehensive test coverage.

### Challenge 3: Cross-Platform Consistency
Maintaining consistent UI/UX across six platforms while handling platform-specific requirements.

**Solution:** Created centralized theme system, reusable base components, platform-specific configurations, and responsive layouts.


## Future Plans

- Add support for additional blockchain networks (Polygon, Arbitrum, etc)
- Deploy it on play store
- Make it multi-chain by the use of CCIP 
- Add QR code generation for physical tree tags

---

## Acknowledgements

I express my sincere gratitude to my mentors **Dr. Bruno Woltzenlogel Paleo** and **Bhavik Mangla** at AOSSIE, who provided invaluable guidance, technical expertise, and continuous support throughout my GSoC journey. Their feedback was instrumental in shaping both the technical architecture and user experience of the Tree Planting Protocol.

Thank you.