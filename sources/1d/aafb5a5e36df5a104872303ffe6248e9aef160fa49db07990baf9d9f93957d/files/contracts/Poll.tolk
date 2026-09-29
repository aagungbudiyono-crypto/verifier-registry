import "@gen/Voter.code"
import "types"

type AllowedPollMessage = Vote | ClosePoll

const CLOSED_POLL_RESERVE = grams("0.05")

contract Poll {
    storage: PollStorage
    incomingMessages: AllowedPollMessage
}

fun onInternalMessage(in: InMessage) {
    val msg = lazy AllowedPollMessage.fromSlice(in.body);

    match (msg) {
        Vote => {
            var storage = lazy PollStorage.load();
            assert (!storage.isClosed) throw Errors.PollClosed;
            assert (msg.option == 0 || msg.option == 1) throw Errors.InvalidOption;

            // Optimistic increment — reverted in onBouncedMessage if Voter rejects.
            if (msg.option == 0) {
                storage.option0 += 1;
            } else {
                storage.option1 += 1;
            }
            storage.save();

            // Deploy or message the Voter for this sender.
            // If Voter doesn't exist, the stateInit deploys it.
            // If it already exists, the stateInit is ignored; only the body is processed.
            val voterInit = ContractState {
                code: voterCompiledCode(),
                data: VoterStorage {
                    poll: contract.getAddress(),
                    voter: in.senderAddress,
                    hasVoted: false,
                }.toCell(),
            };
            val outMsg = createMessage({
                bounce: BounceMode.Only256BitsOfBody,
                value: grams("0.05"),
                dest: { stateInit: voterInit },
                body: msg,
            });
            outMsg.send(SEND_MODE_PAY_FEES_SEPARATELY);
        }
        ClosePoll => {
            var storage = lazy PollStorage.load();
            assert (in.senderAddress == storage.owner) throw Errors.NotOwner;
            storage.isClosed = true;
            storage.save();

            // Keep a small reserve for storage fees and late bounces,
            // then send the whole remaining balance back to the owner.
            reserveGramsOnBalance(CLOSED_POLL_RESERVE, RESERVE_MODE_EXACT_AMOUNT);
            val returnMsg = createMessage({
                bounce: false,
                value: 0,
                dest: storage.owner,
            });
            // SAFETY: only the poll owner can close, and storage is marked closed
            // before the balance is returned.
            returnMsg.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
        else => {
            assert (in.body.isEmpty()) throw Errors.InvalidMessage;
        }
    }
}

fun onBouncedMessage(in: InMessageBounced) {
    in.bouncedBody.skipBouncedPrefix();
    val msg = lazy Vote.fromSlice(in.bouncedBody);

    var storage = lazy PollStorage.load();
    if (msg.option == 0) {
        storage.option0 -= 1;
    } else {
        storage.option1 -= 1;
    }
    storage.save();
}

get fun results(): (uint32, uint32) {
    val storage = lazy PollStorage.load();
    return (storage.option0, storage.option1);
}

get fun owner(): address {
    val storage = lazy PollStorage.load();
    return storage.owner;
}

get fun calcVoterAddress(voter: address): address {
    val init = ContractState {
        code: voterCompiledCode(),
        data: VoterStorage {
            poll: contract.getAddress(),
            voter,
            hasVoted: false,
        }.toCell(),
    };
    return AutoDeployAddress { stateInit: init }.calculateAddress();
}

get fun isClosed(): bool {
    val storage = lazy PollStorage.load();
    return storage.isClosed;
}
