// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDAO} from "../../lib/trustless-management/src/IDAOManager.sol";

interface IPaidAction {
    error Underpaying();
    error TransferToDAOFailed();

    /// @notice A container for all settings related to a certain DAO.
    /// @param cost How much native currency should be paid to be allowed to create an action.
    struct PaidDaoSettings {
        uint256 cost;
    }

    /// @notice The cost of a certain DAO.
    function getCost(IDAO _dao) external view returns (uint256 cost);

    /// @notice Updates the cost. The sender should be the DAO that wants to update.
    /// @param _cost The new cost.
    function updateCost(uint256 _cost) external;
}
