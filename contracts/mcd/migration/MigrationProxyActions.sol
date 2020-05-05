pragma solidity ^0.6.0;

import "../../DS/DSMath.sol";

import "../../interfaces/TokenInterface.sol";
import "../maker/DaiJoin.sol";
import "../../interfaces/OtcInterface.sol";

import "../maker/ScdMcdMigration.sol";
import "./SaiTubLike.sol";

// This contract is intended to be executed via the Profile proxy of a user (DSProxy) which owns the SCD CDP
contract MigrationProxyActions is DSMath {
    function swapSaiToDai(
        address payable scdMcdMigration,    // Migration contract address
        uint wad                           // Amount to swap
    ) external {
        Gem sai = SaiTubLike(ScdMcdMigration(scdMcdMigration).tub()).sai();
        Gem dai = DaiJoin(ScdMcdMigration(scdMcdMigration).daiJoin()).dai();

        sai.transferFrom(msg.sender, address(this), wad);

        if (sai.allowance(address(this), scdMcdMigration) < wad) {
            sai.approve(scdMcdMigration, wad);
        }

        ScdMcdMigration(scdMcdMigration).swapSaiToDai(wad);
        dai.transfer(msg.sender, wad);
    }

    function swapDaiToSai(
        address payable scdMcdMigration,    // Migration contract address
        uint wad                            // Amount to swap
    ) external {
        Gem sai = SaiTubLike(ScdMcdMigration(scdMcdMigration).tub()).sai();
        Gem dai = DaiJoin(ScdMcdMigration(scdMcdMigration).daiJoin()).dai();

        dai.transferFrom(msg.sender, address(this), wad);

        if (dai.allowance(address(this), scdMcdMigration) < wad) {
            dai.approve(scdMcdMigration, wad);
        }

        ScdMcdMigration(scdMcdMigration).swapDaiToSai(wad);
        sai.transfer(msg.sender, wad);
    }

    function migrate(
        address payable scdMcdMigration,    // Migration contract address
        bytes32 cup                         // SCD CDP Id to migrate
    ) public returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(tub.rap(cup), val);

            // Get MKR from the user's wallet and transfer to Migration contract
            require(tub.gov().transferFrom(msg.sender, address(scdMcdMigration), govFee), "transfer-failed");
        }
        // Transfer ownership of SCD CDP to the migration contract
        tub.give(cup, address(scdMcdMigration));
        // Execute migrate function
        cdp = ScdMcdMigration(scdMcdMigration).migrate(cup);
    }

    function migratePayFeeWithGem(
        address payable scdMcdMigration,    // Migration contract address
        bytes32 cup,                        // SCD CDP Id to migrate
        address otc,                        // Otc address
        address payGem,                     // Token address to be used for purchasing govFee MKR
        uint maxPayAmt                      // Max amount of payGem to sell for govFee MKR needed
    ) public returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(tub.rap(cup), val);

            // Calculate how much payGem is needed for getting govFee value
            uint payAmt = OtcInterface(otc).getPayAmount(payGem, address(tub.gov()), govFee);
            // Fails if exceeds maximum
            require(maxPayAmt >= payAmt, "maxPayAmt-exceeded");
            // Set allowance, if necessary
            if (Gem(payGem).allowance(address(this), otc) < payAmt) {
                Gem(payGem).approve(otc, payAmt);
            }
            // Get payAmt of payGem from user's wallet
            require(Gem(payGem).transferFrom(msg.sender, address(this), payAmt), "transfer-failed");
            // Trade it for govFee amount of MKR
            OtcInterface(otc).buyAllAmount(address(tub.gov()), govFee, payGem, payAmt);
            // Transfer govFee amount of MKR to Migration contract
            require(tub.gov().transfer(address(scdMcdMigration), govFee), "transfer-failed");
        }
        // Transfer ownership of SCD CDP to the migration contract
        tub.give(cup, address(scdMcdMigration));
        // Execute migrate function
        cdp = ScdMcdMigration(scdMcdMigration).migrate(cup);
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

    function migratePayFeeWithDebt(
        address payable scdMcdMigration,    // Migration contract address
        bytes32 cup,                        // SCD CDP Id to migrate
        address otc,                        // Otc address
        uint maxPayAmt,                     // Max amount of SAI to generate to sell for govFee MKR needed
        uint minRatio                       // Min collateralization ratio after generating new debt (e.g. 180% = 1.8 RAY)
    ) public returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(tub.rap(cup), val) + 1; // 1 extra wei MKR to avoid any possible rounding issue after drawing new SAI

            // Calculate how much SAI is needed for getting govFee value
            uint payAmt = OtcInterface(otc).getPayAmount(address(tub.sai()), address(tub.gov()), govFee);
            // Fails if exceeds maximum
            require(maxPayAmt >= payAmt, "maxPayAmt-exceeded");
            // Get payAmt of SAI from user's CDP
            tub.draw(cup, payAmt);

            require(_getRatio(tub, cup) > minRatio, "minRatio-failed");

            // Set allowance, if necessary
            if (Gem(address(tub.sai())).allowance(address(this), otc) < payAmt) {
                Gem(address(tub.sai())).approve(otc, payAmt);
            }
            // Trade it for govFee amount of MKR
            OtcInterface(otc).buyAllAmount(address(tub.gov()), govFee, address(tub.sai()), payAmt);
            // Transfer real needed govFee amount of MKR to Migration contract (it might leave some MKR dust in the proxy contract)
            govFee = wdiv(tub.rap(cup), val);
            require(tub.gov().transfer(address(scdMcdMigration), govFee), "transfer-failed");
        }
        // Transfer ownership of SCD CDP to the migration contract
        tub.give(cup, address(scdMcdMigration));
        // Execute migrate function
        cdp = ScdMcdMigration(scdMcdMigration).migrate(cup);
    }
}
