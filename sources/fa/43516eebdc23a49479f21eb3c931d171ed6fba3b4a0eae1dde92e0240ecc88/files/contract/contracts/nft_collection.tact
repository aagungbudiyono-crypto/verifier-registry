import "@stdlib/content";
import "./messages.tact";
import "./nft_item.tact";

// Builds the Getgems "editable collection" content cell:
//   ref 0: collection content  -> 0x01 tag + URL of the collection JSON (name, description,
//          avatar and cover all live inside that JSON)
//   ref 1: common content      -> raw URL prefix (no tag) prepended to every item's content
// The common content must fit in one cell (snake chains are not allowed there), because
// get_nft_content() has to append the item's own content as a reference after it.
fun buildCollectionContent(collectionContentUrl: String, commonContentUrl: String): Cell {
    let common: Slice = commonContentUrl.asSlice();
    require(common.bits() <= 1000 && common.refs() == 0, "common content too long");
    return beginCell()
        .storeRef(createOffchainContent(collectionContentUrl))
        .storeRef(beginCell().storeSlice(common).endCell())
        .endCell();
}

// Checks that a raw content cell has the layout above (two references, the second one a
// single cell with room for the tag byte), so that no owner mistake can break the getters.
fun requireValidCollectionContent(content: Cell) {
    let cs: Slice = content.beginParse();
    cs.loadRef();
    let common: Slice = cs.loadRef().beginParse();
    require(common.bits() <= 1000 && common.refs() == 0, "invalid common content");
}

// TEP-62 NFT collection with TEP-66 royalties and Ed25519-gated minting, in the
// Getgems "editable collection" layout:
//   * get_collection_data() returns the collection JSON cell, common content is kept apart
//   * get_nft_content() = 0x01 + commonContent + item's own content (snake, by reference)
//   * ChangeOwner (3) / EditContent (4) are the standard Getgems messages
// The owner can also change, with dedicated messages, the collection + common content
// (ChangeCollectionContent), the royalty (ChangeRoyalty, ChangeRoyaltyDestination), the
// metadata index URL, the minting public key and the content of every minted item
// (EditItemContent). Nobody, owner included, can transfer an item they do not own.
//
// `metadataIndexUrl` points at a JSON array of per-item metadata URLs; it is stored here
// only for transparency/auditing — the contract never fetches it. Minting is authorized by
// a trusted off-chain signer that reads metadataIndex.json, enforces max-supply-per-item
// itself, and signs a `Mint` message with AUTHENTICATION_SIGNATURE_PRIVATE_KEY.
contract NftCollection {
    owner: Address;
    nextItemIndex: Int as uint256;
    // Getgems layout: ref 0 = collection content, ref 1 = common content.
    content: Cell;
    metadataIndexUrl: String;
    royaltyDestination: Address;
    authPublicKey: Int as uint256;
    mintedPerMetadataIndex: map<Int, Int>;
    // TEP-66 royalty = numerator / denominator. Starts at 200/1000 (= 20%) and can be
    // changed by the owner (ChangeRoyalty, EditContent).
    royaltyNumerator: Int as uint16;
    royaltyDenominator: Int as uint16;

    const DefaultRoyaltyNumerator: Int = 200;
    const DefaultRoyaltyDenominator: Int = 1000;
    const ItemDeployValue: Int = ton("0.03");
    // Minimum TON attached to a Mint: the collection pays ItemDeployValue to the new item,
    // so a signature holder cannot mint paying only gas at the collection's expense.
    const MinMintValue: Int = ton("0.05");

    init(
        owner: Address,
        royaltyDestination: Address,
        authPublicKey: Int,
        collectionContentUrl: String,
        metadataIndexUrl: String,
        commonContentUrl: String,
    ) {
        self.owner = owner;
        self.nextItemIndex = 0;
        self.content = buildCollectionContent(collectionContentUrl, commonContentUrl);
        self.metadataIndexUrl = metadataIndexUrl;
        self.royaltyDestination = royaltyDestination;
        self.authPublicKey = authPublicKey;
        self.mintedPerMetadataIndex = emptyMap();
        self.royaltyNumerator = self.DefaultRoyaltyNumerator;
        self.royaltyDenominator = self.DefaultRoyaltyDenominator;
    }

    // Accepts a plain deploy transaction with no message body.
    receive() {}

    receive(msg: Mint) {
        require(context().value >= self.MinMintValue, "not enough TON attached to mint");
        require(now() <= msg.validUntil, "signature expired");

        let contentHash: Int = sha256(msg.contentUrl);
        // Tact's sha256(Slice) (HASHEXT_SHA256 under the hood) requires the slice's
        // bit length to be a multiple of 8, or it throws a cell-underflow exception.
        // metadataIndex(32) + contentHash(256) + address(267) + validUntil(32) +
        // nextItemIndex(256) = 843 bits, which is NOT byte-aligned, so we pad with
        // 5 zero bits to reach 848 bits (106 bytes). The off-chain signer must add
        // the exact same padding when computing the digest it signs.
        let signedData: Cell = beginCell()
            .storeUint(msg.metadataIndex, 32)
            .storeUint(contentHash, 256)
            .storeAddress(msg.newOwner)
            .storeUint(msg.validUntil, 32)
            .storeUint(self.nextItemIndex, 256)
            .storeUint(0, 5)
            .endCell();
        let digest: Int = sha256(signedData.asSlice());
        require(checkSignature(digest, msg.signature, self.authPublicKey), "invalid signature");

        let itemIndex: Int = self.nextItemIndex;
        let itemInit: StateInit = initOf NftItem(itemIndex, myAddress());
        let itemAddress: Address = contractAddress(itemInit);
        // Getgems layout: the item stores only its own (raw, tag-less) content; the full
        // URL is commonContent + this. With an empty common content it is the full URL.
        let itemContent: Cell = beginCell().storeSlice(msg.contentUrl.asSlice()).endCell();

        send(SendParameters{
            to: itemAddress,
            value: self.ItemDeployValue,
            bounce: true,
            body: Initialize{owner: msg.newOwner, content: itemContent}.toCell(),
            code: itemInit.code,
            data: itemInit.data,
        });

        let mintedSoFar: Int? = self.mintedPerMetadataIndex.get(msg.metadataIndex);
        let minted: Int = 0;
        if (mintedSoFar != null) {
            minted = mintedSoFar!!;
        }
        self.mintedPerMetadataIndex.set(msg.metadataIndex, minted + 1);
        self.nextItemIndex = itemIndex + 1;
    }

    // Lets the collection owner pull out the accumulated TON balance (mint
    // proceeds minus what gets forwarded to each NftItem on deploy). Keeps a
    // small reserve on the contract so it stays funded for storage rent.
    receive(msg: Withdraw) {
        require(sender() == self.owner, "only owner can withdraw");
        nativeReserve(ton("0.05"), 0);
        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: false,
        });
    }

    // ---- Owner administration ------------------------------------------------

    // Getgems-standard: pass the collection to another wallet.
    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "only owner can change owner");
        self.owner = msg.newOwner;
    }

    // Getgems-standard: the message sent by the Getgems edit button. Replaces the content
    // (collection + common) and the royalty together.
    receive(msg: EditContent) {
        require(sender() == self.owner, "only owner can edit content");
        require(msg.denominator > 0, "invalid royalty denominator");
        require(msg.numerator <= msg.denominator, "royalty too high");
        requireValidCollectionContent(msg.content);
        self.content = msg.content;
        self.royaltyNumerator = msg.numerator;
        self.royaltyDenominator = msg.denominator;
        self.royaltyDestination = msg.destination;
    }

    // One message: new collection JSON URL + new commonContentUrl.
    receive(msg: ChangeCollectionContent) {
        require(sender() == self.owner, "only owner can change content");
        self.content = buildCollectionContent(msg.collectionContentUrl, msg.commonContentUrl);
    }

    receive(msg: ChangeMetadataIndexUrl) {
        require(sender() == self.owner, "only owner can change index url");
        self.metadataIndexUrl = msg.metadataIndexUrl;
    }

    receive(msg: ChangeAuthPublicKey) {
        require(sender() == self.owner, "only owner can change auth key");
        self.authPublicKey = msg.authPublicKey;
    }

    // Changes the royalty percentage paid on secondary market sales (numerator over the
    // current denominator, e.g. 100/1000 = 10%). Never above 100%.
    receive(msg: ChangeRoyalty) {
        require(sender() == self.owner, "only owner can change royalty");
        require(msg.numerator <= self.royaltyDenominator, "royalty too high");
        self.royaltyNumerator = msg.numerator;
    }

    receive(msg: ChangeRoyaltyDestination) {
        require(sender() == self.owner, "only owner can change royalty destination");
        self.royaltyDestination = msg.destination;
    }

    // Changes the content (metadata URL) of an already minted item. Only the
    // collection owner can ask for it and the item's owner is never touched.
    // Attach ~0.05 TON: what is not spent as gas comes back to the sender.
    receive(msg: EditItemContent) {
        require(sender() == self.owner, "only owner can edit items");
        require(msg.itemIndex < self.nextItemIndex, "unknown item");
        let url: Slice = msg.itemContentUrl.asSlice();
        require(url.bits() > 0, "empty item content");
        let itemInit: StateInit = initOf NftItem(msg.itemIndex, myAddress());
        send(SendParameters{
            to: contractAddress(itemInit),
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: ItemEditContent{
                queryId: msg.queryId,
                content: beginCell().storeSlice(url).endCell(),
                responseDestination: sender(),
            }.toCell(),
        });
    }

    receive(msg: GetRoyaltyParams) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: false,
            body: ReportRoyaltyParams{
                queryId: msg.queryId,
                numerator: self.royaltyNumerator,
                denominator: self.royaltyDenominator,
                destination: self.royaltyDestination,
            }.toCell(),
        });
    }

    // ---- Getters -----------------------------------------------------------------

    // TEP-62 / Getgems: the cell returned is the collection JSON URL cell (ref 0); the
    // common content is kept in ref 1 and exposed through get_common_content().
    get fun get_collection_data(): CollectionData {
        let cs: Slice = self.content.beginParse();
        let collectionContent: Cell = cs.loadRef();
        return CollectionData{
            nextItemIndex: self.nextItemIndex,
            collectionContent: collectionContent,
            ownerAddress: self.owner,
        };
    }

    get fun get_nft_address_by_index(index: Int): Address {
        let itemInit: StateInit = initOf NftItem(index, myAddress());
        return contractAddress(itemInit);
    }

    // TEP-62 / Getgems: 0x01 (off-chain tag) + commonContent, with the item's own content
    // as a reference (snake format) => URL = commonContent + individual content.
    get fun get_nft_content(index: Int, individualContent: Cell): Cell {
        let cs: Slice = self.content.beginParse();
        cs.loadRef();
        let common: Slice = cs.loadRef().beginParse();
        return beginCell()
            .storeUint(1, 8)
            .storeSlice(common)
            .storeRef(individualContent)
            .endCell();
    }

    // Current commonContentUrl (prefix prepended to every item's own content).
    get fun get_common_content(): String {
        let cs: Slice = self.content.beginParse();
        cs.loadRef();
        return cs.loadRef().beginParse().asString();
    }

    // Current URL of the collection JSON (without the 0x01 tag).
    get fun get_collection_content_url(): String {
        let cs: Slice = self.content.beginParse();
        let collectionContent: Slice = cs.loadRef().beginParse();
        collectionContent.loadUint(8);
        return collectionContent.asString();
    }

    // The raw two-reference content cell exactly as Getgems stores it.
    get fun get_content(): Cell {
        return self.content;
    }

    get fun royalty_params(): RoyaltyParams {
        return RoyaltyParams{
            numerator: self.royaltyNumerator,
            denominator: self.royaltyDenominator,
            destination: self.royaltyDestination,
        };
    }

    get fun get_metadata_index_url(): String {
        return self.metadataIndexUrl;
    }

    get fun get_auth_public_key(): Int {
        return self.authPublicKey;
    }

    get fun get_minted_count(metadataIndex: Int): Int {
        let count: Int? = self.mintedPerMetadataIndex.get(metadataIndex);
        if (count != null) {
            return count!!;
        }
        return 0;
    }
}

struct CollectionData {
    nextItemIndex: Int;
    collectionContent: Cell;
    ownerAddress: Address;
}

struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}
