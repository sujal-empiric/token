// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Token is ERC20("DEZ", "$DEZ"), Ownable {
    using SafeMath for uint;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address public liquidityPairAddress;
    uint256 public buyTax = 10;
    uint256 public sellTax = 10;
    address public taxAddress;

    constructor() {
        _name = "DEZ";
        _symbol = "$DEZ";
        _mint(msg.sender, (1000000000 * 10 ** 18));
        taxAddress = 0xbacf5fEAAB46dFe77f6c97ba0ff8aAfBc73753f6;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        liquidityPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    }

    function setLiquidityPairAddress(
        address newLiquidityAddress_
    ) public onlyOwner {
        require(
            newLiquidityAddress_ != address(0),
            "Token: New Liquidity Pair address can not be zero."
        );
        liquidityPairAddress = newLiquidityAddress_;
    }

    function setTaxAddress(address newTaxAddress_) public onlyOwner {
        require(
            newTaxAddress_ != address(0),
            "Token: New Liquidity Pair address can not be zero."
        );
        taxAddress = newTaxAddress_;
    }

    function setTax(uint256 buyTax_, uint256 sellTax_) public onlyOwner {
        buyTax = buyTax_;
        sellTax = sellTax_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (
            from == liquidityPairAddress &&
            to != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ) {
            uint256 taxAmount = amount.mul(buyTax).div(100);
            require(taxAmount < amount, "FROM: TAX AMOUNT IS MORE THEN AMOUNT");
            uint256 finalAmount = amount - taxAmount;
            unchecked {
                _balances[from] = fromBalance - amount;
                _balances[to] += finalAmount;
                _balances[taxAddress] += taxAmount;
            }
        } else if (
            to == liquidityPairAddress &&
            to != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ) {
            uint256 taxAmount = amount.mul(sellTax).div(100);
            require(taxAmount < amount, "TO: TAX AMOUNT IS MORE THEN AMOUNT");
            uint256 finalAmount = amount - taxAmount;
            unchecked {
                _balances[from] = fromBalance - amount;
                _balances[to] += finalAmount;
                _balances[taxAddress] += taxAmount;
            }
        } else {
            unchecked {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
            }
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
