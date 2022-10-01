pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        // 空字符串hash值
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;  
        //内联编译（inline assembly）语言，是用一种非常底层的方式来访问EVM
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

library SafeERC20 {
    using Address for address;
 
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
 
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
 
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
 
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
 
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Pledge {
    using SafeERC20 for ERC20;

    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
 
    address private owner;
    
    mapping(address => PledgeOrder) public _orders;

    //a代币合约地址 旧币
    ERC20 public _PledgeToken = ERC20(0xF44eA90A86C837937C45EE7A9f5eCAEf2a0Ba128);
    //b代币合约地址
    ERC20 public _newToken = ERC20(0xF44eA90A86C837937C45EE7A9f5eCAEf2a0Ba128);

    address public zero = 0x0000000000000000000000000000000000000001;

    //千分之三收益
    uint256 public _rewardFee = 3;
    //质押数量3倍进奖池
    uint256 public _powerFee = 3;

    uint256 public _minAmount = 2000 * 10 ** 18;

    mapping(address => address) public recommendList;
 

    //是否存在质押记录 最后一次领取时间 分销可领取余金额 奖池总额 当前奖池剩余额度
    struct PledgeOrder {
        bool isExist;
        uint256 lastTime;
        uint256 receiveAmount;
        uint256 totalAmount;
        uint256 rewardAmount;
    }
 
    constructor () public{
        owner = msg.sender;
    }
	
	//质押代币
	//质押之前需要先调用其合约的approve方法 获取授权
    function pledgeToken(uint256 _amount) public{
        require(_amount > _minAmount, "amount too little");
        require(address(msg.sender) == address(tx.origin), "no contract");
		_newToken.transferFrom(msg.sender, address(this), _amount);
        if(_orders[msg.sender].isExist == false){
            createOrder(_amount);
        }else{
            PledgeOrder storage order=_orders[msg.sender];

            order.totalAmount = order.totalAmount + (_amount * _powerFee);
            order.rewardAmount = order.rewardAmount + (_amount * _powerFee);
        }
        _newToken.safeTransfer(zero, _amount);
    }
 
    function createOrder(uint256 trcAmount) private {
        _orders[msg.sender] = PledgeOrder(
            true,
            block.timestamp,
            0,
            trcAmount,
            trcAmount
        );
    }

	//提取收益
    function takeProfit() public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder storage order = _orders[msg.sender];
        uint256 day = (block.timestamp - order.lastTime) / SECONDS_PER_DAY;
        require(day > 0 || order.receiveAmount > 0, "no reward");
        uint256 pledgeBalance = _PledgeToken.balanceOf(address(this));

        // 奖池总量 * 收益倍率 * 天数 + 分销收益
        uint256 profits = order.totalAmount * _rewardFee / 1000 * day;
        
        address rec1 = recommendList[msg.sender];
        if(rec1 != address(0)){
            PledgeOrder storage order1 = _orders[rec1];
            if(order1.isExist){
                order1.receiveAmount += profits / 4;
            }

            address rec2 = recommendList[rec1];
            if(rec2 != address(0)){
                PledgeOrder storage order2 = _orders[rec2];
                if(order2.isExist){
                    order2.receiveAmount += profits / 2;
                }
            }
        }

        profits += order.receiveAmount;
        require(pledgeBalance >= profits, "no balance");
        _PledgeToken.safeTransfer(address(msg.sender), profits);
        //提取收益后刷新时间
        order.lastTime = block.timestamp;
        order.receiveAmount = 0;
        order.rewardAmount = order.rewardAmount - profits;
    }

	//查询收益
    function getParentProfitToken(address _target) public view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        PledgeOrder memory order = _orders[_target];
        uint256 day = (block.timestamp - order.lastTime) / SECONDS_PER_DAY;
        uint256 profits = order.totalAmount * _rewardFee / 1000 * day + order.receiveAmount;
        return profits;
    }

    function changeOwner(address paramOwner) public onlyOwner {
		owner = paramOwner;
    }

    function setRewardFee(uint256 _fee) public onlyOwner {
		_rewardFee = _fee;
    }

    function withdraw(address _token, address _target, uint256 _amount) public onlyOwner {
        require(ERC20(_token).balanceOf(address(this)) >= _amount, "no balance");
		ERC20(_token).safeTransfer(_target, _amount);
    }


    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
 
    function getOwner() public view returns (address) {
        return owner;
    }

    function bind(address _target) public {
        recommendList[msg.sender] = _target;
    }
}