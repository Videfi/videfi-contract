// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VidefiContent} from "./VidefiContent.sol";

contract VidefiContentDeployer {
    event ContentCreated(address indexed content);

    function deploy(
        string memory _contentName,
        string memory _contentSymbol,
        string memory _tokenURI,
        uint256 _limitAmount,
        IERC20 _paymentToken,
        uint256 _mintPrice,
        address _beneficiary,
        bool _isDAOBeneficiary,
        address[] memory _tokenGates,
        uint256[] memory _tokenGateAmounts
    ) external {
        VidefiContent content = new VidefiContent(
            _contentName,
            _contentSymbol,
            _tokenURI,
            _limitAmount,
            _paymentToken,
            _mintPrice,
            _beneficiary,
            _isDAOBeneficiary,
            _tokenGates,
            _tokenGateAmounts,
            msg.sender
        );

        emit ContentCreated(address(content));
    }
}
