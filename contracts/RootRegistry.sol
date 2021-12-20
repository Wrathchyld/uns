// @author Unstoppable Domains, Inc.
// @date December 20th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol';

import './@maticnetwork/IMintableERC721.sol';
import './@maticnetwork/IRootChainManager.sol';
import './@maticnetwork/RootChainManagerStorage.sol';

abstract contract RootRegistry is ERC721Upgradeable, IMintableERC721 {
    // This is the keccak-256 hash of "uns.polygon.root_chain_manager" subtracted by 1
    bytes32 internal constant _ROOT_CHAIN_MANAGER_SLOT = 0xbe2bb46ac0377341a1ec5c3116d70fd5029d704bd46292e58f6265dd177ebafe;

    modifier onlyPredicate() {
        require(_msgSender() == _getPredicate(), 'Registry: INSUFFICIENT_PERMISSIONS');
        _;
    }

    /**
     * @dev Stores RootChainManager address.
     * It's one-time operation required to set RootChainManager address.
     * RootChainManager is a contract responsible for bridging Ethereum
     * and Polygon networks.
     * @param rootChainManager address of RootChainManager contract
     */
    function setRootChainManager(address rootChainManager) external {
        require(
            StorageSlotUpgradeable.getAddressSlot(_ROOT_CHAIN_MANAGER_SLOT).value == address(0),
            'Registry: ROOT_CHAIN_MANEGER_NOT_EMPTY'
        );
        StorageSlotUpgradeable.getAddressSlot(_ROOT_CHAIN_MANAGER_SLOT).value = rootChainManager;
    }

    function _deposit(address to, uint256 tokenId) internal {
        address predicate = _getPredicate();
        _approve(predicate, tokenId);

        address manager = StorageSlotUpgradeable.getAddressSlot(_ROOT_CHAIN_MANAGER_SLOT).value;
        IRootChainManager(manager).depositFor(to, address(this), abi.encode(tokenId));
    }

    function _getPredicate() internal view returns(address predicate) {
        address manager = StorageSlotUpgradeable.getAddressSlot(_ROOT_CHAIN_MANAGER_SLOT).value;
        bytes32 tokenType = RootChainManagerStorage(manager).tokenToType(address(this));
        predicate = RootChainManagerStorage(manager).typeToPredicate(tokenType);
    }
}
