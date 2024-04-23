// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TrustlessActions} from "./TrustlessActions.sol";
import {
    IOptimisticActions, ITrustlessActions, IDAO, IDAOManager, IDAOExtensionWithAdmin
} from "./IOptimisticActions.sol";

contract OptimisticActions is TrustlessActions, IOptimisticActions {
    mapping(IDAO dao => mapping(uint32 id => OptimisticActionRequest optimisticRequests)) private optimisticDaoRequests;
    mapping(IDAO dao => OptimisticDAOSettings settings) private optimisticDaoSettings;

    /// @inheritdoc TrustlessActions
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IOptimisticActions).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @inheritdoc IOptimisticActions
    function getOptimisticAction(IDAO _dao, uint32 _id)
        external
        view
        returns (OptimisticActionRequest memory request)
    {
        return optimisticDaoRequests[_dao][_id];
    }

    /// @inheritdoc TrustlessActions
    function createAction(
        IDAOManager _manager,
        uint256 _role,
        IDAO.Action[] calldata _actions,
        uint256 _failureMap,
        string calldata _metadata
    ) public override(TrustlessActions, ITrustlessActions) returns (uint32 id) {
        id = super.createAction(_manager, _role, _actions, _failureMap, _metadata);

        OptimisticDAOSettings storage settings = optimisticDaoSettings[IDAO(msg.sender)];
        uint64 executableFrom = _toUint64(block.timestamp) + settings.executeDelay;

        OptimisticActionRequest storage request = optimisticDaoRequests[IDAO(msg.sender)][id];
        request.executableFrom = executableFrom;
        emit OptimisticActionCreated(id, IDAO(msg.sender), executableFrom);
    }

    /// @inheritdoc IOptimisticActions
    function rejectAction(uint32 _id, string calldata _metadata) external {
        _ensureRequestNotExecuted(IDAO(msg.sender), _id);

        // Becomes executable in the year 584_554_051_223 (kudos if this smart contract is still used at that time)
        OptimisticActionRequest storage request = optimisticDaoRequests[IDAO(msg.sender)][_id];
        request.executableFrom = type(uint64).max;
        emit OptimisticActionRejected(_id, IDAO(msg.sender), _metadata);
    }

    /// @inheritdoc TrustlessActions
    function _ensureRequestExecutable(IDAO _dao, uint32 _id) internal view override {
        OptimisticActionRequest storage request = optimisticDaoRequests[_dao][_id];
        if (block.timestamp < request.executableFrom) {
            revert OptimisticRequestNotExecutableYet();
        }
    }

    /// @inheritdoc IOptimisticActions
    function setExecuteDelay(IDAO _dao, uint64 _executeDelay) external {
        OptimisticDAOSettings storage settings = optimisticDaoSettings[_dao];
        _ensureSenderIsAdmin(_dao, settings.admin);

        settings.executeDelay = _executeDelay;
        emit OptimisticExecuteDelaySet(_dao, _executeDelay);
    }

    /// @inheritdoc IDAOExtensionWithAdmin
    function setAdmin(IDAO _dao, address _admin) external {
        OptimisticDAOSettings storage settings = optimisticDaoSettings[_dao];
        _ensureSenderIsAdmin(_dao, settings.admin);
        settings.admin = _admin;
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
