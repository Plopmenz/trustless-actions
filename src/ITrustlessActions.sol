// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDAOManager, IDAO} from "../lib/trustless-management/src/IDAOManager.sol";

interface ITrustlessActions {
    error RequestDoesNotExist();
    error RequestAlreadyExecuted();

    event ActionCreated(
        uint32 indexed id,
        IDAO indexed dao,
        IDAOManager manager,
        uint256 role,
        IDAO.Action[] actions,
        uint256 failureMap,
        string metadata
    );
    event ActionExecuted(
        uint32 indexed id, IDAO indexed dao, address indexed executor, bytes[] returnValues, uint256 failureMap
    );

    /// @notice A container for multiple requests.
    /// @param requestCount How many proposed actions have been created.
    /// @param getRequest The proposed actions to be executed.
    struct ActionRequests {
        uint32 requestCount;
        mapping(uint32 id => ActionRequest request) getRequest;
    }

    /// @notice A container for all info related to an execute action request.
    /// @param executed If the action has been executed.
    /// @param manager The management contract to use for the execution.
    /// @param role The role to use for the execution.
    /// @param actions The actions to execute.
    /// @param failureMap Which actions are allowed to fail without reverting the transaction.
    struct ActionRequest {
        bool executed;
        IDAOManager manager;
        uint256 role;
        IDAO.Action[] actions;
        uint256 failureMap;
    }

    /// @notice Gets a certain action request.
    /// @param _dao The DAO that has the request.
    /// @param _id The id of the request.
    function getAction(IDAO _dao, uint32 _id) external view returns (ActionRequest memory request);

    /// @notice Creates a request to execute certain actions.
    /// @param _manager The management contract to use for performing the actions.
    /// @param _role The role of the management contract to use for performing the actions.
    /// @param _actions The actions that are proposed to be executed.
    /// @param _failureMap The actions that are allowed to be revert.
    /// @param _metadata Additional info from the creator.
    /// @dev The sender should be the DAO (utilizing a management solution).
    function createAction(
        IDAOManager _manager,
        uint256 _role,
        IDAO.Action[] calldata _actions,
        uint256 _failureMap,
        string calldata _metadata
    ) external returns (uint32 id);

    /// @notice Executes a certain action request.
    /// @param _dao The DAO that has the request.
    /// @param _id The id of the request.
    /// @dev This is only possible if the request has not been executed yet and the conditions of the TrustlessActions implementation are met.
    function executeAction(IDAO _dao, uint32 _id) external returns (bytes[] memory returnValues, uint256 failureMap);
}
