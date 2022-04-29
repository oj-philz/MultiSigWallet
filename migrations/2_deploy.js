var MultiSigWallet = artifacts.require("./contracts/MultiSigWallet");

module.exports = function (deployer) {
  deployer.deploy(MultiSigWallet, 3);
};
