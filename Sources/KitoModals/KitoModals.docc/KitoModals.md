# ``KitoModals``

Route-based bottom sheets, custom sheets, confirmations, alerts, and status dialogs for SwiftUI.

## Overview

KitoModals drives every modal on a screen from a single piece of state. A
confirmation is one optional ``KitoConfirmation`` binding, a blocking status
dialog is one optional ``KitoStatusDialogState``, and a screen's bottom sheets
are owned by a ``KitoSheetPresenter`` whose `route` is a single optional, so
only one sheet can be active at a time by construction.

Define the sheets a screen can show as a ``KitoSheetRoute`` and present them
through the presenter with `kitoBottomSheet(presenter:detents:content:)`:

```swift
enum ProfileSheet: String, KitoSheetRoute {
    case editPhoto, editBio
    var id: Self { self }
}

@State private var sheets = KitoSheetPresenter<ProfileSheet>()

var body: some View {
    ProfileView()
        .kitoBottomSheet(presenter: sheets, detents: [.medium, .large]) { route in
            switch route {
            case .editPhoto: EditPhotoView()
            case .editBio: EditBioView()
            }
        }
        .toolbar {
            Button("Edit photo") { sheets.present(.editPhoto) }
        }
}
```

For full control over appearance, `kitoSheet(isPresented:configuration:content:)`
draws a custom sheet described by a ``KitoSheetConfiguration``: detents you
drag between, attached, floating, or glass styles, and an optional blurred
backdrop. The package also provides themed alerts with optional confetti
(`kitoAlert(_:)`), action menus (`kitoActionMenu`), tooltips (`kitoTooltip`),
a slide-to-confirm control, and expanding hero cards. Every view reads its
colors, spacing, and corner radii from the KitoCore theme.

## Topics

### Bottom Sheets

- ``KitoSheetRoute``
- ``KitoSheetPresenter``
- ``KitoBottomSheetModifier``

### Custom Sheets

- ``KitoSheetConfiguration``
- ``KitoSheetDetent``
- ``KitoSheetStyle``
- ``KitoSheetContentMode``

### Confirmations and Status

- ``KitoConfirmation``
- ``KitoStatusDialogState``
- ``KitoStatusDialogView``

### Alerts and Menus

- ``KitoAlert``
- ``KitoAlertAction``
- ``KitoMenuAction``
- ``KitoConfetti``

### Controls and Transitions

- ``KitoSlideToConfirm``
- ``KitoHeroContainer``
- ``KitoHeroCard``
