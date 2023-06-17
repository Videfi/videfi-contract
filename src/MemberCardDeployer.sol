// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MemberCard} from "./MemberCard.sol";

contract MemberCardDeployer {
    event MemberCardCreated(address indexed content);

    function deploy(
        string memory _cardName,
        string memory _cardSymbol,
        string memory _tokenURI,
        uint256 _duration,
        uint256 _limitAmount,
        IERC20 _paymentToken,
        uint256 _mintPrice,
        address _beneficiary,
        bool _isDAOBeneficiary
    ) external {
        MemberCard memberCard = new MemberCard(
            _cardName,
            _cardSymbol,
            _tokenURI,
            _duration,
            _limitAmount,
            _paymentToken,
            _mintPrice,
            _beneficiary,
            _isDAOBeneficiary
        );

        emit MemberCardCreated(address(memberCard));
    }
}
