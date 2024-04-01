// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../lib/forge-std/src/Test.sol";

import {TrustlessActionsMock, IDAO} from "./mocks/TrustlessActionsMock.sol";
import {
    TrustlessManagementMock,
    NO_PERMISSION_CHECKER
} from "../lib/trustless-management/test/mocks/TrustlessManagementMock.sol";
import {DAOMock} from "../lib/trustless-management/test/mocks/DAOMock.sol";
import {ActionHelper} from "../lib/trustless-management/test/helpers/ActionHelper.sol";

contract TrustlessActionsTest is Test {
    DAOMock public dao;
    TrustlessManagementMock public trustlessManagement;
    TrustlessActionsMock public trustlessActions;
    uint256 constant role = 0;

    error RequestDoesNotExist();
    error RequestAlreadyExecuted();

    function setUp() external {
        dao = new DAOMock();
        trustlessManagement = new TrustlessManagementMock();
        trustlessActions = new TrustlessActionsMock();

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
        uint32 id = trustlessActions.createAction(trustlessManagement, role, actions, _failureMap, "");
        bytes[] memory shortendReturnValues = new bytes[](actions.length);
        for (uint256 i; i < shortendReturnValues.length; i++) {
            shortendReturnValues[i] = _returnValues[i];
        }

        (bytes[] memory returnValues, uint256 failureMap) = trustlessActions.executeAction(dao, id);
        assertEq(abi.encode(returnValues), abi.encode(shortendReturnValues));
        assertEq(failureMap, 0); // No failed actions
    }

    function test_doubleExecution() external {
        IDAO.Action[] memory actions = new IDAO.Action[](0);
        uint32 id = trustlessActions.createAction(trustlessManagement, role, actions, 0, "");

        trustlessActions.executeAction(dao, id);
        vm.expectRevert(RequestAlreadyExecuted.selector);
        trustlessActions.executeAction(dao, id);
    }

    function test_nonExistent(uint32 id) external {
        vm.expectRevert(RequestDoesNotExist.selector);
        trustlessActions.executeAction(dao, id);
    }

    function test_interfaces() external view {
        // As according to spec: https://eips.ethereum.org/EIPS/eip-165
        assert(trustlessActions.supportsInterface(0x01ffc9a7));
        assert(!trustlessActions.supportsInterface(0xffffffff));
    }
}
