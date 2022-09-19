
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface TokenDividendTracker {
    //初始化
    function initialize(address rewardToken_,uint256 minimumTokenBalanceForDividends_) external payable;
    //获取key
    function getKey() external view returns (uint256);
    function setKey(uint256 key_) external;
    function owner() external view returns (address);
    function excludeFromDividends(address account) external;
    function setMinimumTokenBalanceForDividends(uint256 val) external;
    function updateClaimWait(uint256 newClaimWait) external;
    function claimWait() external view returns (uint256);
    function totalDividendsDistributed() external view returns (uint256);
    function withdrawableDividendOf(address account) external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function getAccount(address _account) external view returns (address account,int256 index,int256 iterationsUntilProcessed,uint256 withdrawableDividends,uint256 totalDividends,uint256 lastClaimTime,uint256 nextClaimTime,uint256 secondsUntilAutoClaimAvailable);
    function getAccountAtIndex(uint256 index) external view returns (address,int256,int256,uint256,uint256,uint256,uint256,uint256);
    function process(uint256 gas) external returns (uint256, uint256, uint256);
    function processAccount(address payable account, bool automatic) external returns (bool);
    function getLastProcessedIndex() external view returns(uint256);
    function getNumberOfTokenHolders() external view returns(uint256);
    function setBalance(address payable account, uint256 newBalance) external;
    function distributeCAKEDividends(uint256 amount) external;
    function isExcludedFromDividends(address account) external view returns (bool);
}