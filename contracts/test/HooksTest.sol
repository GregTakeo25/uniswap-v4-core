// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
import {Hooks} from '../libraries/Hooks.sol';
import {IHooks} from '../interfaces/IHooks.sol';

contract HooksTest {
    using Hooks for IHooks;

    function validateHookAddress(address hookAddress, Hooks.Calls calldata params) external pure {
        IHooks(hookAddress).validateHookAddress(params);
    }

    function shouldCallBeforeInitialize(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.BeforeInitialize);
    }

    function shouldCallAfterInitialize(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.AfterInitialize);
    }

    function shouldCallBeforeSwap(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.BeforeSwap);
    }

    function shouldCallAfterSwap(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.AfterSwap);
    }

    function shouldCallBeforeModifyPosition(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.BeforeModifyPosition);
    }

    function shouldCallAfterModifyPosition(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.AfterModifyPosition);
    }

    function shouldCallBeforeDonate(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.BeforeDonate);
    }

    function shouldCallAfterDonate(address hookAddress) external pure returns (bool) {
        return IHooks(hookAddress).shouldCall(Hooks.CallPoint.AfterDonate);
    }

    function getGasCostOfShouldCall(address hookAddress) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        IHooks(hookAddress).shouldCall(Hooks.CallPoint.BeforeSwap);
        return gasBefore - gasleft();
    }

    function getGasCostOfValidateHookAddress(address hookAddress, Hooks.Calls calldata params)
        external
        view
        returns (uint256)
    {
        uint256 gasBefore = gasleft();
        IHooks(hookAddress).validateHookAddress(params);
        return gasBefore - gasleft();
    }
}
