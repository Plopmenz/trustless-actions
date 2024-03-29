// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC165} from "../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {ENSReverseClaimable} from "../lib/ens-reverse-claimable/src/ENSReverseClaimable.sol";

import {ITrustlessActions, IDAO, IDAOManager} from "./ITrustlessActions.sol";

abstract contract TrustlessActions is ERC165, ENSReverseClaimable, ITrustlessActions {
    mapping(IDAO dao => ActionRequests requests) private daoRequests;

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(ITrustlessActions).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @inheritdoc ITrustlessActions
    function getAction(IDAO _dao, uint32 _id) external view override returns (ActionRequest memory request) {
        return daoRequests[_dao].getRequest[_id];
    }

    /// @inheritdoc ITrustlessActions
    function createAction(
        IDAOManager _manager,
        uint256 _role,
        IDAO.Action[] calldata _actions,
        uint256 _failureMap,
        string calldata _metadata
    ) public virtual returns (uint32 id) {
        ActionRequests storage requests = daoRequests[IDAO(msg.sender)];
        id = requests.requestCount++;

        ActionRequest storage request = requests.getRequest[id];
        // executed = false (default value)
        request.manager = _manager;
        request.role = _role;
        request.actions = _actions;
        request.failureMap = _failureMap;
        emit ActionCreated(id, IDAO(msg.sender), _manager, _role, _actions, _failureMap, _metadata);
    }

    /// @inheritdoc ITrustlessActions
    function executeAction(IDAO _dao, uint32 _id) external returns (bytes[] memory returnValues, uint256 failureMap) {
        ActionRequest storage request = _ensureRequestNotExecuted(_dao, _id);
        _ensureRequestExecutable(_dao, _id);

        request.executed = true;
        (returnValues, failureMap) = request.manager.asDAO(_dao, request.role, request.actions, request.failureMap);
        emit ActionExecuted(_id, _dao, msg.sender, returnValues, failureMap);
    }

    function _ensureRequestExists(IDAO _dao, uint32 _id) internal view returns (ActionRequest storage request) {
        ActionRequests storage requests = daoRequests[_dao];
        if (_id >= requests.requestCount) {
            revert RequestDoesNotExist();
        }

        request = requests.getRequest[_id];
    }

    function _ensureRequestNotExecuted(IDAO _dao, uint32 _id) internal view returns (ActionRequest storage request) {
        request = _ensureRequestExists(_dao, _id);
        if (request.executed) {
            revert RequestAlreadyExecuted();
        }
    }

    function _ensureRequestExecutable(IDAO _dao, uint32 _id) internal view virtual;
}
