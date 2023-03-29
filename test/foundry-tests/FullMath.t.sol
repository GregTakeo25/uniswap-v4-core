// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {FullMath} from "../../contracts/libraries/FullMath.sol";

contract FullMathTest is Test {
    using FullMath for uint256;

    uint256 constant Q128 = 2 ** 128;
    uint256 constant MAX_UINT256 = type(uint256).max;

    function testMulDivRevertsWithZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert();
        x.mulDiv(y, 0);
    }

    function testMulDivRevertsWithOverflowingNumeratorAndZeroDenominator() public {
        vm.expectRevert();
        Q128.mulDiv(Q128, 0);
    }

    function testMulDivRevertsIfOutputOverflows() public {
        vm.expectRevert();
        Q128.mulDiv(Q128, 1);
    }

    function testMulDivRevertsOverflowWithAllMaxInputs() public {
        vm.expectRevert();
        MAX_UINT256.mulDiv(MAX_UINT256, MAX_UINT256 - 1);
    }

    function testMulDivMaxInputs() public {
        assertEq(MAX_UINT256.mulDiv(MAX_UINT256, MAX_UINT256), MAX_UINT256);
    }

    function testMulDivNoPhantomOverflow() public {
        uint256 result = Q128 / 3;
        assertEq(Q128.mulDiv(50 * Q128 / 100, 150 * Q128 / 100), result);
    }

    function testMulDivPhantomOverflow() public {
        uint256 result = 4375 * Q128 / 1000;
        assertEq(Q128.mulDiv(35 * Q128, 8 * Q128), result);
    }

    function testMulDivPhantomOverflowRepeatingDecimal() public {
        uint256 result = 1 * Q128 / 3;
        assertEq(Q128.mulDiv(1000 * Q128, 3000 * Q128), result);
    }

    function testFuzzMulDiv(uint256 x, uint256 y, uint256 d) public {
        vm.assume(d != 0);
        vm.assume(y != 0);
        vm.assume(x <= type(uint256).max / y);
        assertEq(FullMath.mulDiv(x, y, d), x * y / d);
    }

    function testMulDivRoundingUpRevertsWithZeroDenominator(uint256 x, uint256 y) public {
        vm.expectRevert();
        x.mulDivRoundingUp(y, 0);
    }

    function testMulDivRoundingUpAllMaxInputs() public {
        assertEq(MAX_UINT256.mulDivRoundingUp(MAX_UINT256, MAX_UINT256), MAX_UINT256);
    }

    function testMulDivRoundingUpNoPhantomOverflow() public {
        uint256 result = Q128 / 3 + 1;
        assertEq(Q128.mulDivRoundingUp(50 * Q128 / 100, 150 * Q128 / 100), result);
    }

    function testMulDivRoundingUpPhantomOverflow() public {
        uint256 result = 4375 * Q128 / 1000;
        assertEq(Q128.mulDiv(35 * Q128, 8 * Q128), result);
    }

    function testMulDivRoundingUpPhantomOverflowRepeatingDecimal() public {
        uint256 result = 1 * Q128 / 3 + 1;
        assertEq(Q128.mulDivRoundingUp(1000 * Q128, 3000 * Q128), result);
    }

    function testFuzzMulDivRoundingUp(uint256 x, uint256 y, uint256 d) public {
        vm.assume(d != 0);
        vm.assume(y != 0);
        vm.assume(x <= type(uint256).max / y);
        uint256 numerator = x * y;
        uint256 result = FullMath.mulDivRoundingUp(x, y, d);
        assertTrue(result == numerator / d || result == numerator / d + 1);
    }

    function testMulDivRounding(uint256 x, uint256 y, uint256 d) public {
        unchecked {
            vm.assume(d > 0);
            vm.assume(!resultOverflows(x, y, d));

            uint256 ceiled = FullMath.mulDivRoundingUp(x, y, d);

            uint256 floored = FullMath.mulDiv(x, y, d);

            if (mulmod(x, y, d) > 0) {
                assertEq(ceiled - floored, 1);
            } else {
                assertEq(ceiled, floored);
            }
        }
    }

    function testMulDivRecomputed(uint256 x, uint256 y, uint256 d) public {
        unchecked {
            vm.assume(d > 0);
            vm.assume(!resultOverflows(x, y, d));
            uint256 z = FullMath.mulDiv(x, y, d);
            if (x == 0 || y == 0) {
                assertEq(z, 0);
                return;
            }

            // recompute x and y via mulDiv of the result of floor(x*y/d), should always be less than original inputs by < d
            uint256 x2 = FullMath.mulDiv(z, d, y);
            uint256 y2 = FullMath.mulDiv(z, d, x);
            assertLe(x2, x);
            assertLe(y2, y);

            assertLt(x - x2, d);
            assertLt(y - y2, d);
        }
    }

    function checkMulDivRoundingUp(uint256 x, uint256 y, uint256 d) external {
        unchecked {
            require(d > 0);
            vm.assume(!resultOverflows(x, y, d));
            uint256 z = FullMath.mulDivRoundingUp(x, y, d);
            if (x == 0 || y == 0) {
                assertEq(z, 0);
                return;
            }

            // recompute x and y via mulDiv of the result of floor(x*y/d), should always be less than original inputs by < d
            uint256 x2 = FullMath.mulDiv(z, d, y);
            uint256 y2 = FullMath.mulDiv(z, d, x);
            assertGe(x2, x);
            assertGe(y2, y);

            assertLt(x2 - x, d);
            assertLt(y2 - y, d);
        }
    }

    function testResultOverflowsHelper() public {
        assertFalse(resultOverflows(0, 0, 1));
        assertFalse(resultOverflows(1, 0, 1));
        assertFalse(resultOverflows(0, 1, 1));
        assertFalse(resultOverflows(1, 1, 1));
        assertFalse(resultOverflows(10000000, 10000000, 1));
        assertFalse(resultOverflows(Q128, 50 * Q128 / 100, 150 * Q128 / 100));
        assertFalse(resultOverflows(Q128, 35 * Q128, 8 * Q128));
        assertTrue(resultOverflows(type(uint256).max, type(uint256).max, type(uint256).max - 1));
        assertTrue(resultOverflows(Q128, type(uint256).max, 1));
    }

    function resultOverflows(uint256 x, uint256 y, uint256 d) private pure returns (bool) {
        // If x or y is zero, the result will be zero, and there's no overflow
        if (x == 0 || y == 0) {
            return false;
        }

        if (x <= type(uint256).max / y) return false;

        uint256 remainder = mulmod(x, y, type(uint256).max);
        uint256 small;
        uint256 big;
        unchecked {
            small = x * y;
            big = remainder - small;
        }

        return d <= big;
    }
}
