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

    /// @notice Installs Trustless Exeuction module in the smart account, grants the address trustless management permission and performs the permissionsInstall.
    /// @param _cost How much native currency someone has to pay to perform the paid action.
    function fullInstall(uint256 _cost) public virtual {
        // Install smart account module
        SmartAccountTrustlessExecutionLib.fullInstall(address(smartAccountTrustlessExecution));

        // Enable trustless management (give execute permission).
        SmartAccountTrustlessExecutionLib.setExecutePermission(address(addressTrustlessManagement), true);

        permissionsInstall(_cost);
    }

    /// @notice If Trustless Execution module is already installed and address trustless management is enabled, this will skip those installation steps.
    /// @param _cost How much native currency someone has to pay to perform the paid action.
    function permissionsInstall(uint256 _cost) public virtual {
        // Grants trustless management permissions and cost.
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

    /// @notice Uninstalls Trustless Exeuction module in the smart account, revokes the address trustless management permission and performs the permissionsUninstall.
    function fullUninstall() public virtual {
        // Install smart account module
        SmartAccountTrustlessExecutionLib.fullUninstall();

        // Enable trustless management (give execute permission).
        SmartAccountTrustlessExecutionLib.setExecutePermission(address(addressTrustlessManagement), false);

        permissionsUninstall();
    }

    /// @notice If Trustless Execution module is already installed and address trustless management is enabled, this will skip those installation steps.
    function permissionsUninstall() public virtual {
        // Revokes trustless management permissions
        // Cost is not updated, as the contract itself cannot create action anymore anyhow, it will be overwritten on the next install
        addressTrustlessManagement.changeFunctionAccess(
            IDAO(address(this)),
            uint160(address(paidAction)),
            address(trustlessActions),
            trustlessActions.createAction.selector,
            address(0)
        );

        revokePermissions();
    }

    function grantPermissions() internal virtual;

    function revokePermissions() internal virtual;

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

    function revokeZoneAccess(address _zone) internal {
        addressTrustlessManagement.changeZoneAccess(
            IDAO(address(this)), uint160(address(trustlessActions)), _zone, address(0)
        );
    }

    function revokeFunctionAccess(address _zone, bytes4 _functionSelector) internal {
        addressTrustlessManagement.changeFunctionAccess(
            IDAO(address(this)), uint160(address(trustlessActions)), _zone, _functionSelector, address(0)
        );
    }
}
