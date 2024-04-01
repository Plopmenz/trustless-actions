// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    SmartAccountTrustlessExecutionLib,
    ISmartAccountTrustlessExecution
} from "../../lib/smart-account/src/modules/trustless-execution/SmartAccountTrustlessExecutionLib.sol";

import {
    ITrustlessManagement,
    IDAO,
    NO_PERMISSION_CHECKER
} from "../../lib/trustless-management/src/TrustlessManagement.sol";

import {ITrustlessActions} from "../ITrustlessActions.sol";
import {IPaidAction} from "../extensions/IPaidAction.sol";

abstract contract SmartAccountPaidActionInstaller {
    /// @notice The smart account module to add execute, which is needed to use trustless management.
    ISmartAccountTrustlessExecution public immutable smartAccountTrustlessExecution;

    /// @notice Address trustless management (for creating and executing trustless actions).
    ITrustlessManagement public immutable addressTrustlessManagement;

    /// @notice The trustless actions implementation.
    ITrustlessActions public immutable trustlessActions;

    /// @notice The paid action contract.
    IPaidAction public immutable paidAction;

    constructor(
        ISmartAccountTrustlessExecution _smartAccountTrustlessExecution,
        ITrustlessManagement _addressTrustlessManagement,
        ITrustlessActions _trustlessActions,
        IPaidAction _paidAction
    ) {
        smartAccountTrustlessExecution = _smartAccountTrustlessExecution;
        addressTrustlessManagement = _addressTrustlessManagement;
        trustlessActions = _trustlessActions;
        paidAction = _paidAction;
    }

    function install(uint256 _cost) public {
        // Install smart account module
        SmartAccountTrustlessExecutionLib.fullInstall(address(smartAccountTrustlessExecution));

        // Enable trustless management (give execute permission).
        SmartAccountTrustlessExecutionLib.setExecutePermission(address(addressTrustlessManagement), true);

        // Set trustless management permissions and optmistic actions delay.
        if (_cost != 0) {
            paidAction.updateCost(_cost);
        }
        addressTrustlessManagement.changeFunctionAccess(
            IDAO(address(this)),
            uint160(address(paidAction)),
            address(trustlessActions),
            trustlessActions.createAction.selector,
            NO_PERMISSION_CHECKER
        );

        grantPermissions();
    }

    function grantPermissions() internal virtual;

    function grantZoneAccess(address _zone) internal {
        addressTrustlessManagement.changeZoneAccess(
            IDAO(address(this)), uint160(address(trustlessActions)), _zone, NO_PERMISSION_CHECKER
        );
    }

    function grantFunctionAccess(address _zone, bytes4 _functionSelector) internal {
        addressTrustlessManagement.changeFunctionAccess(
            IDAO(address(this)), uint160(address(trustlessActions)), _zone, _functionSelector, NO_PERMISSION_CHECKER
        );
    }
}
