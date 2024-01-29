// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../lib/forge-std/src/Test.sol";

import {OptimisticActions, IOptimisticActions, IDAO} from "../src/OptimisticActions.sol";
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

    error SenderIsNotAdmin();

    error RequestDoesNotExist();
    error RequestNotExecutableYet();
    error RequestAlreadyExecuted();

    function setUp() external {
        dao = new DAOMock();
        trustlessManagement = new TrustlessManagementMock();
        optimisticActions = new OptimisticActions();

        vm.startPrank(address(dao));
        trustlessManagement.changeFullAccess(dao, role, NO_PERMISSION_CHECKER);
    }

    function test_execution(
        uint256[] calldata _callableIndexes,
        bytes[] calldata _calldatas,
        bytes[] calldata _returnValues,
        uint256 _failureMap
    ) external {
        vm.assume(_calldatas.length >= _callableIndexes.length);
        vm.assume(_returnValues.length >= _callableIndexes.length);
        ActionHelper actionHelper = new ActionHelper(_callableIndexes, _calldatas, _returnValues);
        vm.assume(actionHelper.isValid());

        IDAO.Action[] memory actions = actionHelper.getActions();
        (uint32 id, uint64 executableFrom) =
            optimisticActions.createAction(trustlessManagement, role, actions, _failureMap, "");
        vm.warp(executableFrom);
        bytes[] memory shortendReturnValues = new bytes[](actions.length);
        for (uint256 i; i < shortendReturnValues.length; i++) {
            shortendReturnValues[i] = _returnValues[i];
        }

        (bytes[] memory returnValues, uint256 failureMap) = optimisticActions.executeAction(dao, id);
        assertEq(abi.encode(returnValues), abi.encode(shortendReturnValues));
        assertEq(failureMap, 0); // No failed actions
    }

    function test_rejected() external {
        IDAO.Action[] memory actions = new IDAO.Action[](0);
        (uint32 id, uint64 executableFrom) = optimisticActions.createAction(trustlessManagement, role, actions, 0, "");
        vm.warp(executableFrom);

        optimisticActions.rejectAction(id, "");

        vm.expectRevert(RequestNotExecutableYet.selector); // Based on the current implementation, just to make sure it does not throw an unexpected revert
        optimisticActions.executeAction(dao, id);
    }

    function test_earlyExecution(uint64 early) external {
        IDAO.Action[] memory actions = new IDAO.Action[](0);
        (uint32 id, uint64 executableFrom) = optimisticActions.createAction(trustlessManagement, role, actions, 0, "");
        vm.assume(early <= executableFrom);
        vm.warp(executableFrom - early);

        if (early > 0) {
            vm.expectRevert(RequestNotExecutableYet.selector);
        }
        optimisticActions.executeAction(dao, id);
    }

    function test_doubleExecution() external {
        IDAO.Action[] memory actions = new IDAO.Action[](0);
        (uint32 id, uint64 executableFrom) = optimisticActions.createAction(trustlessManagement, role, actions, 0, "");
        vm.warp(executableFrom);

        optimisticActions.executeAction(dao, id);
        vm.expectRevert(RequestAlreadyExecuted.selector);
        optimisticActions.executeAction(dao, id);
    }

    function test_nonExistent(uint32 id) external {
        vm.expectRevert(RequestDoesNotExist.selector);
        optimisticActions.rejectAction(id, "");

        vm.expectRevert(RequestDoesNotExist.selector);
        optimisticActions.executeAction(dao, id);
    }

    function test_noAdmin(uint64 _executeDelay, address _admin) external {
        vm.stopPrank();

        vm.expectRevert(SenderIsNotAdmin.selector);
        optimisticActions.setExecuteDelay(dao, _executeDelay);

        vm.expectRevert(SenderIsNotAdmin.selector);
        optimisticActions.setAdmin(dao, _admin);
    }

    function test_interfaces() external view {
        assert(optimisticActions.supportsInterface(type(IOptimisticActions).interfaceId));
        // As according to spec: https://eips.ethereum.org/EIPS/eip-165
        assert(optimisticActions.supportsInterface(0x01ffc9a7));
        assert(!optimisticActions.supportsInterface(0xffffffff));
    }
}
