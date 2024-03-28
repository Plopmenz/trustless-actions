// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDAOExtensionWithAdmin} from "../lib/trustless-management/src/IDAOExtensionWithAdmin.sol";
import {ITrustlessActions, IDAOManager, IDAO} from "./ITrustlessActions.sol";

interface IOptimisticActions is ITrustlessActions, IDAOExtensionWithAdmin {
    error OptimisticRequestNotExecutableYet();

    event OptimisticActionCreated(uint32 indexed id, IDAO indexed dao, uint64 executableFrom);
    event OptimisticActionRejected(uint32 indexed id, IDAO indexed dao, string metadata);
    event OptimisticExecuteDelaySet(IDAO indexed dao, uint64 executeDelay);

    /// @notice A container for all optimistic settings related to a certain DAO.
    /// @param admin The address that can change the settings for this DAO. Default address(0) means the DAO itself.
    /// @param executeDelay How long actions need to wait before they become executable (if not rejected before).
    struct OptimisticDAOSettings {
        address admin;
        uint64 executeDelay;
    }

    /// @notice A container for all info related to an optimistic execute action request.
    /// @param executableFrom From what block time the request becomes executable.
    struct OptimisticActionRequest {
        uint64 executableFrom;
    }

    /// @notice Rejects a certain action request. The sender should be the DAO (utilizing a management solution).
    /// @param _id The id of the request.
    /// @param _metadata Additional info from the rejector.
    function rejectAction(uint32 _id, string calldata _metadata) external;

    /// @notice Changes the execute delay of a DAO.
    /// @param _dao The DAO to change the settings of.
    /// @param _executeDelay The new execute delay.
    /// @dev By default this value is 0, meaning there is no delay. This is likely not desired so you are recommened to set the delay before granting this contract any permissions.
    function setExecuteDelay(IDAO _dao, uint64 _executeDelay) external;
}
