// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IVidefiContent {
    function allTokenURI() external view returns (string memory);
    function duration() external view returns (uint256);
    function limitAmount() external view returns (uint256);
    function paymentToken() external view returns (address);
    function mintPrice() external view returns (uint256);
    function beneficiary() external view returns (address);
    function isDAOBeneficiary() external view returns (bool);
    function safeMint() external returns (uint256);
    function isAccessible(address viewer, uint256 tokenId, address tokenGate) external view returns (bool);
}
