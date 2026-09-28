// «Коллекция Gram Daily Draw» — NFT collection for the Gram Daily Draw prize draw.
// Standards: TEP-62 (NFT), TEP-64 (off-chain metadata), TEP-66 (royalty).
// Design:
//  * Only the owner or the backend "minter" wallet can mint (NFTs are free gifts to ticket buyers).
//  * Item index = combination number (0..MAX_ITEMS-1). An item can be initialised only once,
//    so every combination exists at most once — enforced on-chain, no map needed.
//  * Collection is non-sequential: get_collection_data returns next_item_index = -1 (allowed by TEP-62).

const MAX_ITEMS: Int = 20000;              // 2 series x 10 000 combinations
const ITEM_RESERVE: Int = ton("0.005");    // stays on every NFT to pay storage for years
const COLLECTION_RESERVE: Int = ton("0.05");

// ---------- TEP-62 messages ----------
message(0x5fcc3d14) NftTransfer {
    queryId: Int as uint64;
    newOwner: Address;
    responseDestination: Address?;
    customPayload: Cell?;
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

// ---------- TEP-66 royalty ----------
message(0x693d3950) GetRoyaltyParams {
    queryId: Int as uint64;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    queryId: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

// ---------- collection admin / mint ----------
message(0x6d696e74) Mint {                 // "mint"
    queryId: Int as uint64;
    index: Int as uint32;
    owner: Address;
    content: Cell;                           // individual content: snake string, e.g. "13912.json"
}

message(0x696e6974) InitItem {             // "init" — collection -> item, first and only time
    queryId: Int as uint64;
    owner: Address;
    content: Cell;
    response: Address;
}

message(3) ChangeOwner {                   // same op as the Getgems reference collection
    queryId: Int as uint64;
    newOwner: Address;
}

message(0x6d6e7472) ChangeMinter {         // "mntr"
    queryId: Int as uint64;
    minter: Address;
}

message(4) EditContent {                   // same op as the Getgems reference collection
    queryId: Int as uint64;
    collectionContent: Cell;
    commonContent: Cell;
    royaltyNumerator: Int as uint16;
    royaltyDenominator: Int as uint16;
    royaltyDestination: Address;
}

// ---------- getter structs ----------
struct CollectionData {
    nextItemIndex: Int;
    collectionContent: Cell;
    ownerAddress: Address;
}

struct NftData {
    init: Bool;
    index: Int;
    collectionAddress: Address;
    ownerAddress: Address?;
    individualContent: Cell?;
}

struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}

contract NftCollection {
    owner: Address;
    minter: Address;
    collectionContent: Cell;               // 0x01 + URL of collection.json
    commonContent: Cell;                   // URL prefix for items, e.g. "https://draw.claude-model.com/nft/"
    royaltyNumerator: Int as uint16;
    royaltyDenominator: Int as uint16;
    royaltyDestination: Address;
    minted: Int as uint32;

    init(owner: Address, minter: Address, collectionContent: Cell, commonContent: Cell,
         royaltyNumerator: Int, royaltyDenominator: Int, royaltyDestination: Address) {
        self.owner = owner;
        self.minter = minter;
        self.collectionContent = collectionContent;
        self.commonContent = commonContent;
        self.royaltyNumerator = royaltyNumerator;
        self.royaltyDenominator = royaltyDenominator;
        self.royaltyDestination = royaltyDestination;
        self.minted = 0;
    }

    receive() {}                           // accept top-ups

    receive(msg: Mint) {
        let ctx: Context = context();
        require(ctx.sender == self.minter || ctx.sender == self.owner, "Access denied");
        require(msg.index >= 0 && msg.index < MAX_ITEMS, "Index out of range");
        let init: StateInit = initOf NftItem(myAddress(), msg.index);
        self.minted = self.minted + 1;
        send(SendParameters{
            to: contractAddress(init),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: InitItem{ queryId: msg.queryId, owner: msg.owner, content: msg.content, response: ctx.sender }.toCell(),
            code: init.code,
            data: init.data
        });
    }

    // Item already exists (combination taken) -> the init bounces back: undo the counter, refund the minter.
    bounced(msg: bounced<InitItem>) {
        self.minted = self.minted - 1;
        send(SendParameters{
            to: self.minter,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: false,
            body: Excesses{ queryId: msg.queryId }.toCell()
        });
    }

    receive(msg: GetRoyaltyParams) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: ReportRoyaltyParams{
                queryId: msg.queryId,
                numerator: self.royaltyNumerator,
                denominator: self.royaltyDenominator,
                destination: self.royaltyDestination
            }.toCell()
        });
    }

    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "Access denied");
        self.owner = msg.newOwner;
    }

    receive(msg: ChangeMinter) {
        require(sender() == self.owner, "Access denied");
        self.minter = msg.minter;
    }

    receive(msg: EditContent) {
        require(sender() == self.owner, "Access denied");
        self.collectionContent = msg.collectionContent;
        self.commonContent = msg.commonContent;
        self.royaltyNumerator = msg.royaltyNumerator;
        self.royaltyDenominator = msg.royaltyDenominator;
        self.royaltyDestination = msg.royaltyDestination;
    }

    receive("withdraw") {
        require(sender() == self.owner, "Access denied");
        nativeReserve(COLLECTION_RESERVE, ReserveAtMost);
        send(SendParameters{ to: self.owner, value: 0, mode: SendRemainingBalance + SendIgnoreErrors, bounce: false });
    }

    get fun get_collection_data(): CollectionData {
        return CollectionData{ nextItemIndex: -1, collectionContent: self.collectionContent, ownerAddress: self.owner };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        return contractAddress(initOf NftItem(myAddress(), index));
    }

    get fun get_nft_content(index: Int, individualContent: Cell): Cell {
        return beginCell().storeUint(1, 8).storeSlice(self.commonContent.beginParse()).storeRef(individualContent).endCell();
    }

    get fun royalty_params(): RoyaltyParams {
        return RoyaltyParams{ numerator: self.royaltyNumerator, denominator: self.royaltyDenominator, destination: self.royaltyDestination };
    }

    get fun minter(): Address { return self.minter; }
    get fun minted(): Int { return self.minted; }
}

contract NftItem {
    collection: Address;
    index: Int as uint32;
    owner: Address?;
    content: Cell?;

    init(collection: Address, index: Int) {
        self.collection = collection;
        self.index = index;
        self.owner = null;
        self.content = null;
    }

    receive(msg: InitItem) {
        require(sender() == self.collection, "Only collection");
        require(self.owner == null, "Already minted");
        self.owner = msg.owner;
        self.content = msg.content;
        nativeReserve(ITEM_RESERVE, ReserveAtMost);
        send(SendParameters{
            to: msg.response,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors,
            bounce: false,
            body: Excesses{ queryId: msg.queryId }.toCell()
        });
    }

    receive(msg: NftTransfer) {
        require(self.owner != null, "Not minted");
        let prev: Address = self.owner!!;
        require(sender() == prev, "Not owner");
        self.owner = msg.newOwner;
        nativeReserve(ITEM_RESERVE, ReserveAtMost);
        if (msg.forwardAmount > 0) {
            send(SendParameters{
                to: msg.newOwner,
                value: msg.forwardAmount,
                mode: SendPayGasSeparately,
                bounce: false,
                body: OwnershipAssigned{ queryId: msg.queryId, prevOwner: prev, forwardPayload: msg.forwardPayload }.toCell()
            });
        }
        if (msg.responseDestination != null) {
            send(SendParameters{
                to: msg.responseDestination!!,
                value: 0,
                mode: SendRemainingBalance + SendIgnoreErrors,
                bounce: false,
                body: Excesses{ queryId: msg.queryId }.toCell()
            });
        }
    }

    receive(msg: GetStaticData) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: ReportStaticData{ queryId: msg.queryId, index: self.index, collection: self.collection }.toCell()
        });
    }

    get fun get_nft_data(): NftData {
        return NftData{
            init: self.owner != null,
            index: self.index,
            collectionAddress: self.collection,
            ownerAddress: self.owner,
            individualContent: self.content
        };
    }
}
