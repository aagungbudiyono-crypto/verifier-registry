// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct (0x77697468) NftCollectionWithdraw {
    queryId: uint64
}

struct (0x726f7961) NftCollectionChangeRoyalty {
    queryId: uint64
    numerator: uint16
}

struct (0x00000003) NftCollectionChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x00000004) NftCollectionEditContent {
    queryId: uint64
    content: cell
    numerator: uint16
    denominator: uint16
    destination: address
}

struct (0x63636f6e) NftCollectionChangeCollectionContent {
    queryId: uint64
    collectionContentUrl: string
    commonContentUrl: string
}

struct (0x6d646978) NftCollectionChangeMetadataIndexUrl {
    queryId: uint64
    metadataIndexUrl: string
}

struct (0x61757468) NftCollectionChangeAuthPublicKey {
    queryId: uint64
    authPublicKey: uint256
}

struct (0x726f7964) NftCollectionChangeRoyaltyDestination {
    queryId: uint64
    destination: address
}

struct (0x65646974) NftCollectionEditItemContent {
    queryId: uint64
    itemIndex: uint256
    itemContentUrl: string
}

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    queryId: uint64
}

struct NftCollectionCollectionData {
    nextItemIndex: int257
    collectionContent: cell
    ownerAddress: address
}

struct NftCollectionRoyaltyParams {
    numerator: int257
    denominator: int257
    destination: address
}

struct NftCollectionData {
    tactSystemCell: cell
    tactDeploymentCompleted: bool
    owner: address
    nextItemIndex: uint256
    content: cell
    tactContinuation: Cell<NftCollectionDataContinuation>
}

struct NftCollectionDataContinuation {
    metadataIndexUrl: string
    royaltyDestination: address
    authPublicKey: uint256
    mintedPerMetadataIndex: map<int257, int257>
    royaltyNumerator: uint16
    royaltyDenominator: uint16
}

type NftCollectionIncomingMessage =
    | NftCollectionWithdraw
    | NftCollectionChangeOwner
    | NftCollectionEditContent
    | NftCollectionChangeCollectionContent
    | NftCollectionChangeMetadataIndexUrl
    | NftCollectionChangeAuthPublicKey
    | NftCollectionChangeRoyalty
    | NftCollectionChangeRoyaltyDestination
    | NftCollectionEditItemContent
    | NftCollectionGetRoyaltyParams

enum NftCollectionErrors {
    /// Stack underflow
    StackUnderflow = 2
    /// Stack overflow
    StackOverflow = 3
    /// Integer overflow
    IntegerOverflow = 4
    /// Integer out of expected range
    IntegerOutOfExpectedRange = 5
    /// Invalid opcode
    InvalidOpcode = 6
    /// Type check error
    TypeCheckError = 7
    /// Cell overflow
    CellOverflow = 8
    /// Cell underflow
    CellUnderflow = 9
    /// Dictionary error
    DictionaryError = 10
    /// 'Unknown' error
    UnknownError = 11
    /// Fatal error
    FatalError = 12
    /// Out of gas error
    OutOfGasError = 13
    /// Virtualization error
    VirtualizationError = 14
    /// Action list is invalid
    ActionListIsInvalid = 32
    /// Action list is too long
    ActionListIsTooLong = 33
    /// Action is invalid or not supported
    ActionIsInvalidOrNotSupported = 34
    /// Invalid source address in outbound message
    InvalidSourceAddressInOutboundMessage = 35
    /// Invalid destination address in outbound message
    InvalidDestinationAddressInOutboundMessage = 36
    /// Not enough Toncoin
    NotEnoughToncoin = 37
    /// Not enough extra currencies
    NotEnoughExtraCurrencies = 38
    /// Outbound message does not fit into a cell after rewriting
    OutboundMessageDoesNotFitIntoACellAfterRewriting = 39
    /// Cannot process a message
    CannotProcessAMessage = 40
    /// Library reference is null
    LibraryReferenceIsNull = 41
    /// Library change action error
    LibraryChangeActionError = 42
    /// Exceeded maximum number of cells in the library or the maximum depth of the Merkle tree
    ExceededMaximumNumberOfCellsInTheLibraryOrTheMaximumDepthOfTheMerkleTree = 43
    /// Account state size exceeded limits
    AccountStateSizeExceededLimits = 50
    /// Null reference exception
    NullReferenceException = 128
    /// Invalid serialization prefix
    InvalidSerializationPrefix = 129
    /// Invalid incoming message
    InvalidIncomingMessage = 130
    /// Constraints error
    ConstraintsError = 131
    /// Access denied
    AccessDenied = 132
    /// Contract stopped
    ContractStopped = 133
    /// Invalid argument
    InvalidArgument = 134
    /// Code of a contract was not found
    CodeOfAContractWasNotFound = 135
    /// Invalid standard address
    InvalidStandardAddress = 136
    /// Not a basechain address
    NotABasechainAddress = 138
    /// signature expired
    SignatureExpired = 3838
    /// common content too long
    CommonContentTooLong = 7298
    /// already initialized
    AlreadyInitialized = 8704
    /// only owner can change royalty destination
    OnlyOwnerCanChangeRoyaltyDestination = 9120
    /// empty item content
    EmptyItemContent = 10224
    /// only owner can withdraw
    OnlyOwnerCanWithdraw = 10395
    /// only owner can change auth key
    OnlyOwnerCanChangeAuthKey = 17573
    /// only owner can edit content
    OnlyOwnerCanEditContent = 19805
    /// invalid common content
    InvalidCommonContent = 23121
    /// only collection can initialize
    OnlyCollectionCanInitialize = 24105
    /// only owner can change owner
    OnlyOwnerCanChangeOwner = 28454
    /// not initialized
    NotInitialized = 29252
    /// only owner can edit items
    OnlyOwnerCanEditItems = 29704
    /// only owner can change royalty
    OnlyOwnerCanChangeRoyalty = 30366
    /// invalid royalty denominator
    InvalidRoyaltyDenominator = 31108
    /// only collection can edit content
    OnlyCollectionCanEditContent = 32494
    /// unknown item
    UnknownItem = 41093
    /// not owner
    NotOwner = 49280
    /// royalty too high
    RoyaltyTooHigh = 55571
    /// only owner can change content
    OnlyOwnerCanChangeContent = 55942
    /// invalid signature
    InvalidSignature = 57400
    /// not enough TON attached to mint
    NotEnoughTONAttachedToMint = 58226
    /// only owner can change index url
    OnlyOwnerCanChangeIndexUrl = 62329
}

get fun get_collection_data(): NftCollectionCollectionData {
    throw 0;
}

get fun get_nft_address_by_index(index: int257): address {
    throw 0;
}

get fun get_nft_content(index: int257, individualContent: cell): cell {
    throw 0;
}

get fun get_common_content(): string {
    throw 0;
}

get fun get_collection_content_url(): string {
    throw 0;
}

get fun get_content(): cell {
    throw 0;
}

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun get_metadata_index_url(): string {
    throw 0;
}

get fun get_auth_public_key(): int257 {
    throw 0;
}

get fun get_minted_count(metadataIndex: int257): int257 {
    throw 0;
}
