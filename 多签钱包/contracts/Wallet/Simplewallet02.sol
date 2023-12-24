// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import{ManageOwner} from "./ManageOwner.sol";
import {GetAbi} from "./GetAbi.sol";

contract Wallet is ManageOwner , GetAbi{
    event InitialSuccess(address indexed initiator, address[] owners, uint256 threshold);
    event ExecutionSuccess(bytes32 indexed txhash);
    event ExecutionFailure(bytes32 indexed txhash);
    event Receiveeth(address indexed sender,uint256 value);
    event Callfallback(address indexed sender,uint256 value, bytes data);

    // 交易次数
    uint256 public nonce;
    
    constructor(
        address[] memory _owners,
        uint256 _threshold
    ){
        _initialwallet(_owners, _threshold);
        emit InitialSuccess(msg.sender, _owners,_threshold);
    }

    // 创建并执行交易
    function exertransact(
        // 转入的地址
        address to,
        // 转账金额
        uint256 value,
        // 调用的函数abi
        bytes calldata data,
        // 签名
        bytes memory signatures
        )public payable virtual returns(bool success){
            bytes32 txhash;
            // 获取交易哈希
            txhash = encodetx(
                to,
                value, 
                data,
                nonce,
                block.chainid
                );
            nonce++;
            // 检查签名
            checkSignature(txhash, signatures);
            // 验证通过则开始交易
            (success,) = to.call{value: value}(data);
            if (success)
                emit ExecutionSuccess(txhash);
            else 
                emit ExecutionFailure(txhash);                
        }
    // 验证签名
    function checkSignature(bytes32 datatxhash, bytes memory signatures)public view {
        uint256 _threshold = threshold;
        // 检查门槛是否设定
        require(_threshold > 0, "error05");
        // 开始验证签名
        startCheckSignature(datatxhash, signatures, _threshold);
    }
    function startCheckSignature (bytes32 txhash, bytes memory signatures, uint256 numOfsignatures)internal view {
        // 检查签名足够长
        require(signatures.length >= numOfsignatures * 65,"Signatures too short");
        // 开始循环检查签名
        // 1. 用ecdsa先验证签名是否有效
        // 2. 利用 currentOwner > lastOwner 确定签名来自不同多签（多签地址递增）
        // 3. 确定签名者是否为为多签持有人
        address lastowner;
        address currentowner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for(i=0; i<numOfsignatures; i++){
            (v, r, s) = signatureSplit(signatures, i);
            // 验证签名是否有效,ecrecover()函数获取交易哈希与签名，返回公钥(地址)
            currentowner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",txhash)), v, r, s);
            require(currentowner > lastowner && ownerExist(currentowner), "error06");
            
            lastowner = currentowner;
        }
    }
    // 将单个签名从打包的签名分离出来
    
    function signatureSplit(bytes memory signatures, uint256 pos)internal pure returns(uint8 v,bytes32 r,bytes32 s){
        // 签名的格式：{bytes32 r}{bytes32 s}{uint8 v}
        assembly {
            //计算签名在字节数组中的位置。
            /*
            pos用于确定要提取的签名的索引(提取第几个签名)。
            0x41 是每个签名所占的字节数（r 和 s一共64bytes，加上一个字节的 v，总共65bytes，16进制下为0x41）
            所以乘以 pos 可以得到相应签名的起始位置
            */
            let signaturePos := mul(0x41, pos)
            //从指定的签名的位置获取 r 值。
            /*
            add(signaturePos, 0x20)计算r在签名中的位置，0x20为r的大小
            add(signatures, add(signaturePos, 0x20))签名的起始位置加上r在签名中的位置即为r在内存中的位置
            最后用mload读取此位置开始的32bytes的数据，即为r的数据。
            */
            r := mload(add(signatures, add(signaturePos, 0x20)))
            //计算s在内存中的位置
            /*
            add(signaturePos, 0x40)计算s在签名中的位置，0x40为s的大小
            add(signatures, add(signaturePos, 0x40))签名的起始位置加上s在签名中的位置即为s在内存中的位置
            最后用mload读取此位置开始的32bytes的数据，即为s的数据。
            */
            s := mload(add(signatures, add(signaturePos, 0x40)))
            //计算v在内存中的位置
            /*
            因为v在签名最后一字节，而mload会读取32字节数据
            则找到包含v数据在内，且v数据为首字节的32bytes数据的内存位置
            用mload将此32bytes数据，并用byte(0,)取其第一字节数据即为v
            */
            v := byte(0, mload(add(signatures, add(signaturePos, 0x60))))
        }
    }

    // 获取交易信息
    function getTxhash(
        address to,
        uint256 value,
        bytes memory data
    ) public view returns(bytes32) {
        return encodetx(to,value,data,nonce,block.chainid);
    }

    //编码交易信息
    function encodetx(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    )private pure returns(bytes32){
        bytes32 safetxhash = keccak256(
            abi.encode(
                to,
                value,
                keccak256(data),
                _nonce,
                chainid
            )
        );
        return safetxhash;
    }
    

    receive() external payable {
        if (msg.value>0)
            emit Receiveeth(msg.sender,msg.value);
    }

    fallback() external payable {
        emit Callfallback(msg.sender,msg.value, msg.data);
    }

    

}