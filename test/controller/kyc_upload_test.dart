import 'dart:async';

import 'package:autonect/controller/supplier/supplier_kyc_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/kyc_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/services/document_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The KYC upload is three round trips, and the FIRST one destroys state:
/// `createUploadUrl` deletes the previous document and its S3 object before any
/// bytes move. So every failure after it leaves the server without a document
/// the screen is still showing — which is what these lock down.

KycState _state({List<KycDocType> uploaded = const []}) => KycState.fromJson({
  'kycStatus': 'PENDING',
  'approved': false,
  'requiredDocuments': const ['ID', 'BUSINESS_REGISTRY', 'TAX'],
  'documents': [
    for (final t in uploaded)
      {'type': t.wire, 'uploaded': true, 'fileName': '${t.wire}.pdf'},
  ],
});

class _FakeKycRepository implements KycRepository {
  ApiResult<KycState> statusResult = Ok(_state());
  ApiResult<UploadTicket> ticketResult =
      const Ok(UploadTicket(key: 'k', url: 'https://s3/x', expiresInSec: 300));
  ApiResult<KycState> confirmResult = Ok(_state(uploaded: [KycDocType.id]));
  ApiResult<KycState> removeResult = Ok(_state());

  final calls = <String>[];

  @override
  Future<ApiResult<KycState>> status() async {
    calls.add('status');
    return statusResult;
  }

  @override
  Future<ApiResult<UploadTicket>> createUploadTicket(KycUploadRequest r) async {
    calls.add('ticket:${r.type.wire}');
    return ticketResult;
  }

  @override
  Future<ApiResult<KycState>> confirmUpload(String key) async {
    calls.add('confirm');
    return confirmResult;
  }

  @override
  Future<ApiResult<KycState>> removeDocument(KycDocType type) async {
    calls.add('remove:${type.wire}');
    return removeResult;
  }
}

class _FakeTransport implements HttpTransport {
  _FakeTransport(this.status);
  int status;

  @override
  Future<HttpResponse> send(HttpRequest request) async =>
      HttpResponse(statusCode: status, body: '', headers: const {});
}

class _FakePicker implements DocumentPickerService {
  _FakePicker(this.result);
  DocumentPickResult result;
  int calls = 0;

  /// Completes only when the test says so, to model the system sheet being open.
  Future<void>? gate;

  @override
  Future<DocumentPickResult> pickDocument() async {
    calls++;
    if (gate != null) await gate;
    return result;
  }
}

PickedDocument _doc() => const PickedDocument(
  bytes: [1, 2, 3],
  contentType: 'application/pdf',
  sizeBytes: 3,
  fileName: 'passport.pdf',
);

void main() {
  late _FakeKycRepository repo;
  late _FakePicker picker;
  late SupplierKycController c;
  late List<String> toasts;

  SupplierKycController build({int putStatus = 200}) {
    toasts = [];
    return SupplierKycController(
      repo,
      BlobUploader(_FakeTransport(putStatus)),
      picker,
      // Injected so the test runs with no GetMaterialApp and no Fluttertoast
      // platform channel.
      toast: toasts.add,
    );
  }

  setUp(() {
    repo = _FakeKycRepository();
    picker = _FakePicker(DocumentPickResult.picked(_doc()));
    c = build();
  });

  group('a failure after the ticket call re-reads the truth', () {
    test('the S3 PUT failing triggers a reload', () async {
      // The previous document is already deleted server-side at this point.
      // Without the reload the card keeps showing a file that no longer exists
      // and isComplete keeps Next enabled over the hole.
      c = build(putStatus: 403);
      await c.pickAndUpload(KycDocType.id);

      expect(repo.calls, ['ticket:ID', 'status']);
    });

    test('confirm failing triggers a reload', () async {
      repo.confirmResult = const Err(ApiError.network('offline'));
      await c.pickAndUpload(KycDocType.id);

      expect(repo.calls, ['ticket:ID', 'confirm', 'status']);
    });

    test('the ticket call itself failing triggers a reload', () async {
      repo.ticketResult = const Err(ApiError.network('offline'));
      await c.pickAndUpload(KycDocType.id);

      expect(repo.calls, ['ticket:ID', 'status']);
    });

    test('a remove failing triggers a reload', () async {
      repo.removeResult = const Err(ApiError.network('offline'));
      await c.remove(KycDocType.id);

      expect(repo.calls, ['remove:ID', 'status']);
    });

    test('a SUCCESSFUL upload does not re-read - confirm already answered', () async {
      await c.pickAndUpload(KycDocType.id);

      expect(repo.calls, ['ticket:ID', 'confirm']);
      expect(c.state.value, isA<Data<KycState>>());
    });
  });

  group('one document at a time', () {
    test('a second tap while the picker is open is refused, not queued',
        () async {
      // The latch used to be checked before the pick and set only after it, so
      // both taps reached file_picker and Android answered the second with
      // already_active - an uncaught async error, swallowed in release.
      final gate = Completer<void>();
      picker.gate = gate.future;

      final first = c.pickAndUpload(KycDocType.id);
      await Future<void>.delayed(Duration.zero);

      await c.pickAndUpload(KycDocType.tax);
      expect(picker.calls, 1, reason: 'the second tap must not open a picker');
      expect(toasts, isNotEmpty, reason: 'a refused tap must say why');

      gate.complete();
      await first;
    });

    test('remove is refused while a pick is open', () async {
      // Otherwise a DELETE can land after the ticket INSERT and confirm 404s.
      final gate = Completer<void>();
      picker.gate = gate.future;

      final first = c.pickAndUpload(KycDocType.id);
      await Future<void>.delayed(Duration.zero);

      await c.remove(KycDocType.id);
      expect(repo.calls, isNot(contains('remove:ID')));

      gate.complete();
      await first;
    });

    test('the latch clears after a cancelled pick', () async {
      picker.result =
          const DocumentPickResult.failed(DocumentPickFailure.cancelled);
      await c.pickAndUpload(KycDocType.id);

      expect(c.isLatched, isFalse);
      expect(toasts, isEmpty, reason: 'backing out is not an error');

      // And the next attempt works.
      picker.result = DocumentPickResult.picked(_doc());
      await c.pickAndUpload(KycDocType.id);
      expect(repo.calls, contains('confirm'));
    });

    test('the latch clears after a failed upload', () async {
      c = build(putStatus: 500);
      await c.pickAndUpload(KycDocType.id);
      expect(c.isLatched, isFalse, reason: 'a failure must not wedge the card');
    });
  });

  test('a rejected file never reaches the network', () async {
    picker.result =
        const DocumentPickResult.failed(DocumentPickFailure.tooLarge);
    await c.pickAndUpload(KycDocType.id);

    expect(repo.calls, isEmpty);
    expect(toasts.single, contains('10 MB'));
  });
}
