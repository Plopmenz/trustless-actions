// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../lib/forge-std/src/Test.sol";

import {PessimisticActions, IPessimisticActions, IDAO} from "../src/PessimisticActions.sol";
import {
    TrustlessManagementMock,
    NO_PERMISSION_CHECKER
} from "../lib/trustless-management/test/mocks/TrustlessManagementMock.sol";
import {DAOMock} from "../lib/trustless-management/test/mocks/DAOMock.sol";
import {ActionHelper} from "../lib/trustless-management/test/helpers/ActionHelper.sol";

contract PessimisticActionsTest is Test {
    DAOMock public dao;
    TrustlessManagementMock public trustlessManagement;
    PessimisticActions public pessimisticActions;
    uint256 constant role = 0;

    error RequestDoesNotExist();
    error RequestAlreadyExecuted();

    error SenderNotDAO();

    function setUp() external {
        dao = new DAOMock();
        trustlessManagement = new TrustlessManagementMock();
        pessimisticActions = new PessimisticActions();

        vm.startPrank(address(dao));
        trustlessManagement.changeFullAccess(dao, role, NO_PERMISSION_CHECKER);
    }

    function test_notDAO(address _executor) external {
        vm.assume(_executor != address(dao));
        IDAO.Action[] memory actions = new IDAO.Action[](0);
        uint32 id = pessimisticActions.createAction(trustlessManagement, role, actions, 0, "");

        vm.stopPrank();
        vm.prank(_executor);

        vm.expectRevert(SenderNotDAO.selector);
        pessimisticActions.executeAction(dao, id);
    }
}
