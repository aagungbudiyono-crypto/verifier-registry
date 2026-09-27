// Generated from the verified Tact contract ABI.
contract NftCollection {
    storage: NftCollectionData
    incomingMessages: NftCollectionIncomingMessage
    thrownErrors: NftCollectionErrors
}

struct (0x693d3950) NftCollectionGetRoyaltyParams {
    queryId: uint64
}

struct (0x6d696e74) NftCollectionMint {
    queryId: uint64
    index: uint32
    owner: address
    content: cell
}

struct (0x00000003) NftCollectionChangeOwner {
    queryId: uint64
    newOwner: address
}

struct (0x6d6e7472) NftCollectionChangeMinter {
    queryId: uint64
    minter: address
}

struct (0x00000004) NftCollectionEditContent {
    queryId: uint64
    collectionContent: cell
    commonContent: cell
    royaltyNumerator: uint16
    royaltyDenominator: uint16
    royaltyDestination: address
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
    minter: address
    collectionContent: cell
    commonContent: cell
    royaltyNumerator: uint16
    royaltyDenominator: uint16
    royaltyDestination: address
    minted: uint32
}

type NftCollectionIncomingMessage =
    | NftCollectionMint
    | NftCollectionGetRoyaltyParams
    | NftCollectionChangeOwner
    | NftCollectionChangeMinter
    | NftCollectionEditContent

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
    /// Not owner
    NotOwner = 14534
    /// Only collection
    OnlyCollection = 17639
    /// Index out of range
    IndexOutOfRange = 41046
    /// Access denied
    AccessDenied2 = 49469
    /// Already minted
    AlreadyMinted = 51687
    /// Not minted
    NotMinted = 56591
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

get fun royalty_params(): NftCollectionRoyaltyParams {
    throw 0;
}

get fun minter(): address {
    throw 0;
}

get fun minted(): int257 {
    throw 0;
}
