// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VidefiDAO} from "./VidefiDAO.sol";

contract VidefiDAODeployer {
    event DAOCreated(address indexed dao);

    function deploy(
        string memory _name,
        string memory _image,
        address _governanceToken,
        address _rewardToken
    ) external {
        VidefiDAO dao = new VidefiDAO(
            _name,
            _image,
            _governanceToken,
            _rewardToken
        );
        emit DAOCreated(address(dao));
    }
}
