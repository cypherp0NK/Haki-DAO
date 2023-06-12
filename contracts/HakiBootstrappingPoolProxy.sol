// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

enum SwapKind { GIVEN_IN, GIVEN_OUT }

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface LBPFactory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    ) external returns (address);
}

interface Vault {
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
    
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountCalculated);
}

interface LBP {
    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) external;

    function setSwapEnabled(bool swapEnabled) external;

    function getPoolId() external returns (bytes32 poolID);
}

interface Blocklist {
    function isNotBlocked(address _address) external view returns(bool);
}
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}
// File: @openzeppelin/contracts/utils/Context.sol

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
/**
 * @title ERC20Decimals
 * @dev Implementation of the ERC20Decimals. Extension of {ERC20} that adds decimals storage slot.
 */
abstract contract ERC20Decimals is ERC20 {
    uint8 private immutable _decimals;

    /**
     * @dev Sets the value of the `decimals`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
/// @title HakiBootstrappingPoolProxy
/// @notice This contract allows for simplified creation and management of Balancer LBPs
/// It currently supports:
/// - LBPs with 2 tokens
/// - Withdrawl of the full liquidity at once
/// - Having multiple fee recipients
contract HakiBootstrappingPoolProxy is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PoolData {
        address owner;
        bool isCorrectOrder;
        uint256 fundTokenInputAmount;
    }

    mapping(address => PoolData) private _poolData;
    EnumerableSet.AddressSet private _pools;
    mapping(address => uint256) private _feeRecipientsBPS;
    EnumerableSet.AddressSet private _recipientAddresses;

    address public constant HakiReserve = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address public constant VAULT = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    uint256 private constant _TEN_THOUSAND_BPS = 10_000;
    address public immutable LBPFactoryAddress;
    uint256 public immutable platformAccessFeeBPS;
    address public blockListAddress;

    constructor(
        uint256 _platformAccessFeeBPS,
        address _LBPFactoryAddress
    ) {
        platformAccessFeeBPS = _platformAccessFeeBPS;
        LBPFactoryAddress = _LBPFactoryAddress;
        // set initial fee recipient to owner of contract
        _recipientAddresses.add(owner());
        _feeRecipientsBPS[owner()] = _TEN_THOUSAND_BPS;
    }

    // Events
    event PoolCreated(
        address indexed pool,
        bytes32 poolId,
        string  name,
        string  symbol,
        address[]  tokens,
        uint256[]  weights,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    );

    event JoinedPool(address indexed pool, address[] tokens, uint256[] amounts, bytes userData);

    event GradualWeightUpdateScheduled(address indexed pool, uint256 startTime, uint256 endTime, uint256[] endWeights);

    event SwapEnabledSet(address indexed pool, bool swapEnabled);

    event TransferredPoolOwnership(address indexed pool, address previousOwner, address newOwner);

    event TransferredFee(address indexed pool, address token, address feeRecipient, uint256 feeAmount);

    event TransferredToken(address indexed pool, address token, address to, uint256 amount);

    event RecipientsUpdated(address[] recipients, uint256[] recipientShareBPS);

    event Skimmed(address token, address to, uint256 balance);

    // Pool access control
    modifier onlyPoolOwner(address pool) {
        require(msg.sender == _poolData[pool].owner, "!owner");
        _;
    }

    /**
     * @dev Checks if the pool address was created in this smart contract
     */
    function isPool(address pool) external view returns (bool valid) {
        return _pools.contains(pool);
    }

    /**
     * @dev Returns the total amount of pools created in the contract
     */
    function poolCount() external view returns (uint256 count) {
        return _pools.length();
    }

    /**
     * @dev Returns a pool for a specific index
     */
    function getPoolAt(uint256 index) external view returns (address pool) {
        return _pools.at(index);
    }

    /**
     * @dev Returns all the pool values
     */
    function getPools() external view returns (address[] memory pools) {
        return _pools.values();
    }

    /**
     * @dev Returns the pool's data saved during creation
     */
    function getPoolData(address pool) external view returns (PoolData memory poolData) {
        return _poolData[pool];
    }

    /**
     * @dev Returns the total amount of LBP Tokens for a pool. These tokens are burned when exit
     */
    function getBPTTokenBalance(address pool) external view returns (uint256 bptBalance) {
        return IERC20(pool).balanceOf(address(this));
    }

    /**
     * @dev Returns all the fee recipients
     */
    function getFeeRecipients() external view returns (address[] memory recipients) {
        return _recipientAddresses.values();
    }

    /**
     * @dev Returns the fee share percentage in BPS for a fee recipient
     */
    function getRecipientShareBPS(address recipientAddress) external view returns (uint256 shareSize) {
        if (_recipientAddresses.contains(recipientAddress)) {
            return _feeRecipientsBPS[recipientAddress];
        }
        return uint256(0);
    }

    struct PoolConfig {
        string name;
        string symbol;
        address[] tokens;
        uint256[] amounts;
        uint256[] weights;
        uint256[] endWeights;
        bool isCorrectOrder;
        uint256 swapFeePercentage;
        uint256 startTime;
        uint256 endTime;
    }

    /**
     * @dev Creates a pool and return the contract address of the new pool
     */
    function createLBP(PoolConfig memory poolConfig) external returns (address) {
        // 1: deposit tokens and approve vault
        require(poolConfig.tokens.length == 2, "Copper LBPs must have exactly two tokens");
        require(poolConfig.tokens[0] != poolConfig.tokens[1], "LBP tokens must be unique");
        require(poolConfig.startTime > block.timestamp, "LBP start time must be in the future");
        require(poolConfig.endTime > poolConfig.startTime, "LBP end time must be greater than start time");
        require(blockListAddress != address(0), "no blocklist address set");
        bool msgSenderIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(msg.sender);
        require(msgSenderIsNotBlocked, "msg.sender is blocked");
        TransferHelper.safeTransferFrom(poolConfig.tokens[0], msg.sender, address(this), poolConfig.amounts[0]);
        TransferHelper.safeTransferFrom(poolConfig.tokens[1], msg.sender, address(this), poolConfig.amounts[1]);
        TransferHelper.safeApprove(poolConfig.tokens[0], VAULT, poolConfig.amounts[0]);
        TransferHelper.safeApprove(poolConfig.tokens[1], VAULT, poolConfig.amounts[1]);

        // 2: pool creation
        address pool = LBPFactory(LBPFactoryAddress).create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.tokens,
            poolConfig.weights,
            poolConfig.swapFeePercentage,
            address(this), // owner set to this proxy
            false // swaps disabled on start
        );

        bytes32 poolId = LBP(pool).getPoolId();
        emit PoolCreated(
            pool,
            poolId,
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.tokens,
            poolConfig.weights,
            poolConfig.swapFeePercentage,
            address(this),
            false    
        );

        // 3: store pool data
        _poolData[pool] = PoolData(
            msg.sender,
            poolConfig.isCorrectOrder,
            poolConfig.amounts[poolConfig.isCorrectOrder ? 0 : 1]
        );
        require(_pools.add(pool), "exists already");

        bytes memory userData = abi.encode(0, poolConfig.amounts); // JOIN_KIND_INIT = 0
        // 4: deposit tokens into pool
        Vault(VAULT).joinPool(
            poolId,
            address(this), // sender
            address(this), // recipient
            Vault.JoinPoolRequest(
                poolConfig.tokens,
                poolConfig.amounts,
                userData,
                false)
        );
        emit JoinedPool(pool, poolConfig.tokens, poolConfig.amounts, userData);

        // 5: configure weights
        LBP(pool).updateWeightsGradually(poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);
        emit GradualWeightUpdateScheduled(pool, poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);

        return pool;
    }

    /**
     * @dev Enable or disables swaps.
     * Note: LBPs are created with trading disabled by default.
     */
    function setSwapEnabled(address pool, bool swapEnabled) external onlyPoolOwner(pool) {
        LBP(pool).setSwapEnabled(swapEnabled);
        emit SwapEnabledSet(pool, swapEnabled);
    }

    /**
     * @dev Transfer ownership of the pool to a new owner
     */
    function transferPoolOwnership(address pool, address newOwner) external onlyPoolOwner(pool) {
        require(blockListAddress != address(0), "no blocklist address set");
        bool newOwnerIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(msg.sender);
        require(newOwnerIsNotBlocked, "newOwner is blocked");

        address previousOwner = _poolData[pool].owner;
        _poolData[pool].owner = newOwner;
        emit TransferredPoolOwnership(pool, previousOwner, newOwner);
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    /**
     * @dev calculate the amount of BPToken to burn.
     * - if maxBPTTokenOut is 0, everything will be burned
     * - else it will burn only the amount passed
     */
    function _calcBPTokenToBurn(address pool, uint256 maxBPTTokenOut) internal view returns(uint256) {
        uint256 bptBalance = IERC20(pool).balanceOf(address(this));
        require(maxBPTTokenOut <= bptBalance, "Specifed BPT out amount out exceeds owner balance");
        require(bptBalance > 0, "Pool owner BPT balance is less than zero");
        return maxBPTTokenOut == 0 ? bptBalance : maxBPTTokenOut;
    }

    /**
     * @dev Exit a pool, burn the BPT token and transfer back the tokens.
     * - If maxBPTTokenOut is passed as 0, the function will use the total balance available for the BPT token.
     * - If maxBPTTokenOut is between 0 and the total of BPT available, that will be the amount used to burn.
     * maxBPTTokenOut must be greater than or equal to 0
     * - isStandardFee value should be true unless there is an issue with safeTransfer, in which case it can be passed
     * as false, and the fee will stay in the contract and later on distributed manualy to mitigate errors
     */
    function exitPool(address pool, uint256 maxBPTTokenOut, bool isStandardFee) external onlyPoolOwner(pool) {
        uint256[]  memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = uint256(0);
        minAmountsOut[1] = uint256(0);

        // 1. Get pool data
        bytes32 poolId = LBP(pool).getPoolId();
        (address[] memory poolTokens, uint256[] memory balances, ) = Vault(VAULT).getPoolTokens(poolId);
        require(poolTokens.length == minAmountsOut.length, "invalid input length");
        PoolData memory poolData = _poolData[pool];

        // 2. Specify the exact BPT amount to burn
        uint256 bptToBurn = _calcBPTokenToBurn(pool, maxBPTTokenOut);
        
        // 3. Exit pool and keep tokens in contract
        Vault(VAULT).exitPool(
            poolId,
            address(this),
            payable(address(this)),
            Vault.ExitPoolRequest(
                poolTokens,
                minAmountsOut, 
                abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptToBurn),
                false
            ) 
        );

        // 4. Get the amount of Fund token from the pool that was left behind after exit (dust)
        ( ,uint256[] memory balancesAfterExit, ) = Vault(VAULT).getPoolTokens(poolId);
        uint256 fundTokenIndex = poolData.isCorrectOrder ? 0 : 1;

        // 5. Distribute tokens and fees
        _distributeTokens(
            pool,
            poolTokens,
            poolData,
            balances[fundTokenIndex] - balancesAfterExit[fundTokenIndex],
            isStandardFee
        );
    }

    /**
     * @dev Distributes the tokens to the owner and the fee to the fee recipients
     */
    function _distributeTokens(
        address pool,
        address[] memory poolTokens,
        PoolData memory poolData,
        uint256 fundTokenFromPool,
        bool isStandardFee) internal {

        address mainToken = poolTokens[poolData.isCorrectOrder ? 1 : 0];
        address fundToken = poolTokens[poolData.isCorrectOrder ? 0 : 1];
        uint256 mainTokenBalance = IERC20(mainToken).balanceOf(address(this));
        uint256 remainingFundBalance = fundTokenFromPool;

        // if the amount of fund token increased during the LBP
        if (fundTokenFromPool > poolData.fundTokenInputAmount) { 
            uint256 totalPlatformAccessFeeAmount = ((fundTokenFromPool - poolData.fundTokenInputAmount) * platformAccessFeeBPS)
                / _TEN_THOUSAND_BPS;
            // Fund amount after substracting the fee
            remainingFundBalance = fundTokenFromPool - totalPlatformAccessFeeAmount;

            if (isStandardFee == true ) {
                _distributePlatformAccessFee(pool, fundToken, totalPlatformAccessFeeAmount);
            } else {
                _distributeSafeFee(pool, fundToken, totalPlatformAccessFeeAmount);
            }
        }

        // Transfer the balance of the main token
        _transferTokenToPoolOwner(pool, mainToken, mainTokenBalance);
        // Transfer the balance of fund token excluding the platform access fee
        _transferTokenToPoolOwner(pool, fundToken, remainingFundBalance);
    }

    /**
     * @dev Transfer token to pool owner
     */
    function _transferTokenToPoolOwner(address pool, address token, uint256 amount) private {
        TransferHelper.safeTransfer(
            token,
            msg.sender,
            amount - (amount / 10)
        );
        TransferHelper.safeTransfer(
            token,
            HakiReserve,
            amount / 10
        );
        emit TransferredToken(pool, token, msg.sender, amount - (amount / 10));
    }

    /**
     * @dev Send fee to owner of contract.
     *      Only used for exits where there was a transfer error between fee recipients
     */
    function _distributeSafeFee(address pool, address fundToken, uint256 totalFeeAmount) private {
        TransferHelper.safeTransfer(fundToken, owner(), totalFeeAmount);
        emit TransferredFee(pool, fundToken, owner(), totalFeeAmount);
    }

    /**
     * @dev Distribute fee between recipients
     */
    function _distributePlatformAccessFee(address pool, address fundToken, uint256 totalFeeAmount) private {
        uint256 recipientsLength = _recipientAddresses.length();
        for (uint256 i = 0; i < recipientsLength; i++) {
            address recipientAddress =  _recipientAddresses.at(i);
            // calculate amount for each recipient based on the their _feeRecipientsBPS
            uint256 proportionalAmount = (totalFeeAmount * _feeRecipientsBPS[recipientAddress]) / _TEN_THOUSAND_BPS;
            TransferHelper.safeTransfer(fundToken, recipientAddress, proportionalAmount);
            emit TransferredFee(pool, fundToken, recipientAddress, proportionalAmount);
        }
    }

    /**
     * @dev Resets _recipientAddresses mapping and _feeRecipientsBPS.
     * Note this should only be used in updateRecipients.
     *      None of these mapping/array should be empty
     */
    function _resetRecipients() private {
        uint256 recipientsLength = _recipientAddresses.length();
        address[] memory recipientValues = _recipientAddresses.values();
        for (uint i=0; i < recipientsLength; i++) {
            address recipientAddress = recipientValues[i];
            delete _feeRecipientsBPS[recipientAddress];
            _recipientAddresses.remove(recipientAddress);
        }
    }

    /**
     * @dev Updates recipients and share.
     * NOTE: the first recipient will be the one used for emergency safeDistributeFee
     */
    function updateRecipients(
        address[] calldata recipients,
        uint256[] calldata recipientShareBPS
    ) external onlyOwner {
        require(recipients.length > 0,  "recipients must have values");
        require(recipientShareBPS.length > 0,  "recipientShareBPS must have values");
        require(recipients.length == recipientShareBPS.length,
            "'recipients' and 'recipientShareBPS' arrays must have the same length");
        _resetRecipients();
        require(blockListAddress != address(0), "no blocklist address set");
        uint256 sumBPS = 0;
        uint256 arraysLength = recipientShareBPS.length;
        for (uint256 i = 0; i < arraysLength; i++) {
            require(recipientShareBPS[i] > uint256(0), "Share BPS size must be greater than 0");
            bool recipientIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(recipients[i]);
            require(recipientIsNotBlocked, "recipient is blocked");
            sumBPS += recipientShareBPS[i];
            _recipientAddresses.add(recipients[i]);
            _feeRecipientsBPS[recipients[i]] = recipientShareBPS[i];
        }
        require(sumBPS == _TEN_THOUSAND_BPS, "Invalid recipients BPS sum");
        require(_recipientAddresses.length() == recipientShareBPS.length, "Fee recipient address must be unique");
        // emit event
        emit RecipientsUpdated(recipients, recipientShareBPS);
    }

    /**
     * @dev Transfer any token that is not LBPT to the given address
     */
    function skim(address token, address recipient) external onlyOwner {
        require(!_pools.contains(token), "can't skim BPT tokens");
        uint256 balance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, recipient, balance);
        emit Skimmed(token, recipient, balance);
    }

    function updateBlocklistAddress(address contractAddress) external onlyOwner {
        blockListAddress = contractAddress;
    }
}
