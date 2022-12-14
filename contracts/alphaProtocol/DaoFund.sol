pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./../interfaces/ICurrencyReserve.sol";
import "./../Operator.sol";

contract DaoFund is ICurrencyReserve, Operator {
    using SafeERC20 for IERC20;

    address public treasury;
    address public custodian;

    /* ========== MODIFIER ========== */
    modifier onlyTreasuryOrCustodian() {
        require(treasury == msg.sender || custodian == msg.sender, "Only treasury or custodian can trigger this function");
        _;
    }

    modifier onlyCustodian() {
        require(custodian == msg.sender, "!custodian");
        _;
    }

    constructor (address _treasury, address _custodian) public {
        treasury = _treasury;
        custodian = _custodian;
    }

    /* ========== VIEWS ================ */

    function fundBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) public override onlyTreasuryOrCustodian {
        require(_receiver != address(0), "Invalid address");
        require(_amount > 0, "Cannot transfer zero amount");
        IERC20(_token).safeTransfer(_receiver, _amount);
    }

    function setCustodian(address _custodian) public onlyCustodian {
        require(_custodian != address(0), "Invalid address");
        custodian = _custodian;
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyOperator returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, string("DaoFund::executeTransaction: Transaction execution reverted."));
        emit TransactionExecuted(target, value, signature, data);
        return returnData;
    }

    event TransactionExecuted(address indexed target, uint256 value, string signature, bytes data);
}
