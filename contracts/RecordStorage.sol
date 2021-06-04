// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IRecordStorage.sol';
import './KeyStorage.sol';

abstract contract RecordStorage is KeyStorage, IRecordStorage {
    // Mapping from token ID to preset id to key to value
    mapping (uint256 => mapping (uint256 =>  mapping (string => string))) internal _records;

    // Mapping from token ID to current preset id
    mapping (uint256 => uint256) internal _presets;

    function get(string memory key, uint256 tokenId) public view override returns (string memory) {
        return _records[tokenId][_presets[tokenId]][key];
    }

    function getByHash(
        uint256 keyHash,
        uint256 tokenId
    ) public view override returns (string memory key, string memory value) {
        key = getKey(keyHash);
        value = get(key, tokenId);
    }

    function getManyByHash(
        uint256[] memory keyHashes,
        uint256 tokenId
    ) public view override returns (string[] memory keys, string[] memory values) {
        uint256 keyCount = keyHashes.length;
        keys = new string[](keyCount);
        values = new string[](keyCount);
        for (uint256 i = 0; i < keyCount; i++) {
            (keys[i], values[i]) = getByHash(keyHashes[i], tokenId);
        }
    }

    function getMany(
        string[] calldata keys,
        uint256 tokenId
    ) public view override returns (string[] memory) {
        uint256 keyCount = keys.length;
        string[] memory values = new string[](keyCount);
        uint256 preset = _presets[tokenId];
        for (uint256 i = 0; i < keyCount; i++) {
            values[i] = _records[tokenId][preset][keys[i]];
        }
        return values;
    }

    function _set(string calldata key, string calldata value, uint256 tokenId) internal {
        _set(_presets[tokenId], key, value, tokenId);
    }

    function _setMany(string[] memory keys, string[] memory values, uint256 tokenId) internal {
        _setMany(_presets[tokenId], keys, values, tokenId);
    }

    function _reconfigure(string[] memory keys, string[] memory values, uint256 tokenId) internal {
        _setPreset(tokenId);
        _setMany(_presets[tokenId], keys, values, tokenId);
    }

    function _reset(uint256 tokenId) internal {
        _setPreset(tokenId);
    }

    function _setPreset(uint256 tokenId) private {
        _presets[tokenId] = block.timestamp;
        emit ResetRecords(tokenId);
    }

    function _set(uint256 preset, string memory key, string memory value, uint256 tokenId) private {
        bool isNewKey = bytes(_records[tokenId][preset][key]).length == 0;
        _records[tokenId][preset][key] = value;
        addKey(key);

        if (isNewKey) {
            emit NewKey(tokenId, key, key);
        }
        emit Set(tokenId, key, value, key, value);
    }

    function _setMany(uint256 preset, string[] memory keys, string[] memory values, uint256 tokenId) private {
        uint256 keyCount = keys.length;
        for (uint256 i = 0; i < keyCount; i++) {
            _set(preset, keys[i], values[i], tokenId);
        }
    }
}