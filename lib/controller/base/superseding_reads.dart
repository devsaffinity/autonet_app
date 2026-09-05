/// THE SUPERSEDING-READ DISCIPLINE, in one place so it is INHERITED rather
/// than re-typed into every controller that reads an entity.
///
/// It is PagedController's idiom — `final generation = ++_generation;` at
/// dispatch, `if (generation != _generation) return;` before every write —
/// hoisted out of that one class and generalised in exactly one way: a list
/// screen has ONE thing to publish, while a detail screen has several that
/// refresh independently, so the counter is per [StateSlot] rather than per
/// controller.
library;

import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:flutter/foundation.dart';

/// A NAME for one independently-published piece of asynchronous state.
///
/// One slot per observable that can be refreshed on its own. A request's header
/// and its offers load in PARALLEL and neither may supersede the other, so they
/// are two slots; sharing one would make dispatching the offers read discard
/// the header read issued a microsecond earlier.
final class StateSlot {
  const StateSlot(this.name);

  final String name;

  @override
  String toString() => 'StateSlot($name)';
}

/// The right to publish ONE answer into ONE slot, taken at DISPATCH and asked
/// again on ARRIVAL.
///
/// [isCurrent] is false once ANY of three things has happened: a newer answer
/// was dispatched into the same slot (the buyer asked again, or a write
/// produced something fresher), the controller was pointed at a different
/// entity (the buyer backed out and opened another order), or this claim has
/// already resolved. The first two are the same lie — an answer fetched for one
/// screen painted onto another — so they are one check, made immediately before
/// the write and never cached in a local.
final class SlotClaim {
  SlotClaim._(this._ledger, this._slot, this._generation, this._entity)
    : _dropped = false;

  /// The claim of a write that was DROPPED before it took anything.
  ///
  /// It owns no slot and describes no entity, so every question below answers
  /// no. It exists so a call site asks a dropped write the SAME question it
  /// asks a superseded one — 'may I publish?' — and cannot forget the case.
  SlotClaim._dropped(this._ledger, this._slot)
    : _generation = 0,
      _entity = null,
      _dropped = true;

  final _SlotLedger _ledger;
  final StateSlot _slot;
  final int _generation;
  final String? _entity;
  final bool _dropped;

  /// A claim resolves EXACTLY ONCE — it publishes, or it gives the slot back.
  bool _settled = false;

  bool get isCurrent => !_dropped && !_settled && _ledger.isCurrent(this);

  /// Publish [write] into the slot, and say whether it happened.
  ///
  /// The ONLY way an answer reaches a slot, because it is also the only record
  /// that one did: [SupersedingReads.runWrite] releases a claim that published
  /// nothing, and a caller that assigned the observable itself would leave that
  /// release rolling back a slot it had in fact already filled.
  bool publish(void Function() write) {
    if (!isCurrent) return false;
    _settled = true;
    write();
    return true;
  }

  /// Give the slot back to whatever this claim superseded.
  void _releaseIfUnpublished() {
    if (_dropped || _settled) return;
    _settled = true;
    _ledger.release(this);
  }
}

/// One controller's dispatch ledger: the entity it is pointed at, and how many
/// answers it has dispatched into each slot.
class _SlotLedger {
  final Map<StateSlot, int> _dispatched = <StateSlot, int>{};

  String? entityId;

  SlotClaim claim(StateSlot slot) {
    final generation = (_dispatched[slot] ?? 0) + 1;
    _dispatched[slot] = generation;
    return SlotClaim._(this, slot, generation, entityId);
  }

  bool isCurrent(SlotClaim c) =>
      _dispatched[c._slot] == c._generation && entityId == c._entity;

  /// Undo a claim that published NOTHING, so the read it superseded is current
  /// again and still lands. Only when nothing newer has taken the slot since:
  /// rolling back over a later dispatch would hand it to an older answer.
  void release(SlotClaim c) {
    if (_dispatched[c._slot] != c._generation) return;
    _dispatched[c._slot] = c._generation - 1;
  }
}

/// What every ApiController mixes in: the entity it is pointed at, and the
/// two ways an asynchronous answer may reach its observable state.
mixin SupersedingReads {
  final _SlotLedger _ledger = _SlotLedger();

  /// THE entity, held once. A controller that kept its own copy of the id
  /// beside this one would drift from it, and the claims below are only as
  /// truthful as this field.
  @protected
  String? get entityId => _ledger.entityId;

  @protected
  set entityId(String? id) => _ledger.entityId = id;

  /// THE DROP DECISION, owned by `ApiController`'s busy latch and asked here
  /// exactly once — before [runWrite] has claimed anything.
  @protected
  bool get isBusy;

  /// `ApiController.run`'s body with the drop decision ALREADY MADE: the latch,
  /// the modal dialog and the finally, and nothing that could still refuse.
  @protected
  Future<R> runLatched<T, R>(
    Future<ApiResult<T>> Function() call,
    R Function(ApiResult<T>) then, {
    required bool silent,
  });

  /// THE SUPERSEDING READ — the idempotent sibling of `ApiController.run`, and
  /// the ONLY path an entity read may take.
  ///
  /// `run` DROPS a re-entrant call: right for a WRITE, where firing twice is
  /// the harm, and wrong for a read, where it means the read the buyer asked
  /// for is never issued at all while the older one still lands on the screen
  /// they have since left. A read SUPERSEDES instead — the newest dispatch owns
  /// [slot] and older answers are discarded WHOLE on arrival.
  ///
  /// It takes NO busy latch and shows NO dialog, and that is what makes a stuck
  /// spinner unrepresentable rather than merely unlikely: a discarded answer
  /// has no flag left to clear. The only progress indicator is the ViewState
  /// its caller writes at dispatch, and the newest dispatch — the one nothing
  /// supersedes — always reaches [then] and replaces it.
  @protected
  Future<void> runRead<T>(
    StateSlot slot,
    Future<ApiResult<T>> Function() call,
    void Function(ApiResult<T>) then,
  ) async {
    final claim = _ledger.claim(slot);
    final result = await call();
    // The whole answer or none of it: publishing the rows but not the error
    // beside them is the same lie in a smaller box.
    claim.publish(() => then(result));
  }

  /// THE SUPERSEDING WRITE — the drop decision and the claim as ONE step.
  ///
  /// A write's response is fresher than any read in flight (a PATCH answers
  /// with the whole updated entity), so it must TAKE [slot], and must ask when
  /// it lands whether the buyer is still looking at what it describes. Both
  /// halves used to be hand-rolled beside `run`, claim FIRST — so a duplicate
  /// tap bumped the slot and was only then dropped as re-entrant, stealing the
  /// claim from the write still in flight and turning that write's successful
  /// response into a discarded one. Here nothing runs between them.
  ///
  /// A claim that publishes nothing is RELEASED, which is the other half: a
  /// write that had overtaken the screen's only read and then failed would
  /// otherwise leave that screen on Loading with nothing left in flight to fill
  /// it. Released, the read it superseded is current again and still lands.
  @protected
  Future<R> runWrite<T, R>(
    StateSlot slot,
    Future<ApiResult<T>> Function() call,
    R Function(ApiResult<T>, SlotClaim) then, {
    bool silent = false,
  }) async {
    // A DROPPED write claims NOTHING.
    if (isBusy) {
      return then(const Err(droppedReentry), SlotClaim._dropped(_ledger, slot));
    }
    final claim = _ledger.claim(slot);
    try {
      return await runLatched(call, (r) => then(r, claim), silent: silent);
    } finally {
      claim._releaseIfUnpublished();
    }
  }
}
