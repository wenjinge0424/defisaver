pragma solidity ^0.6.0;

import "../../DS/DSMath.sol";

import "../../interfaces/TokenInterface.sol";
import "../maker/DaiJoin.sol";
import "../../interfaces/OtcInterface.sol";

import "../maker/ScdMcdMigration.sol";
import "./SaiTubLike.sol";

// This contract is intended to be executed via the Profile proxy of a user (DSProxy) which owns the SCD CDP
contract PayProxyActions is DSMath {
    function pay(
        address payable scdMcdMigration,    // Migration contract address
        bytes32 cup,                        // SCD CDP Id to migrate
        uint amount                         // Amount of SAI to wipe
    ) public {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(rmul(amount, rdiv(tub.rap(cup), tub.tab(cup))) + 1, val); // 1 extra wei MKR to avoid any possible rounding issue after drawing new SAI

            // Get MKR from the user's wallet
            require(tub.gov().transferFrom(msg.sender, address(this), govFee), "transfer-failed");

            // Approve tub to get SAI
            tub.sai().approve(address(tub), amount);
            // Approve tub to get MKR
            tub.gov().approve(address(tub), govFee);
        }
    }

    function payFeeWithGem(
        address payable scdMcdMigration,    // Migration contract address
        bytes32 cup,                        // SCD CDP Id to migrate
        uint amount,                        // Amount of SAI to wipe
        address otc,                        // Otc address
        address payGem                      // Token address to be used for purchasing govFee MKR
    ) public {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(rmul(amount, rdiv(tub.rap(cup), tub.tab(cup))) + 1, val); // 1 extra wei MKR to avoid any possible rounding issue after drawing new SAI
            // Calculate how much payGem is needed for getting govFee value
            uint payAmt = OtcInterface(otc).getPayAmount(payGem, address(tub.gov()), govFee);
            // Set allowance, if necessary
            if (Gem(payGem).allowance(address(this), otc) < payAmt) {
                Gem(payGem).approve(otc, payAmt);
            }
            // Get payAmt of payGem from user's wallet
            require(Gem(payGem).transferFrom(msg.sender, address(this), payAmt), "transfer-failed");
            // Trade it for govFee amount of MKR
            OtcInterface(otc).buyAllAmount(address(tub.gov()), govFee, payGem, payAmt);

            // Approve tub to get SAI
            tub.sai().approve(address(tub), amount);
            // Approve tub to get MKR
            tub.gov().approve(address(tub), govFee);
        }
    }

    function _getRatio(
        SaiTubLike tub,
        bytes32 cup
    ) internal returns (uint ratio) {
        ratio = rdiv(
                        rmul(tub.tag(), tub.ink(cup)),
                        rmul(tub.vox().par(), tub.tab(cup))
                    );
    }

    function payFeeWithDebt(
        address payable scdMcdMigration,    // Migration contract address
        bytes32 cup,                        // SCD CDP Id to migrate,
        uint amount,                        // Amount of SAI to wipe
        address otc,                        // Otc address
        uint minRatio                       // Min collateralization ratio after generating new debt (e.g. 180% = 1.8 RAY)
    ) public {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(rmul(amount, rdiv(tub.rap(cup), tub.tab(cup))) + 1, val); // 1 extra wei MKR to avoid any possible rounding issue after drawing new SAI
            // Calculate how much SAI is needed for getting govFee value
            uint payAmt = OtcInterface(otc).getPayAmount(address(tub.sai()), address(tub.gov()), govFee);

            // Get payAmt of SAI from user's CDP
            tub.draw(cup, payAmt);

            require(_getRatio(tub, cup) > minRatio, "minRatio-failed");

            // Set allowance, if necessary
            if (Gem(address(tub.sai())).allowance(address(this), otc) < payAmt) {
                Gem(address(tub.sai())).approve(otc, payAmt);
            }
            // Trade it for govFee amount of MKR
            OtcInterface(otc).buyAllAmount(address(tub.gov()), govFee, address(tub.sai()), payAmt);

            // Approve tub to get SAI
            tub.sai().approve(address(tub), amount);
            // Approve tub to get MKR
            tub.gov().approve(address(tub), govFee);
        }
    }
}
