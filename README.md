# KitoModals

**[Documentation](https://wyksofts-inc.github.io/KitoModals/documentation/kitomodals/)**

Route-based bottom sheets, one-binding confirmation dialogs, themed corner
radius and drag indicators for free.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoModals.git", from: "1.0.0"),
```

## Samples

**Delete confirmation (one binding, no state duplication):**
```swift
@State private var confirmation: KitoConfirmation?

var body: some View {
    List { /* ... */ }
        .kitoConfirmation($confirmation)
}

func deleteTapped(_ card: Card) {
    confirmation = KitoConfirmation(
        title: "Delete \(card.name)?",
        message: "This can't be undone.",
        confirmTitle: "Delete",
        isDestructive: true
    ) { viewModel.delete(card) }
}
```

**Route-based bottom sheet (only one sheet active at a time, by construction):**
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

**Card checkout — bottom sheet for card entry, confirmation before charging:**
```swift
enum CheckoutSheet: String, KitoSheetRoute { case addCard; var id: Self { self } }

@State private var sheets = KitoSheetPresenter<CheckoutSheet>()
@State private var confirmation: KitoConfirmation?

CheckoutView()
    .kitoBottomSheet(presenter: sheets) { _ in AddCardForm() }
    .kitoConfirmation($confirmation)

func payTapped() {
    confirmation = KitoConfirmation(title: "Charge $42.00?", confirmTitle: "Pay") {
        Task { await viewModel.charge() }
    }
}
```

**Blocking status dialog — pending → success/failure with animated draw-in icons:**
```swift
@State private var paymentStatus: KitoStatusDialogState?

CheckoutView()
    .kitoStatusDialog($paymentStatus)

func pay() async {
    paymentStatus = .pending(message: "Processing payment…")
    do {
        try await api.charge()
        paymentStatus = .success(message: "Payment complete")
    } catch {
        paymentStatus = .failure(message: "Payment failed")
    }
}
```

The checkmark and X are hand-drawn `Shape`s that trim in with an easing
curve (not a static SF Symbol fade); the surrounding circle pops in with a
spring. `.pending` spins indefinitely until you set the state to
`.success`/`.failure`, which then auto-dismiss after `autoDismissAfter`
seconds (default 1.6s; pass `nil` to require the caller to clear it).

## License

MIT

## Custom sheets

```swift
.kitoSheet(isPresented: $shows, configuration: KitoSheetConfiguration(
    detents: [.fit, .fraction(0.6), .large],   // drag between them; rubber-bands past the top
    style: .floating,                          // .attached, .glass
    blursBackdrop: true
)) { FiltersView() }
```

## Alerts, menus and tips

```swift
@State private var alert: KitoAlert?
.kitoAlert($alert)
alert = KitoAlert(systemImage: "trash.fill", title: "Delete account?", message: "This can't be undone.",
                  actions: [.cancel(), KitoAlertAction("Delete", role: .destructive) { delete() }])
alert = KitoAlert(systemImage: "party.popper.fill", title: "Order placed!", celebrates: true)   // confetti

.kitoActionMenu(isPresented: $shows, title: "Profile photo", actions: [
    KitoMenuAction("Take photo", systemImage: "camera") { … },
    KitoMenuAction("Remove photo", systemImage: "trash", isDestructive: true) { … },
])

Button { … }.kitoTooltip(isPresented: $tip, "Create your first list", edge: .top)
```

## Slide to confirm and hero cards

```swift
KitoSlideToConfirm("Slide to pay", systemImage: "creditcard.fill", tint: .green) { await pay() }

KitoHeroContainer {
    ScrollView {
        KitoHeroCard(id: story.id) { StoryFace(story) } expanded: { StoryBody(story) }
    }
}
```
