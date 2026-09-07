/// The address a stuck user is told to contact.
///
/// EMPTY, and that is not an oversight: no support address exists anywhere in
/// either repository or in the API's environment. Rather than invent one, every
/// Contact Support affordance is HIDDEN while this is empty — a button that
/// leads nowhere is worse than an absent one, particularly on the
/// awaiting-approval screen, where the person tapping it is already stuck.
///
/// Set it here and the buttons appear. One line, no other change.
///
/// It must be a real, monitored inbox: the supplier reaching for it is blocked
/// behind an admin review that has no client, so this is currently the only
/// route they have to a human.
const String kSupportEmail = '';
