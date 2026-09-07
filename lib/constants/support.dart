/// The address a stuck user is told to contact.
///
/// Every Contact Support affordance is HIDDEN while this is empty — a button
/// that leads nowhere is worse than an absent one, particularly on the
/// awaiting-approval screen, where the person tapping it is already stuck
/// behind a review that has no admin client.
///
/// This is currently the only route a blocked supplier has to a human, so it
/// must be an inbox somebody actually reads. Worth revisiting before launch:
/// it is a personal address rather than a monitored support alias, which means
/// it cannot be handed over, has no shared history, and identifies an
/// individual to every supplier who gets stuck.
const String kSupportEmail = 'rashid.dev7@gmail.com';
