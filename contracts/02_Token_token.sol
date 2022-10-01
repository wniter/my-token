/**
    简单的bsc发币过程

    Open new project @ https://remix.ethereum.org/

    Add Token.sol with source code

    Compile project verify that the compiler is the same version in the Token.sol

    Deploy with Injected Web 3 Environment ->Injected Provider - Metamask

    IMPORTANT Do not navigate away you need to wait for blocks to commit AND transfer tokens to YOUR wallet

    fill in transfer field syntax: WALLETaccount#, 

    # (ACCOUNT：Ex.0x5284C4980275cCAC3eCcf1e63c0ebC0fEceA49B4, GAS LIMIT：10000)

    verify transaction after 1min+ @ https://bscscan.com/ with your Wallet Account Number

    Listing on Pancake Swap -> deploy

    Add Liquidity for trading Recommend: BNB / NewToken for Pair

    For the NewToken you need to paste the CONTRACT address

    Done! -> ensure Address of Deploy token (Deployed Contracts)

 */
pragma solidity ^0.8.2;
// SPDX-License-Identifier: GPL-3.0

/**
    简单的例子
*/
contract Token {
  
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "Cong Yu Pig";
    string public symbol = "CYG";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    //msg.sender 为环境变量 
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}


/****************************************************************
Deployed Contracts
https://draveness.me/smart-contract-deploy/

****************************************************************
 */