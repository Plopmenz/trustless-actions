// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC165} from "../../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

import {ICreateTrustlessAction, IDAO} from "./ICreateTrustlessAction.sol";

abstract contract CreateTrustlessAction is ICreateTrustlessAction {
    function _createAction(
        IDAO _dao,
        string calldata _metadata,
        ManagementInfo calldata _managementInfo,
        TrustlessActionsInfo calldata _trustlessActionsInfo,
        IDAO.Action[] memory _actions
    ) internal returns (uint256 actionId) {
        IDAO.Action[] memory createAction = new IDAO.Action[](1);
        createAction[0] = IDAO.Action(
            address(_managementInfo.trustlessActions),
            0,
            abi.encodeWithSelector(
                _managementInfo.trustlessActions.createAction.selector,
                _trustlessActionsInfo.manager,
                _trustlessActionsInfo.role,
                _actions,
                0, // Failure map
                _metadata
            )
        );

        (bytes[] memory returnValues,) = _managementInfo.manager.asDAO(_dao, _managementInfo.role, createAction, 0);
        (actionId) = abi.decode(returnValues[0], (uint256));
        emit TrustlessActionCreated(_dao, _managementInfo.trustlessActions, actionId);
    }
}
