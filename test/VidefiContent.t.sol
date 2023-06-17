pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {VidefiContent} from "../src/VidefiContent.sol";
import {VidefiDAO} from "../src/VidefiDAO.sol";
import {MemberCard} from "../src/MemberCard.sol";

contract VidefiContentTest is Test, IERC721Receiver {
    VidefiContent private unlimitedContent;
    VidefiContent private limitedContent;

    MemberCard private goldMemberCard;
    
    VidefiDAO private videfiDao;
    ERC20 private govToken;
    ERC20 private rewardToken;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

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

        goldMemberCard = new MemberCard(
            "Gold Card",
            "GOLD",
            "Token URI",
            30 days,
            1,
            rewardToken,
            100 * 1e18,
            address(videfiDao),
            true
        );

        address[] memory unlimitedContentTokenGates = new address[](0);
        uint256[] memory unlimitedContentTokenGateAmounts = new uint256[](0);

        unlimitedContent = new VidefiContent(
            "Unlimited Content",
            "UNLIMITED",
            "Token URI",
            type(uint).max,
            rewardToken,
            1e18,
            address(this),
            false,
            unlimitedContentTokenGates,
            unlimitedContentTokenGateAmounts,
            address(this)
        );

        address[] memory limitedContentTokenGates = new address[](1);
        uint256[] memory limitedContentTokenGateAmounts = new uint256[](1);

        limitedContentTokenGates[0] = address(goldMemberCard);
        limitedContentTokenGateAmounts[0] = 1;

        limitedContent = new VidefiContent(
            "Limited Content",
            "LIMITED",
            "Token URI",
            2,
            rewardToken,
            100 * 1e18,
            address(videfiDao),
            true,
            limitedContentTokenGates,
            limitedContentTokenGateAmounts,
            address(this)
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

    function _mint(VidefiContent content, address minter) private {
        vm.startPrank(minter);
        rewardToken.approve(address(content), type(uint).max);
        content.safeMint(minter);
        vm.stopPrank();
    }

    function _mintMemberCard(MemberCard memberCard, address minter) private {
        vm.startPrank(minter);
        rewardToken.approve(address(memberCard), type(uint).max);
        memberCard.safeMint(minter);
        vm.stopPrank();
    }

    function testCardTokenURI() public {
        assertEq(unlimitedContent.tokenURI(0), "Token URI");
    }

    function testUnlimitedContent() public {
        // 1. Alice has 10 REW
        address alice = address(1);
        deal(address(rewardToken), alice, 10 * 1e18, true);

        // 2. Alice mint 1 content using 1 REW
        _mint(unlimitedContent, alice);

        // 3. Alice should have remaining 9 REW
        assertEq(rewardToken.balanceOf(alice), 9 * 1e18, "Alice remaining bal");

        // 4. Alice should get 1 content NFT
        assertEq(unlimitedContent.balanceOf(alice), 1, "Alice Content");

        // 5. This contract as a content creator should get 1 REW
        assertEq(rewardToken.balanceOf(address(this)), 1 * 1e18, "Creator balance");
    }

    function testDAOClaimBenefit() public {
        // 1. Alice has 10,000 REW
        address alice = address(1);
        deal(address(rewardToken), alice, 10000 * 1e18, true);

        // 2. Alice mint the first content succesfully
        _mint(limitedContent, alice);

        // 3. As a DAO member, this contract should be able to claim reward
        videfiDao.claim();

        // 4. REW balance of this should be equal to the limited content price
        assertEq(rewardToken.balanceOf(address(this)), limitedContent.mintPrice());
    }

    function testLimitedContentMintLimit() public {
        // 1. Alice has 10,000 REW
        address alice = address(1);
        deal(address(rewardToken), alice, 10000 * 1e18, true);

        // 2. Alice mint the first content succesfully
        _mint(limitedContent, alice);

        // 3. Alice fails to mint the second content because it reaches limit
        vm.startPrank(alice);
        rewardToken.approve(address(limitedContent), type(uint).max);
        vm.expectRevert("Content limit reached");
        limitedContent.safeMint(alice);
        vm.stopPrank();
    }

    function testAccessibleUnlimitedContent() public {
        // 1. Alice should be able to view the original content because it is public 
        address alice = address(1);
        assertTrue(unlimitedContent.isAccessible(alice, 0, address(0)), "Public visibility");

        // 2. Alice should be able to view the content even it passes for 1,000,000 days
        vm.warp(block.timestamp + 1000000 days);
        assertTrue(unlimitedContent.isAccessible(alice, 0, address(0)), "Public visibility after a long time");
    }

    function testAccessibleLimitedContent() public {
        // 1. Alice should not be able to view the limited content because it is protected
        address alice = address(1);
        assertFalse(limitedContent.isAccessible(alice, 0, address(0)), "Private visibility");

        // 2. Alice mint a member card
        deal(address(rewardToken), alice, 10000 * 1e18, true);
        _mintMemberCard(goldMemberCard, alice);

        // 3. Alice should be able to view the limited content using the gold member card
        assertTrue(limitedContent.isAccessible(alice, 0, address(goldMemberCard)), "View with member card");

        // 4. Alice is no longer able to view the limited content when the member card is expired
        vm.warp(block.timestamp + 1000000 days);
        assertFalse(limitedContent.isAccessible(alice, 0, address(goldMemberCard)), "Member card expires");
    }

}
