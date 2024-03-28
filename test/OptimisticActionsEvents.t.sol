// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../lib/forge-std/src/Test.sol";

import {OptimisticActions, IOptimisticActions, IDAO, IDAOExtensionWithAdmin} from "../src/OptimisticActions.sol";
import {
    TrustlessManagementMock,
    NO_PERMISSION_CHECKER
} from "../lib/trustless-management/test/mocks/TrustlessManagementMock.sol";
import {DAOMock} from "../lib/trustless-management/test/mocks/DAOMock.sol";
import {ActionHelper} from "../lib/trustless-management/test/helpers/ActionHelper.sol";

contract OptimisticActionsTest is Test {
    DAOMock public dao;
    TrustlessManagementMock public trustlessManagement;
    OptimisticActions public optimisticActions;
    uint256 constant role = 0;

    function setUp() external {
        dao = new DAOMock();
        trustlessManagement = new TrustlessManagementMock();
        optimisticActions = new OptimisticActions();

        vm.startPrank(address(dao));
        trustlessManagement.changeFullAccess(dao, role, NO_PERMISSION_CHECKER);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_createAction(
        IDAO.Action[] calldata _actions,
        uint256 _failureMap,
        string calldata _metadata,
        uint32 _executeDelay
    ) external {
        optimisticActions.setExecuteDelay(dao, _executeDelay);
        vm.expectEmit(address(optimisticActions));
        // This has assumption that the executionDelay is 0
        emit IOptimisticActions.OptimisticActionCreated(0, dao, uint64(block.timestamp) + _executeDelay);
        optimisticActions.createAction(trustlessManagement, role, _actions, _failureMap, _metadata);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_rejectAction(string calldata _metadata) external {
        IDAO.Action[] memory actions = new IDAO.Action[](0);
        uint32 id = optimisticActions.createAction(trustlessManagement, role, actions, 0, _metadata);

        vm.expectEmit(address(optimisticActions));
        emit IOptimisticActions.OptimisticActionRejected(id, dao, _metadata);
        optimisticActions.rejectAction(id, _metadata);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_setExecuteDelay(uint64 _executeDelay) external {
        vm.expectEmit(address(optimisticActions));
        emit IOptimisticActions.OptimisticExecuteDelaySet(dao, _executeDelay);
        optimisticActions.setExecuteDelay(dao, _executeDelay);
    }

    /// forge-config: default.fuzz.runs = 10
    function test_setAdmin(address _admin) external {
        vm.expectEmit(address(optimisticActions));
        emit IDAOExtensionWithAdmin.AdminSet(dao, _admin);
        optimisticActions.setAdmin(dao, _admin);
    }
}
