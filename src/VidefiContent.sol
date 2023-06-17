// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVidefiDAO.sol";

contract VidefiContent is ERC721, ERC721Enumerable, ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public allTokenURI;
    uint256 public duration;
    uint256 public limitAmount;
    IERC20 public paymentToken;
    uint256 public mintPrice;
    address public beneficiary;
    bool public isDAOBeneficiary;

    // token_id => card_address => card_amount
    mapping(uint256 => mapping(address => uint256)) accessControl;
    mapping(uint256 => bool) contentProtected;

    constructor(
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
    ) ERC721(_contentName, _contentSymbol) {
        allTokenURI = _tokenURI;
        limitAmount = _limitAmount;
        paymentToken = _paymentToken;
        mintPrice = _mintPrice;
        beneficiary = _beneficiary;
        isDAOBeneficiary = _isDAOBeneficiary;

        if (_isDAOBeneficiary) {
            require(address(_paymentToken) == IVidefiDAO(_beneficiary).rewardToken(), "Payment token mismatch");
        }

        uint256 id = _safeMint(msg.sender);
        require(_tokenGates.length == _tokenGateAmounts.length, "Token gate length mismatch");
        for (uint256 i = 0; i < _tokenGates.length; i++) {
            accessControl[id][_tokenGates[i]] = _tokenGateAmounts[i];
        }

        if (_tokenGates.length > 0) {
            contentProtected[id] = true;
        }
    }

    function safeMint() public returns (uint256) {
        if (isDAOBeneficiary) { 
            paymentToken.approve(beneficiary, mintPrice);
            paymentToken.transferFrom(
                msg.sender,
                address(this),
                mintPrice
            );
            IVidefiDAO(beneficiary).updateRewardIndex(mintPrice);
        } else {
            paymentToken.transferFrom(
                msg.sender,
                beneficiary,
                mintPrice
            );
        }

        return _safeMint(msg.sender);
    }

    function _safeMint(address to) private returns (uint256) {
        require(totalSupply() < limitAmount, "Content limit reached");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        super._safeMint(to, tokenId);
        return tokenId;
    }

    function isAccessible(address viewer, uint256 tokenId, address tokenGate) external view returns (bool) {
        // Not protected content is always viewable
        if (!contentProtected[tokenId]) return true;
        // Owner is always be able to view
        if (ownerOf(tokenId) == viewer) return true;

        uint256 tokenGateAmount = accessControl[tokenId][tokenGate];
        // The provided tokenGate is not in the list
        if (tokenGateAmount == 0) return false;

        // Check whether the viewer has sufficient token gates
        return IERC721(tokenGate).balanceOf(viewer) >= tokenGateAmount;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
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
