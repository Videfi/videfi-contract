pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {VidefiDAO} from '../src/VidefiDAO.sol';

contract VidefiDAOTest is Test {

    VidefiDAO private videfiDao;
    ERC20 private govToken;
    ERC20 private rewardToken;

    function setUp() public {
        govToken = new ERC20("GovernanceToken", "GOV");
        rewardToken = new ERC20("RewardToken", "REW");
        videfiDao = new VidefiDAO("GOV DAO", "Image", address(govToken), address(rewardToken));
    }

    function _stake(address staker, uint256 amount) private {
        deal(address(govToken), staker, amount, true);
        vm.startPrank(staker);
        govToken.approve(address(videfiDao), type(uint).max);
        videfiDao.stake(amount);
        vm.stopPrank();
    }

    function _updateRewardIndex(uint256 amount) private {
        deal(address(rewardToken), address(this), amount, true);
        rewardToken.approve(address(videfiDao), type(uint).max);
        videfiDao.updateRewardIndex(amount);
    }

    function _claim(address claimer) private {
        vm.startPrank(claimer);
        videfiDao.claim();
        vm.stopPrank();
    }

    function testBenefitSharing() public {
        // 1. Alice stake 10 GOV to the contract
        address alice = address(1);
        _stake(alice, 10 * 1e18);
        console.log("Stake of alice: ", videfiDao.balanceOf(alice));

        // 2. Bob stake 100 GOV to the contract
        address bob = address(2);
         _stake(bob, 100 * 1e18);
        console.log("Stake of bob: ", videfiDao.balanceOf(bob));

        // 3. Reward is distributed to the contract for 100 REW
        _updateRewardIndex(10 * 1e18);

        // 4. Alice should be able to claim reward for 10/(10 + 100) * 100 = 10 / 110 * 100 = 9.09
        _claim(alice);
        console.log(rewardToken.balanceOf(alice) / 1e18, "Alice reward");
        
        // 5. Bob should be able to claim reward for 100/(10 + 100) * 100 = 100 / 110 * 100 = 90.909
        _claim(bob);
        console.log(rewardToken.balanceOf(bob) / 1e18, "Bob reward");
    }


}