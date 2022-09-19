// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import './IERC20.sol';

// ERC20 标准中可选元数据功能的接口
interface IERC20Metadata is IERC20 {
    // 返回代币名称
    function name() external view returns (string memory);

    // 返回代币符号
    function symbol() external view returns (string memory);

    // 返回代币的精度（小数位数）
    function decimals() external view returns (uint8);
}