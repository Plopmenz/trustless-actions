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
    error RequestAlreadyExecuted();

    error OptimisticRequestNotExecutableYet();

    function setUp() external {
        dao = new DAOMock();
        trustlessManagement = new TrustlessManagementMock();
        optimisticActions = new OptimisticActions();

        vm.startPrank(address(dao));
        trustlessManagement.changeFullAccess(dao, role, NO_PERMISSION_CHECKER);
    }

    function test_rejected() external {
        IDAO.Action[] memory actions = new IDAO.Action[](0);
        uint32 id = optimisticActions.createAction(trustlessManagement, role, actions, 0, "");

        optimisticActions.rejectAction(id, "");

        vm.expectRevert(OptimisticRequestNotExecutableYet.selector); // Based on the current implementation, just to make sure it does not throw an unexpected revert
        optimisticActions.executeAction(dao, id);
    }

    function test_earlyExecution(uint32 _executeDelay, uint32 _early) external {
        vm.assume(_executeDelay > _early);
        optimisticActions.setExecuteDelay(dao, _executeDelay);

        IDAO.Action[] memory actions = new IDAO.Action[](0);
        uint32 id = optimisticActions.createAction(trustlessManagement, role, actions, 0, "");
        vm.warp(block.timestamp + _executeDelay - _early);

        if (_early > 0) {
            vm.expectRevert(OptimisticRequestNotExecutableYet.selector);
        }
        optimisticActions.executeAction(dao, id);
    }

    function test_noAdmin(uint32 _executeDelay, address _admin) external {
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
