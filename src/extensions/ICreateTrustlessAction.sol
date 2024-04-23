// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDAOManager, IDAO} from "../../lib/trustless-management/src/IDAOManager.sol";
import {ITrustlessActions} from "../ITrustlessActions.sol";

interface ICreateTrustlessAction {
    event TrustlessActionCreated(
        IDAO indexed dao, ITrustlessActions indexed trustlessActions, uint256 indexed actionId
    );

    /// @notice A container for all info needed to create a trustless action.
    /// @param manager Management solution used by the DAO (for creating trustless actions).
    /// @param role Role to use to be allowed to create actions.
    /// @param trustlessActions TrustlessActions contract where to create the action.
    struct ManagementInfo {
        IDAOManager manager;
        uint256 role;
        ITrustlessActions trustlessActions;
    }

    /// @notice A container for all info needed to execute a trustless action.
    /// @param manager Management solution used by the DAO (for executing trustless actions).
    /// @param role Role to use to be allowed to execute the trustless action.
    struct TrustlessActionsInfo {
        IDAOManager manager;
        uint256 role;
    }
}
