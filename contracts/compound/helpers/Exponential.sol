pragma solidity ^0.5.0;

import "./CarefulMath.sol";


contract Exponential is CarefulMath {
    // solhint-disable-next-line const-name-snakecase
    uint256 constant expScale = 1e18;
    // solhint-disable-next-line const-name-snakecase
    uint256 constant halfExpScale = expScale / 2;
    // solhint-disable-next-line const-name-snakecase
    uint256 constant mantissaOne = expScale;

    struct Exp {
        uint256 mantissa;
    }

    function divScalarByExp(uint256 scalar, Exp memory divisor)
        internal
        pure
        returns (MathError, Exp memory)
    {
        (MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor)
        internal
        pure
        returns (MathError, uint256)
    {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    function getExp(uint256 num, uint256 denom) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }
}
