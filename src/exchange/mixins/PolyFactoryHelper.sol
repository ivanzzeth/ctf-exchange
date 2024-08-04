// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { PolySafeLib } from "../libraries/PolySafeLib.sol";
import { PolyProxyLib } from "../libraries/PolyProxyLib.sol";

interface IPolyProxyFactory {
    function getImplementation() external view returns (address);
}

interface IPolySafeFactory {
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function masterCopy() external view returns (address);

    // For https://basescan.org/address/0xC22834581EbC8527d974F8a1c97E1bEA4EF910BC
    function createProxy(address singleton, bytes memory data) external returns (address proxy);

    // For https://polygonscan.com/address/0xaacfeea03eb1561c4e67d661e40682bd20e3541b#code
    function createProxy(
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver,
        Sig calldata createSig
    ) external;
}

interface IGnosisSafe {
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

abstract contract PolyFactoryHelper {
    /// @notice The Polymarket Proxy Wallet Factory Contract
    address public proxyFactory;
    /// @notice The Polymarket Gnosis Safe Factory Contract
    address public safeFactory;

    event ProxyFactoryUpdated(address indexed oldProxyFactory, address indexed newProxyFactory);

    event SafeFactoryUpdated(address indexed oldSafeFactory, address indexed newSafeFactory);

    constructor(address _proxyFactory, address _safeFactory) {
        proxyFactory = _proxyFactory;
        safeFactory = _safeFactory;
    }

    /// @notice Gets the Proxy factory address
    function getProxyFactory() public view returns (address) {
        return proxyFactory;
    }

    /// @notice Gets the Safe factory address
    function getSafeFactory() public view returns (address) {
        return safeFactory;
    }

    /// @notice Gets the Polymarket Proxy factory implementation address
    function getPolyProxyFactoryImplementation() public view returns (address) {
        return IPolyProxyFactory(proxyFactory).getImplementation();
    }

    /// @notice Gets the Safe factory implementation address
    function getSafeFactoryImplementation() public view returns (address) {
        return IPolySafeFactory(safeFactory).masterCopy();
    }

    /// @notice Gets the Polymarket proxy wallet address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getPolyProxyWalletAddress(address _addr) public view returns (address) {
        return PolyProxyLib.getProxyWalletAddress(_addr, getPolyProxyFactoryImplementation(), proxyFactory);
    }

    /// @notice Gets the Polymarket Gnosis Safe address for an address
    /// @param _addr    - The address that owns the proxy wallet
    function getSafeAddress(address _addr) public view returns (address) {
        return PolySafeLib.getSafeAddress(_addr, getSafeFactoryImplementation(), safeFactory);
    }

    function checkSafeSignatures(
        address safeAddress,
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view returns(bool) {
        try IGnosisSafe(safeAddress).checkSignatures(dataHash, data, signatures) {
            return true;
        } catch {
            return false;
        }
    }

    function _setProxyFactory(address _proxyFactory) internal {
        emit ProxyFactoryUpdated(proxyFactory, _proxyFactory);
        proxyFactory = _proxyFactory;
    }

    function _setSafeFactory(address _safeFactory) internal {
        emit SafeFactoryUpdated(safeFactory, _safeFactory);
        safeFactory = _safeFactory;
    }
}
