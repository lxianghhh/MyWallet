// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract GetAbi{
    // 获取改交易门槛函数的abi
    function changeThresholdencode(uint256 new_threshold) public pure returns(bytes memory result) {
        result =abi.encodeWithSelector(bytes4(keccak256("changeThreshold(uint256)")), new_threshold);
    }
    // 获取增加持有人函数的abi
    function addOwnersencode(address x, uint256 y) public pure returns(bytes memory result) {
        result =abi.encodeWithSelector(bytes4(keccak256("addOwnersAndThreshold(address,uint256)")),x,y);
    }

    // 获取减少持有人函数的abi
    function removeOwnersencode(address x, uint256 y) public pure returns(bytes memory result) {
        result =abi.encodeWithSelector(bytes4(keccak256("removeOwners(address,uint256)")), x,y);
        return result;
    }
}