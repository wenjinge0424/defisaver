pragma solidity ^0.6.0;

import "../maker/ScdMcdMigration.sol";
import "../migration/SaiTubLike.sol";
import "../../interfaces/ITokenInterface.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ERC20.sol";
import "../../constants/ConstantAddresses.sol";

abstract contract SavingsProxyInterface {
    enum SavingsProtocol { Compound, Dydx, Fulcrum, Dsr }

    function deposit(SavingsProtocol _protocol, uint _amount) public virtual;
    function withdraw(SavingsProtocol _protocol, uint _amount) public virtual;
}

contract SavingsMigration is ConstantAddresses {

    address public constant OLD_PROXY_ADDRESS = 0x296420A79fE17B72Eb4749ca26d4E53602f4EDef;
    address public constant NEW_PROXY_ADDRESS = 0x622C283769e08Da806d938EB493cb8C4Cb47E64C;
    ScdMcdMigration public constant scdMcdMigration = ScdMcdMigration(SCD_MCD_MIGRATION);
    ITokenInterface public constant iDai = ITokenInterface(IDAI_ADDRESS);
    CTokenInterface public constant cDai = CTokenInterface(CDAI_ADDRESS);

    function migrateSavings() external {

        uint fulcrumBalance = iDai.assetBalanceOf(address(this));
        uint compoundBalance = cDai.balanceOfUnderlying(address(this));

        if (compoundBalance != 0) {
            DSProxyInterface(address(this)).execute(OLD_PROXY_ADDRESS,
                abi.encodeWithSignature("withdraw(uint8,uint256)", SavingsProxyInterface.SavingsProtocol.Compound, compoundBalance));
        }

        if (fulcrumBalance != 0) {
            DSProxyInterface(address(this)).execute(OLD_PROXY_ADDRESS,
                abi.encodeWithSignature("withdraw(uint8,uint256)", SavingsProxyInterface.SavingsProtocol.Fulcrum, fulcrumBalance));
        }

        uint sumOfSai = compoundBalance + fulcrumBalance;

        Gem sai = SaiTubLike(scdMcdMigration.tub()).sai();
        sai.approve(address(scdMcdMigration), sumOfSai);
        scdMcdMigration.swapSaiToDai(sumOfSai);

        if (compoundBalance != 0) {
            DSProxyInterface(address(this)).execute(NEW_PROXY_ADDRESS,
                abi.encodeWithSignature("deposit(uint8,uint256)", SavingsProxyInterface.SavingsProtocol.Compound, compoundBalance));
        }

        if (fulcrumBalance != 0) {
            DSProxyInterface(address(this)).execute(NEW_PROXY_ADDRESS,
                abi.encodeWithSignature("deposit(uint8,uint256)", SavingsProxyInterface.SavingsProtocol.Fulcrum, fulcrumBalance));
        }
    }

    function withdraw() external {
        uint fulcrumBalance = iDai.assetBalanceOf(address(this));
        uint compoundBalance = cDai.balanceOfUnderlying(address(this));

        if (compoundBalance != 0) {
            DSProxyInterface(address(this)).execute(OLD_PROXY_ADDRESS,
                abi.encodeWithSignature("withdraw(uint8,uint256)", SavingsProxyInterface.SavingsProtocol.Compound, compoundBalance));
        }

        if (fulcrumBalance != 0) {
            DSProxyInterface(address(this)).execute(OLD_PROXY_ADDRESS,
                abi.encodeWithSignature("withdraw(uint8,uint256)", SavingsProxyInterface.SavingsProtocol.Fulcrum, fulcrumBalance));
        }

        ERC20(SAI_ADDRESS).transfer(msg.sender, ERC20(SAI_ADDRESS).balanceOf(address(this)));
    }
}
