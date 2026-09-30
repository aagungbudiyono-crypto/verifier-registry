import "./messages.tact";

// TEP-62 NFT item. Address is deterministic from (index, collection address) alone,
// so it is deployed with empty owner/content and immediately initialized by the
// collection via `Initialize` right after.
//
// `content` is the item's OWN content (Getgems layout: raw snake string, no 0x01 tag);
// the full metadata URL is collection.commonContent + content, resolved by the collection's
// get_nft_content(). The collection owner can replace it with `ItemEditContent` (relayed by
// the collection) but can never touch `owner`: only the item's owner can transfer it.
contract NftItem {
    index: Int as uint256;
    collection: Address;
    owner: Address;
    content: Cell;
    inited: Bool;

    const MinStorageReserve: Int = ton("0.02");

    init(index: Int, collection: Address) {
        self.index = index;
        self.collection = collection;
        self.owner = collection;
        self.content = emptyCell();
        self.inited = false;
    }

    receive(msg: Initialize) {
        require(!self.inited, "already initialized");
        require(sender() == self.collection, "only collection can initialize");
        self.owner = msg.owner;
        self.content = msg.content;
        self.inited = true;
    }

    // Content update requested by the collection owner and relayed by the collection
    // (see `EditItemContent` in nft_collection.tact). Ownership is left untouched.
    receive(msg: ItemEditContent) {
        require(self.inited, "not initialized");
        require(sender() == self.collection, "only collection can edit content");
        self.content = msg.content;
        send(SendParameters{
            to: msg.responseDestination,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: false,
            body: Excesses{queryId: msg.queryId}.toCell(),
        });
    }

    receive(msg: Transfer) {
        require(self.inited, "not initialized");
        require(sender() == self.owner, "not owner");
        let prevOwner: Address = self.owner;
        self.owner = msg.newOwner;

        if (msg.forwardAmount > 0) {
            send(SendParameters{
                to: msg.newOwner,
                value: msg.forwardAmount,
                // The forwarding fee is paid from the item's balance, NOT taken out of
                // `value`. Wallets and marketplaces (Getgems sales) often set forwardAmount
                // to 1 nanoTON: with the default mode the fee cannot be covered by such a
                // value and the action phase fails with exit code 40 ("not enough funds to
                // process a message"), which made every transfer and every purchase fail.
                mode: SendPayGasSeparately,
                bounce: false,
                body: OwnershipAssigned{
                    queryId: msg.queryId,
                    prevOwner: prevOwner,
                    forwardPayload: msg.forwardPayload,
                }.toCell(),
            });
        }

        // Keep a minimum for storage fees on the item (never drain it to 0, or it could be
        // frozen); ReserveAtMost never fails when the balance is below the minimum.
        nativeReserve(self.MinStorageReserve, ReserveAtMost);
        let responseDestination: Address? = msg.responseDestination;
        if (responseDestination != null) {
            send(SendParameters{
                to: responseDestination!!,
                value: 0,
                mode: SendRemainingBalance | SendIgnoreErrors,
                bounce: false,
                body: Excesses{queryId: msg.queryId}.toCell(),
            });
        }
    }

    receive(msg: GetStaticData) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: false,
            body: ReportStaticData{
                queryId: msg.queryId,
                index: self.index,
                collection: self.collection,
            }.toCell(),
        });
    }

    get fun get_nft_data(): NftData {
        return NftData{
            inited: self.inited,
            index: self.index,
            collection: self.collection,
            owner: self.owner,
            individualContent: self.content,
        };
    }
}

struct NftData {
    inited: Bool;
    index: Int;
    collection: Address;
    owner: Address;
    individualContent: Cell;
}
