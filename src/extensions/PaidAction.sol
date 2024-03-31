// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC165} from "../../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

import {IPaidAction, IDAO} from "./IPaidAction.sol";

abstract contract PaidAction is ERC165, IPaidAction {
    mapping(IDAO dao => PaidDaoSettings paidSettings) private paidDaoSettings;

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IPaidAction).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @inheritdoc IPaidAction
    function getCost(IDAO _dao) external view returns (uint256 cost) {
        return paidDaoSettings[_dao].cost;
    }

    /// @inheritdoc IPaidAction
    function updateCost(uint256 _cost) external {
        paidDaoSettings[IDAO(msg.sender)].cost = _cost;
    }

    function _ensurePaid(IDAO _dao) internal {
        uint256 cost = paidDaoSettings[_dao].cost;

        // Gas optimization
        if (cost != 0) {
            // Cost is required to create an action. It is sent to the DAO.
            if (msg.value < cost) {
                revert Underpaying();
            }

            // Normal address.transfer does not work with gas estimation
            (bool success,) = address(_dao).call{value: msg.value}("");
            if (!success) {
                revert TransferToDAOFailed();
            }
        }
    }
}
