// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IVidefiDAO {
    function name() external view returns (string memory);
    function image() external view returns (string memory);
    function governanceToken() external view returns (address);
    function rewardToken() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function updateRewardIndex(uint256 reward) external;
    function calculateRewardsEarned(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function claim() external returns (uint256);
}
