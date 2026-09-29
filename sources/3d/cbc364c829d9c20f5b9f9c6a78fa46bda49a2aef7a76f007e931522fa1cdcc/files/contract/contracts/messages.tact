// Shared message and struct definitions for the NFT collection + item contracts.

// Sent by a trusted off-chain signer (holder of AUTHENTICATION_SIGNATURE_PRIVATE_KEY)
// to authorize minting one NFT copy. The collection contract only accepts this if
// `signature` is a valid Ed25519 signature (over sha256 of the other fields) made
// with the public key stored on-chain at deploy time.
message(0x6d696e74) Mint {
    queryId: Int as uint64;
    // Index into metadataIndex.json identifying which NFT "design" is being minted.
    // Several mints can share the same metadataIndex, producing multiple copies of
    // the same artwork/metadata, up to whatever limit the off-chain signer enforces.
    metadataIndex: Int as uint32;
    // Off-chain URL (TEP-64 style) with the metadata json for this specific NFT copy.
    contentUrl: String;
    newOwner: Address;
    validUntil: Int as uint32;
    signature: Slice;
}

// Sent by the collection owner to pull the accumulated TON balance (mint
// proceeds minus what was forwarded to NftItem deploys) out of the
// collection contract. The collection only accepts this from `self.owner`;
// see the `receive(msg: Withdraw)` handler in nft_collection.tact.
message(0x77697468) Withdraw {
    queryId: Int as uint64;
}

// Sent by the collection owner to change the TEP-66 royalty numerator (the
// denominator is fixed at 1000, so 200 = 20%). The collection only accepts this
// from `self.owner` and rejects values above the denominator; see the
// `receive(msg: ChangeRoyalty)` handler in nft_collection.tact.
message(0x726f7961) ChangeRoyalty {
    queryId: Int as uint64;
    numerator: Int as uint16;
}

// ---------------------------------------------------------------------------
// Owner-only administration of the collection (all rejected for other senders)
// ---------------------------------------------------------------------------

// Getgems-standard "change owner" (opcode 3, same as nft-collection-editable).
message(3) ChangeOwner {
    queryId: Int as uint64;
    newOwner: Address;
}

// Getgems-standard "edit content" (opcode 4, the message sent by the Getgems edit
// button). `content` is a cell with TWO references, exactly the layout Getgems uses:
//   ref 0: collection content (TEP-64 off-chain cell: tag 0x01 + URL of the collection JSON)
//   ref 1: common content (raw URL prefix, no tag) prepended to every item's own content
// It also updates the royalty (numerator / denominator / destination) in one go.
message(4) EditContent {
    queryId: Int as uint64;
    content: Cell;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

// One-message update of the collection JSON URL and of the commonContentUrl.
// Name, description, avatar and cover live inside the collection JSON, so
// changing its URL changes all of them.
message(0x63636f6e) ChangeCollectionContent {
    queryId: Int as uint64;
    collectionContentUrl: String;
    commonContentUrl: String;
}

// Changes the (informational) URL of metadataIndex.json stored in the contract.
message(0x6d646978) ChangeMetadataIndexUrl {
    queryId: Int as uint64;
    metadataIndexUrl: String;
}

// Rotates the Ed25519 public key that authorizes minting (the backend must then
// use the matching AUTHENTICATION_SIGNATURE_PRIVATE_KEY).
message(0x61757468) ChangeAuthPublicKey {
    queryId: Int as uint64;
    authPublicKey: Int as uint256;
}

// Changes only the royalty recipient (numerator/denominator are unchanged).
message(0x726f7964) ChangeRoyaltyDestination {
    queryId: Int as uint64;
    destination: Address;
}

// Owner -> collection: replace the individual content (metadata URL) of an
// already minted item. The collection forwards it to the item as `ItemEditContent`.
// This NEVER changes the item's owner: the collection owner still cannot transfer it.
message(0x65646974) EditItemContent {
    queryId: Int as uint64;
    itemIndex: Int as uint256;
    itemContentUrl: String;
}

// Collection -> item only. The item rejects it from any other sender.
message(0x69656469) ItemEditContent {
    queryId: Int as uint64;
    content: Cell;
    responseDestination: Address;
}

// Sent once, by the collection contract only, right after an NftItem child is deployed,
// to set its real owner and content (the child's address only depends on its index and
// the collection address, not on owner/content, so this must happen post-deploy).
message(0x696e6974) Initialize {
    owner: Address;
    content: Cell;
}

// TEP-62 standard transfer.
message(0x5fcc3d14) Transfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address;
    customPayload: Cell? = null;
    forwardAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining;
}

message(0xd53276db) Excesses {
    queryId: Int as uint64;
}

message(0x2fcb26a2) GetStaticData {
    queryId: Int as uint64;
}

message(0x8b771735) ReportStaticData {
    queryId: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

message(0x693d3950) GetRoyaltyParams {
    queryId: Int as uint64;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    queryId: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}
