// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TrustlessActions, IDAO} from "../../src/TrustlessActions.sol";

contract TrustlessActionsMock is TrustlessActions {
    /// @inheritdoc TrustlessActions
    function _ensureRequestExecutable(IDAO _dao, uint32) internal view override {}
}
