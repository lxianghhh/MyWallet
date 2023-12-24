// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract SelfAuthorize{
    // 设置改变钱包持有人参数的权限，必须要此钱包发动交易才可以改变参数
    function requireSigned()internal view{
        require(msg.sender == address(this), "Not authorized");
    }

    modifier signed(){
        requireSigned();
        _;
    }
}