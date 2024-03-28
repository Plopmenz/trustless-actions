// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TrustlessActions, IDAO, IDAOManager} from "./TrustlessActions.sol";
import {IPessimisticActions} from "./IPessimisticActions.sol";

contract PessimisticActions is TrustlessActions, IPessimisticActions {
    /// @inheritdoc TrustlessActions
    function _ensureRequestExecutable(IDAO _dao, uint32) internal view override {
        if (msg.sender != address(_dao)) {
            revert SenderNotDAO();
        }
    }
}
