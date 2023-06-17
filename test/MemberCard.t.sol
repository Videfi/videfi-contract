pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MemberCard} from "../src/MemberCard.sol";
import {VidefiDAO} from "../src/VidefiDAO.sol";

contract MemberCardTest is Test {
    MemberCard private bronzeMemberCard;
    MemberCard private goldMemberCard;
    
    VidefiDAO private videfiDao;
    ERC20 private govToken;
    ERC20 private rewardToken;

    function setUp() public {
        govToken = new ERC20("GovernanceToken", "GOV");
        rewardToken = new ERC20("RewardToken", "REW");

        videfiDao = new VidefiDAO(
            "GOV DAO",
            "Image",
            address(govToken),
            address(rewardToken)
        );
        
        _stake(address(this), 100 * 1e18);

        bronzeMemberCard = new MemberCard(
            "Bronze Card",
            "BRONZE",
            "Token URI",
            30 days,
            type(uint).max,
            rewardToken,
            1e18,
            address(this),
            false
        );

        goldMemberCard = new MemberCard(
            "Gold Card",
            "GOLD",
            "Token URI",
            type(uint).max,
            1,
            rewardToken,
            100 * 1e18,
            address(videfiDao),
            true
        );
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

    function _mint(MemberCard memberCard, address minter) private {
        vm.startPrank(minter);
        rewardToken.approve(address(memberCard), type(uint).max);
        memberCard.safeMint(minter);
        vm.stopPrank();
    }

    function testCardTokenURI() public {
        assertEq(bronzeMemberCard.tokenURI(0), "Token URI");
    }

    function testBronzeMemberCardMint() public {
        // 1. Alice has 10 REW
        address alice = address(1);
        deal(address(rewardToken), alice, 10 * 1e18, true);

        // 2. Alice mint 1 member card using 1 REW
        _mint(bronzeMemberCard, alice);

        // 3. Alice should have remaining 9 REW
        assertEq(rewardToken.balanceOf(alice), 9 * 1e18, "Alice remaining bal");

        // 4. Alice should get 1 member card
        assertEq(bronzeMemberCard.balanceOf(alice), 1, "Alice Member Card");

        // 5. This contract as a member card creator should get 1 REW
        assertEq(rewardToken.balanceOf(address(this)), 1 * 1e18, "Creator balance");
    }

    function testDAOClaimBenefit() public {
        // 1. Alice has 10,000 REW
        address alice = address(1);
        deal(address(rewardToken), alice, 10000 * 1e18, true);

        // 2. Alice mint the first card succesfully
        _mint(goldMemberCard, alice);

        // 3. As a DAO member, this contract should be able to claim reward
        videfiDao.claim();

        // 4. REW balance of this should be equal to the gold card price
        assertEq(rewardToken.balanceOf(address(this)), goldMemberCard.mintPrice());
    }

    function testGoldMemberCardMintLimit() public {
        // 1. Alice has 10,000 REW
        address alice = address(1);
        deal(address(rewardToken), alice, 10000 * 1e18, true);

        // 2. Alice mint the first card succesfully
        _mint(goldMemberCard, alice);

        // 3. Alice fails to mint the second card because it reaches limit
        vm.startPrank(alice);
        rewardToken.approve(address(goldMemberCard), type(uint).max);
        vm.expectRevert("Card limit reached");
        goldMemberCard.safeMint(alice);
        vm.stopPrank();
    }

    function testTimeLimit() public {
        // 1. Alice has 10 REW
        address alice = address(1);
        deal(address(rewardToken), alice, 10 * 1e18, true);

        // 2. Alice mint 1 member card using 1 REW
        _mint(bronzeMemberCard, alice);

        // 3. Alice member card is valid in the current time. Her card balance should be 1.
        assertEq(bronzeMemberCard.isCardValid(0), true);
        assertEq(bronzeMemberCard.balanceOf(alice), 1);

        // 4. Alice member card is valid in the next 29 days. Her card balance should be 1.
        vm.warp(block.timestamp + 29 days);
        assertEq(bronzeMemberCard.isCardValid(0), true);
        assertEq(bronzeMemberCard.balanceOf(alice), 1);

        // 5. Alice member card is not valid in the next 1 days (totally 30 days from the minting date). Her card balance should be 0.
        vm.warp(block.timestamp + 1 days);
        assertEq(bronzeMemberCard.isCardValid(0), false);
        assertEq(bronzeMemberCard.balanceOf(alice), 0);
    }


}
