// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITrustlessActions} from "./ITrustlessActions.sol";

interface IPessimisticActions is ITrustlessActions {
    error SenderNotDAO();
}
