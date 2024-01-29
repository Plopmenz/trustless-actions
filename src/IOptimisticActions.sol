// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDAOExtensionWithAdmin, IDAO} from "../lib/trustless-management/src/IDAOExtensionWithAdmin.sol";
import {IDAOManager} from "../lib/trustless-management/src/IDAOManager.sol";

interface IOptimisticActions is IDAOExtensionWithAdmin {
    error RequestDoesNotExist();
    error RequestNotExecutableYet();
    error RequestAlreadyExecuted();

    event ActionCreated(
        uint32 indexed id,
        IDAO indexed dao,
        IDAOManager manager,
        uint256 role,
        IDAO.Action[] actions,
        uint256 failureMap,
        string metadata,
        uint64 executableFrom
    );
    event ActionRejected(uint32 indexed id, IDAO indexed dao, string metadata);
    event ActionExecuted(
        uint32 indexed id, IDAO indexed dao, address indexed executor, bytes[] returnValues, uint256 failureMap
    );

    event ExecuteDelaySet(IDAO indexed dao, uint64 executeDelay);

    /// @notice A container for all info related to a certain DAO.
    /// @param admin The address that can change the settings for this DAO. Default address(0) means the DAO itself.
    /// @param executeDelay How long actions need to wait before they become executable (if not rejected before).
    /// @param requestCount How many proposed actions have been created.
    /// @param actionRequests The proposed actions to be executed.
    struct DAOInfo {
        address admin;
        uint64 executeDelay;
        uint32 requestCount;
        mapping(uint32 id => ActionRequest request) actionRequests;
    }

    /// @notice A container for all info related to an execute action request.
    /// @param executed If the action has been executed.
    /// @param executableFrom From what block time the request becomes executable.
    /// @param manager The management contract to use for the execution.
    /// @param role The role to use for the execution.
    /// @param actions The actions to execute.
    /// @param failureMap Which actions are allowed to fail without reverting the transaction.
    struct ActionRequest {
        bool executed;
        uint64 executableFrom;
        IDAOManager manager;
        uint256 role;
        IDAO.Action[] actions;
        uint256 failureMap;
    }

    /// @notice Creates a request to execute certain actions. The sender should be the DAO (utilizing a management solution).
    /// @param _manager The management contract to use for performing the actions.
    /// @param _role The role of the management contract to use for performing the actions.
    /// @param _actions The actions that are proposed to be executed.
    /// @param _failureMap The actions that are allowed to be revert.
    /// @param _metadata Additional info from the creator.
    function createAction(
        IDAOManager _manager,
        uint256 _role,
        IDAO.Action[] calldata _actions,
        uint256 _failureMap,
        string calldata _metadata
    ) external returns (uint32 id, uint64 executableFrom);

    /// @notice Rejects a certain action request. The sender should be the DAO (utilizing a management solution).
    /// @param _id The id of the request.
    /// @param _metadata Additional info from the rejector.
    function rejectAction(uint32 _id, string calldata _metadata) external;

    /// @notice Executes a certain action request.
    /// @param _dao The DAO that has the request.
    /// @param _id The id of the request.
    /// @dev This is only possible if the request has not been executed yet and the block time is past the executableFrom date.
    function executeAction(IDAO _dao, uint32 _id) external returns (bytes[] memory returnValues, uint256 failureMap);

    /// @notice Changes the execute delay of a DAO.
    /// @param _dao The DAO to change the settings of.
    /// @param _executeDelay The new execute delay.
    /// @dev By default this value is 0, meaning there is no delay. This is likely not desired so you are recommened to set the delay before granting this contract any permissions.
    function setExecuteDelay(IDAO _dao, uint64 _executeDelay) external;
}
