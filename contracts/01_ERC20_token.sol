
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./abstracts/Context.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./libraries/SafeMath.sol";

/**
    作为一个简单的test。
    deloy: 只有name和symbol，无添加总量，这个要在constructor下添加，contracts为合约地址
*/


// 继承ERC20，指定名称和代币符号
// contract GLDToken is ERC20 {
//     constructor(uint256 initialSupply) ERC20("Gold", "GLD") {
//         _mint(msg.sender, initialSupply);  // 然后把代币mint到部署合约钱包地址中
//     }
// }

// 实现{IERC20}接口
contract ERC20 is Context, IERC20, IERC20Metadata {
    
    //使用uint256调用SafeMath
   using SafeMath for uint256;


    //  一个地址下有多少代币
    mapping(address => uint256) private _balances;

    // 授权代币数量
    mapping(address => mapping(address => uint256)) private _allowances;
    
    //token的总量
    uint256 private _totalSupply ;
    //token的名字 name
    string private _name;
    //token的符号
    string private _symbol;

    // 设置 {name} 和 {symbol} 的值
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        //？
        // _mint(msg.sender, _totalSupply);//然后把代币mint到部署合约钱包地址中
    }
    // IERC20Metadata
    // 返回代币的名称
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // 返回代币的符号
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // 返回代币的精度（小数位数）
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    // IERC20Metadata
    
    // 返回存在的代币数量
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    // 返回 account 拥有的代币数量
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    // 从操作者地址发送amount代币给to钱包地址
    // 返回一个布尔值表示操作是否成功
    // 发出 {Transfer} 事件
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // 返回owner地址授权给spender地址的代币数量
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    //授权spender地址amount代币
    // 调用者设置 spender 消费自己amount数量的代币
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // 将amount数量的代币从 sender 移动到 recipient ，从调用者的账户扣除 amount
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    // 增加调用者授予 spender 的可消费数额
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    // 减少调用者授予 spender 的可消费数额
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // 将amount数量的代币从 sender 移动到 recipient
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    // 铸造代币，这个函数很重要，当我们部署合约后，初始代币就是从这里来的
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    // 销毁一个地址下amount代币，会影响到代币总量
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    //  授权代币，内部函数
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // 在任何代币转移之前调用的钩子， 包括铸币和销币
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // 在任何代币转移之后调用的钩子， 包括铸币和销币
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

