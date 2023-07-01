// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}


contract L1Gateway is Ownable {
    IStarknetCore starknetCore;
    uint256 private CLAIM_SELECTOR;
    uint256 private starknetEndAddress;

    constructor(
        address starknetCore_
    ) public {
        starknetCore = IStarknetCore(starknetCore_);
    }

    // ADMIN

    function setClaimSelector(uint256 _claimSelector) external onlyOwner {
        CLAIM_SELECTOR = _claimSelector;
    }

    function setStarknetEndAddress(uint256 _starknetEndAddress)
        external
        onlyOwner
    {
        starknetEndAddress = _starknetEndAddress;
    }

    // EXTERNAL

    function bridgeToL2(
        uint256 _l2_account,
        uint16[] memory _anima_ids
    ) public {
        // CAN SEND A MAX OF 7
        require(_anima_ids.length < 7, "BRIDGE LIMIT EXCEEDED");
        // BUILD PAYLOAD
        uint256[] memory payload = new uint256[](2);
        
        payload[0] = uint256(_l2_account);
        payload[1] = uint256(packArray(_anima_ids));

        // SEND PAYLOAD
        starknetCore.sendMessageToL2(
            starknetEndAddress,
            CLAIM_SELECTOR,
            payload
        );
    }

    // INTERNAL
    
    function packArray(uint16[] memory _array) public returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            result = (uint256(_array[i]) << (i * 16)) | result;
        }
        return (result);
    }
}
