// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MemberCard is ERC721Enumerable {
    struct CardTemplate {
        string cardImage;
        string cardName;
        uint256 duration;
        uint256 limitAmount;
        IERC20 paymentToken;
        uint256 mintPrice;
        address payable beneficiary;
    }

    CardTemplate public cardTemplate;
    mapping(uint256 => uint256) public cardExpiry;

    constructor(
        string memory cardImage,
        string memory cardName,
        uint256 duration,
        uint256 limitAmount,
        IERC20 paymentToken,
        uint256 mintPrice,
        address payable beneficiary
    ) ERC721("MemberCard", "MC") {
        cardTemplate = CardTemplate({
            cardImage: cardImage,
            cardName: cardName,
            duration: duration,
            limitAmount: limitAmount,
            paymentToken: paymentToken,
            mintPrice: mintPrice,
            beneficiary: beneficiary
        });
    }

    function mint() external {
        require(totalSupply() < cardTemplate.limitAmount, "Card limit reached");
        require(
            cardTemplate.paymentToken.transferFrom(msg.sender, cardTemplate.beneficiary, cardTemplate.mintPrice),
            "Payment failed"
        );

        uint256 newCardId = totalSupply() + 1;
        _mint(msg.sender, newCardId);
        cardExpiry[newCardId] = block.timestamp + cardTemplate.duration;
    }

    function isCardValid(uint256 cardId) external view returns (bool) {
        return cardExpiry[cardId] > block.timestamp;
    }

    function getCardExpiry(uint256 cardId) external view returns (uint256) {
        return cardExpiry[cardId];
    }
}
