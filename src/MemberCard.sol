// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVidefiDAO.sol";

contract MemberCard is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public allTokenURI;
    uint256 public duration;
    uint256 public limitAmount;
    IERC20 public paymentToken;
    uint256 public mintPrice;
    address public beneficiary;
    bool public isDAOBeneficiary;

    mapping(uint256 => uint256) public cardExpiry;

    constructor(
        string memory _cardName,
        string memory _cardSymbol,
        string memory _tokenURI,
        uint256 _duration,
        uint256 _limitAmount,
        IERC20 _paymentToken,
        uint256 _mintPrice,
        address _beneficiary,
        bool _isDAOBeneficiary
    ) ERC721(_cardName, _cardSymbol) {
        allTokenURI = _tokenURI;
        duration = _duration;
        limitAmount = _limitAmount;
        paymentToken = _paymentToken;
        mintPrice = _mintPrice;
        beneficiary = _beneficiary;
        isDAOBeneficiary = _isDAOBeneficiary;

        if (_isDAOBeneficiary) {
            require(
                address(_paymentToken) ==
                    IVidefiDAO(_beneficiary).rewardToken(),
                "Payment token mismatch"
            );
        }
    }

    function safeMint(address to) external returns (uint256) {
        require(totalSupply() < limitAmount, "Card limit reached");

        if (isDAOBeneficiary) {
            paymentToken.approve(beneficiary, mintPrice);
            paymentToken.transferFrom(to, address(this), mintPrice);
            IVidefiDAO(beneficiary).updateRewardIndex(mintPrice);
        } else {
            paymentToken.transferFrom(to, beneficiary, mintPrice);
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        if (duration != type(uint).max)
            cardExpiry[tokenId] = block.timestamp + duration;

        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function isCardValid(uint256 cardId) public view returns (bool) {
        return cardExpiry[cardId] > block.timestamp;
    }

    function getCardExpiry(uint256 cardId) external view returns (uint256) {
        return cardExpiry[cardId];
    }

    // Override balance of functionality
    function balanceOf(
        address owner
    ) public view override(ERC721, IERC721) returns (uint256 balance) {
        uint256 allTokensBalances = super.balanceOf(owner);
        uint256 validCount = 0;
        for (uint256 i = 0; i < allTokensBalances; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            bool isValid = isCardValid(tokenId);
            if (isValid) {
                validCount++;
            }
        }
        return validCount;
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        tokenId; //unused variable
        return allTokenURI;
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
