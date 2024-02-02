// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ClaimReverseENS} from "../lib/ens-reverse-registrar/src/ClaimReverseENS.sol";

import {IOptimisticActions, IDAO, IDAOManager, IDAOExtensionWithAdmin} from "./IOptimisticActions.sol";

contract OptimisticActions is ERC165, IOptimisticActions {
    mapping(IDAO dao => DAOInfo info) private daoInfo;

    constructor(address _admin, address _reverseRegistrar) ClaimReverseENS(_reverseRegistrar, _admin) {}

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IOptimisticActions).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @inheritdoc IOptimisticActions
    function createAction(
        IDAOManager _manager,
        uint256 _role,
        IDAO.Action[] calldata _actions,
        uint256 _failureMap,
        string calldata _metadata
    ) external returns (uint32 id, uint64 executableFrom) {
        DAOInfo storage info = daoInfo[IDAO(msg.sender)];
        id = info.requestCount++;
        executableFrom = _toUint64(block.timestamp) + info.executeDelay;

        ActionRequest storage request = info.actionRequests[id];
        // executed = false (default value)
        request.executableFrom = executableFrom;
        request.manager = _manager;
        request.role = _role;
        request.actions = _actions;
        request.failureMap = _failureMap;
        emit ActionCreated(id, IDAO(msg.sender), _manager, _role, _actions, _failureMap, _metadata, executableFrom);
    }

    /// @inheritdoc IOptimisticActions
    function rejectAction(uint32 _id, string calldata _metadata) external {
        DAOInfo storage info = daoInfo[IDAO(msg.sender)];
        if (_id >= info.requestCount) {
            revert RequestDoesNotExist();
        }

        // Becomes executable in the year 584_554_051_223 (kudos if this smart contract is still used at that time)
        info.actionRequests[_id].executableFrom = type(uint64).max;
        emit ActionRejected(_id, IDAO(msg.sender), _metadata);
    }

    /// @inheritdoc IOptimisticActions
    function executeAction(IDAO _dao, uint32 _id) external returns (bytes[] memory returnValues, uint256 failureMap) {
        DAOInfo storage info = daoInfo[_dao];
        if (_id >= info.requestCount) {
            revert RequestDoesNotExist();
        }

        ActionRequest storage request = info.actionRequests[_id];
        if (request.executed) {
            revert RequestAlreadyExecuted();
        }
        if (block.timestamp < request.executableFrom) {
            revert RequestNotExecutableYet();
        }

        request.executed = true;
        (returnValues, failureMap) = request.manager.asDAO(_dao, request.role, request.actions, request.failureMap);
        emit ActionExecuted(_id, _dao, msg.sender, returnValues, failureMap);
    }

    /// @inheritdoc IOptimisticActions
    function setExecuteDelay(IDAO _dao, uint64 _executeDelay) external {
        DAOInfo storage info = daoInfo[_dao];
        _ensureSenderIsAdmin(_dao, info.admin);

        info.executeDelay = _executeDelay;
        emit ExecuteDelaySet(_dao, _executeDelay);
    }

    /// @inheritdoc IDAOExtensionWithAdmin
    function setAdmin(IDAO _dao, address _admin) external {
        DAOInfo storage info = daoInfo[_dao];
        _ensureSenderIsAdmin(_dao, info.admin);
        info.admin = _admin;
        emit AdminSet(_dao, _admin);
    }

    function _ensureSenderIsAdmin(IDAO _dao, address _admin) internal view {
        if (_admin == address(0)) {
            // Admin not set means DAO is the admin
            if (msg.sender != address(_dao)) {
                revert SenderIsNotAdmin();
            }
        } else {
            // Specific admin will only be allowed. DAO is not allowed to change permissions. (for example: if it is a SubDAO)
            if (msg.sender != _admin) {
                revert SenderIsNotAdmin();
            }
        }
    }

    error Overflow();

    function _toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert Overflow();
        }
        return uint64(value);
    }
}
