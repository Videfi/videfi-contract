## Videfi contract
This project is submitted in ETH Global Hack FS 2023 Hackathon. We are pround to present Videfi, a web3.0 content platform. 

In this repository, we have 3 main smart contracts, including
1. VidefiContent - a main smart contract for generating content NFT and assign viewer access conditions. The access control relies on token gated scheme, where the NFT owners specify token addresses and token amounts required for accessing the content of the NFT.
2. MemberCard - a smart contract to handle membership subscription. It essentially is an NFT smart contract with expiration functionality. Member cards work together with the content NFT.
3. VidefiDAO - a smart contract that handles benefit sharing among DAO members who stake some tokens on the contract.