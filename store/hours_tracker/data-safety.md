# Data safety answers (draft)

For Google Play's Data safety form and Apple's App Privacy labels. Valid for
the current build, which has no analytics, ads or network calls of its own.

## Google Play
- **Does your app collect or share any of the required user data types?** No (this build).
- **Is all user data encrypted in transit?** Not applicable: the app sends no user data.
- **Do you provide a way for users to request that their data be deleted?** Data lives only on the device; uninstalling or deleting entries removes it.
- **Exports:** CSV/PDF files are created on the device and handed to the system share sheet at the person's request. Play treats user-initiated sharing like this as not "shared" by the developer.

## Apple App Privacy
- **Data Not Collected** (this build).

## Re-check when RevenueCat is added
RevenueCat receives store receipts and an anonymous app user id. At that
point Play's form will likely need **Purchase history** (and possibly an app
user id under Device or other IDs) marked as collected, for app
functionality, not shared, not used for tracking; Apple's label likewise
moves to "Purchases, not linked to identity" depending on configuration.
Use RevenueCat's own published guidance for these forms at that time.
