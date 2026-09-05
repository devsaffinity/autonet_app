/// REAL response bodies for the buyer funnel, envelope and all, captured from
/// the shapes autonect-backend actually builds (REQUEST_INCLUDE at
/// requests.service.ts:17-21, ORDER_INCLUDE at orders.service.ts:12-26,
/// reviews.service.ts listForTarget, vehicles.service.ts toResponse).
///
/// The nullable traps are deliberate: a request with no vehicle, no part number
/// and no images; a supplier with neither a name nor a business profile; an
/// order event with no actor; a review with no reply and an anonymous author.
/// Every one of them is a shape the server can emit today.
library;

/// POST /v1/requests — note the 200, not a 201, and the already-normalised reg.
const String kCreateRequestBody =
    '{"success":true,"data":{"id":"req_1","buyerId":"usr_buyer","regNumber":"LM19XYZ",'
    '"vehicleId":"veh_1","categoryId":"cat_brakes","region":"LONDON",'
    '"partName":"Front brake discs","partNumber":"34116794300","condition":"EITHER",'
    '"urgency":"STANDARD","description":"Pair, front axle","status":"OPEN","offerCount":0,'
    '"createdAt":"2026-09-01T10:15:00.000Z","updatedAt":"2026-09-01T10:15:00.000Z",'
    '"vehicle":{"id":"veh_1","regNumber":"LM19XYZ","make":"BMW","model":"320d","year":2019,'
    '"fuel":"DIESEL","colour":"BLACK","source":"DVLA","fetchedAt":"2026-08-30T08:00:00.000Z"},'
    '"category":{"id":"cat_brakes","name":"Brakes"},'
    '"images":[{"s3Key":"requests/usr_buyer/aaa.jpg"},{"s3Key":"requests/usr_buyer/bbb.jpg"}]}}';

/// GET /v1/requests?page=1&limit=20 — the second item is the all-nulls shape.
const String kListRequestsBody =
    '{"success":true,"data":[{"id":"req_1","buyerId":"usr_buyer","regNumber":"LM19XYZ",'
    '"vehicleId":"veh_1","categoryId":"cat_brakes","region":"LONDON",'
    '"partName":"Front brake discs","partNumber":"34116794300","condition":"EITHER",'
    '"urgency":"STANDARD","description":"Pair, front axle","status":"OPEN","offerCount":3,'
    '"createdAt":"2026-09-01T10:15:00.000Z","updatedAt":"2026-09-02T09:00:00.000Z",'
    '"vehicle":{"id":"veh_1","regNumber":"LM19XYZ","make":"BMW","model":"320d","year":2019,'
    '"fuel":"DIESEL","colour":"BLACK","source":"DVLA","fetchedAt":"2026-08-30T08:00:00.000Z"},'
    '"category":{"id":"cat_brakes","name":"Brakes"},'
    '"images":[{"s3Key":"requests/usr_buyer/aaa.jpg"}]},'
    '{"id":"req_2","buyerId":"usr_buyer","regNumber":"YB68ABC","vehicleId":null,'
    '"categoryId":"cat_lighting","region":"SCOTLAND","partName":"Headlight unit",'
    '"partNumber":null,"condition":"USED","urgency":"LOW","description":null,'
    '"status":"CANCELLED","offerCount":0,"createdAt":"2026-08-20T11:00:00.000Z",'
    '"updatedAt":"2026-08-21T11:00:00.000Z","vehicle":null,'
    '"category":{"id":"cat_lighting","name":"Lighting"},"images":[]}],'
    '"meta":{"page":1,"limit":20,"pageSize":2,"total":2,"totalPages":1,'
    '"hasNextPage":false,"hasPreviousPage":false}}';

/// GET /v1/requests/{id}/offers — a bare array, unpaginated, with no meta.
const String kOffersArrayBody =
    '{"success":true,"data":[{"id":"off_1","requestId":"req_1","supplierId":"usr_sup1",'
    '"pricePence":12999,"condition":"NEW","warrantyMonths":24,"deliveryOption":"STANDARD",'
    '"deliveryTimeDays":3,"stockStatus":"IN_STOCK","quantity":2,"notes":"Genuine OEM pair",'
    '"status":"PENDING","createdAt":"2026-09-01T12:00:00.000Z",'
    '"updatedAt":"2026-09-01T12:00:00.000Z","supplier":{"id":"usr_sup1","name":"Ade O.",'
    '"supplierProfile":{"businessName":"Northside Motors"}}},'
    '{"id":"off_2","requestId":"req_1","supplierId":"usr_sup2","pricePence":8450,'
    '"condition":"USED","warrantyMonths":null,"deliveryOption":"LOCAL_PICKUP",'
    '"deliveryTimeDays":null,"stockStatus":"LOW_STOCK","quantity":1,"notes":null,'
    '"status":"PENDING","createdAt":"2026-09-01T13:30:00.000Z",'
    '"updatedAt":"2026-09-01T13:30:00.000Z",'
    '"supplier":{"id":"usr_sup2","name":null,"supplierProfile":null}}]}';

/// POST /v1/offers/{id}/accept — 200, with the seeded PLACED event.
const String kAcceptOrderBody =
    '{"success":true,"data":{"id":"ord_1","offerId":"off_1","requestId":"req_1",'
    '"buyerId":"usr_buyer","supplierId":"usr_sup1","totalPence":12999,'
    '"deliveryMethod":"STANDARD","deliveryLocation":"12 Bruce Grove, London","etaDays":3,'
    '"status":"PLACED","cancelReason":null,"cancelledById":null,'
    '"createdAt":"2026-09-02T09:00:00.000Z","updatedAt":"2026-09-02T09:00:00.000Z",'
    '"offer":{"id":"off_1","pricePence":12999,"condition":"NEW","warrantyMonths":24,'
    '"deliveryOption":"STANDARD","deliveryTimeDays":3,"quantity":2},'
    '"request":{"id":"req_1","partName":"Front brake discs","regNumber":"LM19XYZ"},'
    '"events":[{"id":"evt_1","orderId":"ord_1","status":"PLACED","note":null,'
    '"byUserId":null,"at":"2026-09-02T09:00:00.000Z"}]}}';

/// GET /v1/orders/{id} — events ordered ASC by `at`, the first with no actor.
const String kOrderDetailBody =
    '{"success":true,"data":{"id":"ord_1","offerId":"off_1","requestId":"req_1",'
    '"buyerId":"usr_buyer","supplierId":"usr_sup1","totalPence":12999,'
    '"deliveryMethod":"STANDARD","deliveryLocation":"12 Bruce Grove, London","etaDays":3,'
    '"status":"OUT_FOR_DELIVERY","cancelReason":null,"cancelledById":null,'
    '"createdAt":"2026-09-02T09:00:00.000Z","updatedAt":"2026-09-04T08:20:00.000Z",'
    '"offer":{"id":"off_1","pricePence":12999,"condition":"NEW","warrantyMonths":24,'
    '"deliveryOption":"STANDARD","deliveryTimeDays":3,"quantity":2},'
    '"request":{"id":"req_1","partName":"Front brake discs","regNumber":"LM19XYZ"},'
    '"events":[{"id":"evt_1","orderId":"ord_1","status":"PLACED","note":null,'
    '"byUserId":null,"at":"2026-09-02T09:00:00.000Z"},'
    '{"id":"evt_2","orderId":"ord_1","status":"PREPARING","note":"Picking stock",'
    '"byUserId":"usr_sup1","at":"2026-09-03T10:05:00.000Z"},'
    '{"id":"evt_3","orderId":"ord_1","status":"OUT_FOR_DELIVERY","note":null,'
    '"byUserId":"usr_sup1","at":"2026-09-04T08:20:00.000Z"}]}}';

/// GET /v1/reviews?targetId — `average` and `counts` ride in `meta` beside the
/// pagination fields; the counts keys are JSON strings, always all five.
const String kReviewsListBody =
    '{"success":true,"data":[{"id":"rev_1","targetId":"usr_sup1","authorId":"usr_buyer",'
    '"orderId":"ord_1","rating":5,"text":"Fast and exactly as described",'
    '"status":"PUBLISHED","createdAt":"2026-09-04T09:00:00.000Z",'
    '"author":{"id":"usr_buyer","name":null},"reply":null},'
    '{"id":"rev_2","targetId":"usr_sup1","authorId":"usr_other","orderId":"ord_9",'
    '"rating":4,"text":null,"status":"PUBLISHED","createdAt":"2026-08-28T15:00:00.000Z",'
    '"author":{"id":"usr_other","name":"Priya S."},'
    '"reply":{"id":"rep_1","reviewId":"rev_2","authorId":"usr_sup1",'
    '"text":"Thanks for the order","createdAt":"2026-08-29T08:00:00.000Z"}}],'
    '"meta":{"page":1,"limit":20,"pageSize":2,"total":2,"totalPages":1,'
    '"hasNextPage":false,"hasPreviousPage":false,"average":4.5,'
    '"counts":{"1":0,"2":0,"3":0,"4":1,"5":1}}}';

/// POST /v1/vehicles/lookup — the projection drops `source`/`fetchedAt`, and a
/// null model is exactly what MANUAL_REQUIRED means.
const String kVehicleLookupManualRequiredBody =
    '{"success":true,"data":{"vehicle":{"id":"veh_2","regNumber":"YB68ABC","make":"FORD",'
    '"model":null,"year":2018,"fuel":"PETROL","colour":"BLUE"},'
    '"modelSource":"MANUAL_REQUIRED"}}';

/// GET /v1/categories — flat, ordered by name; nesting is only `parentId`.
const String kCategoriesBody =
    '{"success":true,"data":[{"id":"cat_brakes","name":"Brakes","parentId":null},'
    '{"id":"cat_discs","name":"Brake discs","parentId":"cat_brakes"},'
    '{"id":"cat_lighting","name":"Lighting","parentId":null}]}';

/// POST /v1/requests/image-url — the single-use S3 key plus its presigned PUT.
const String kImageUrlTicketBody =
    '{"success":true,"data":{"key":"requests/usr_buyer/ccc.jpg",'
    '"url":"https://s3.example.invalid/requests/usr_buyer/ccc.jpg?X-Amz-Signature=abc",'
    '"expiresInSec":300}}';
