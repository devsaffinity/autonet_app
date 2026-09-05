import 'package:autonect/controller/buyer/request_images_controller.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/pending_image.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';
import '../fakes/fake_image_picker.dart';

void main() {
  late FakeRequestsRepository requests;
  late FakeBlobUploader uploader;
  late FakeImagePickerService picker;
  late RequestImagesController c;
  late int changes;

  setUp(() {
    requests = FakeRequestsRepository();
    uploader = FakeBlobUploader();
    picker = FakeImagePickerService();
    changes = 0;
    c = RequestImagesController(
      requests: requests,
      uploader: uploader,
      picker: picker,
      onChanged: () => changes++,
    );
  });

  Future<void> addImages(int n) async {
    picker.next
      ..clear()
      ..addAll([
        for (var i = 0; i < n; i++) FakeImagePickerService.image(path: 'p$i.jpg'),
      ]);
    await c.addFromPicker();
  }

  test('image 3 failing its PUT leaves the other three uploaded', () async {
    await addImages(4);
    uploader.failOnPutNumber = 3;
    await c.uploadAll();

    expect(
      [for (final s in c.slots) s.status],
      [
        ImageUploadStatus.uploaded,
        ImageUploadStatus.uploaded,
        ImageUploadStatus.failed,
        ImageUploadStatus.uploaded,
      ],
    );
    // The run CONTINUES past a failure: submit is not gated on uploads, so
    // 3-of-4 uploaded still ships.
    expect(c.readyKeys.length, 3);
    expect(c.pendingCount, 1);
    expect(c.slots[2].s3Key, isNull);
    expect(c.slots[2].errorMessage, isNotNull);
    // One ticket per image, minted immediately before its own PUT.
    expect(requests.ticketCalls, 4);
    expect(uploader.puts.length, 4);
  });

  test('retry mints a FRESH ticket and never replays the old key', () async {
    await addImages(4);
    uploader.failOnPutNumber = 3;
    await c.uploadAll();
    final before = [...c.readyKeys];
    expect(requests.ticketCalls, 4);

    uploader.failOnPutNumber = null;
    await c.retry('img2');

    // Two ticket calls have now been spent on that one slot. Replaying the
    // first key would be a P2002 on RequestImage.s3Key @unique -> 409.
    expect(requests.ticketCalls, 5);
    expect(c.slots[2].status, ImageUploadStatus.uploaded);
    expect(before, isNot(contains(c.slots[2].s3Key)));
    expect(c.readyKeys.length, 4);
    expect(c.readyKeys.toSet().length, 4);
    expect(c.pendingCount, 0);
  });

  test('a sixth photo is refused before the picker or the network opens', () async {
    await addImages(kMaxRequestImages);
    expect(c.slots.length, kMaxRequestImages);
    expect(picker.calls, 1);

    picker.next
      ..clear()
      ..addAll([FakeImagePickerService.image(path: 'sixth.jpg')]);
    await c.addFromPicker();

    // The sheet is never even shown, so a sixth photo costs no read and no
    // ticket.
    expect(picker.calls, 1);
    expect(c.slots.length, kMaxRequestImages);
    expect(requests.calls, isEmpty);
  });

  test('a picker that hands back six keeps only five', () async {
    await addImages(6);
    expect(c.slots.length, kMaxRequestImages);
  });

  test('a 6 MiB file is rejected before a ticket is minted', () async {
    picker.next.add(
      FakeImagePickerService.image(path: 'huge.jpg', sizeBytes: 6 * 1024 * 1024),
    );
    await c.addFromPicker();

    expect(c.slots, isEmpty);
    expect(c.rejectionMessage.value, isNotNull);
    expect(requests.calls, isEmpty);
  });

  test('a .heic is rejected — the server allowlist is exactly three types', () async {
    picker.next.add(
      FakeImagePickerService.image(path: 'a.heic', contentType: 'image/heic'),
    );
    await c.addFromPicker();

    expect(c.slots, isEmpty);
    expect(c.rejectionMessage.value, isNotNull);
    expect(requests.calls, isEmpty);
  });

  test('every terminal transition asks the draft to persist the key', () async {
    await addImages(2);
    final afterAdd = changes;
    await c.uploadAll();
    // The s3Key is the one thing in the draft that cannot be recreated, so a
    // save has to follow each upload that produced one.
    expect(changes - afterAdd, 2);

    c.remove('img0');
    expect(c.slots.length, 1);
    expect(changes - afterAdd, 3);
  });
}
