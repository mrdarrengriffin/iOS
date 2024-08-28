import Shared
import SwiftUI

struct WatchHomeRowView: View {
    enum RowState {
        case idle
        case loading
        case success
        case failure
    }

    let item: MagicItem
    let itemInfo: MagicItem.Info
    let action: (MagicItem, @escaping (Bool) -> Void) -> Void

    @State private var state: RowState = .idle
    @State private var showConfirmationDialog = false

    var body: some View {
        Button {
            guard state != .loading else { return }
            if item.customization?.requiresConfirmation ?? false {
                showConfirmationDialog = true
            } else {
                executeMainAction()
            }
        } label: {
            HStack(spacing: Spaces.one) {
                iconToDisplay
                    .animation(.bouncy, value: state)
                Text(itemInfo.name)
                    .font(.footnote.bold())
                    .foregroundStyle(textColor)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing)
            }
        }
        .listRowBackground(backgroundForWatchItem.cornerRadius(14))
        .confirmationDialog(
            L10n.Watch.Home.Run.Confirmation.title(itemInfo.name),
            isPresented: $showConfirmationDialog,
            actions: {
                Button(action: {
                    executeMainAction()
                }, label: {
                    Text(L10n.yesLabel)
                })
                Button(action: {}, label: {
                    Text(L10n.cancelLabel)
                })
                .tint(.red)
            }
        )
        .modify { view in
            if let backgroundColor = item.customization?.backgroundColor {
                view.listRowBackground(
                    Color(uiColor: .init(hex: backgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                )
            } else {
                view
            }
        }
        .onChange(of: state) { newValue in
            // TODO: On watchOS 10 this can be replaced by '.sensoryFeedback' modifier
            let currentDevice = WKInterfaceDevice.current()
            switch newValue {
            case .success:
                currentDevice.play(.success)
            case .failure:
                currentDevice.play(.failure)
            case .loading:
                currentDevice.play(.click)
            default:
                break
            }
        }
    }

    private func executeMainAction() {
        state = .loading
        action(item) { success in
            state = success ? .success : .failure
            resetState()
        }
    }

    private var iconToDisplay: some View {
        VStack {
            switch state {
            case .idle:
                Image(uiImage: image)
                    .foregroundStyle(Color(uiColor: .init(hex: itemInfo.customization?.iconColor)))
                    .padding()
            case .loading:
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 24, height: 24)
                    .shadow(color: .white, radius: 10)
                    .padding()
            case .success:
                makeStateImage(systemName: "checkmark.circle.fill")
            case .failure:
                makeStateImage(systemName: "xmark.circle")
            }
        }
        .frame(width: 38, height: 38)
        .background(Color(uiColor: .init(hex: itemInfo.customization?.iconColor)).opacity(0.3))
        .clipShape(Circle())
        .padding([.vertical, .trailing], Spaces.half)
    }

    private func makeStateImage(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 24))
            .foregroundStyle(.white)
            .padding()
    }

    private func resetState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            state = .idle
        }
    }

    private var textColor: Color {
        if let textColor = item.customization?.textColor {
            .init(uiColor: .init(hex: textColor))
        } else {
            .white
        }
    }

    private var backgroundForWatchItem: Color {
        if let backgroundColor = itemInfo.customization?.backgroundColor {
            Color(uiColor: .init(hex: backgroundColor))
        } else {
            .gray.opacity(0.3)
        }
    }

    private var image: UIImage {
        var icon: MaterialDesignIcons
        switch item.type {
        case .action, .scene:
            icon = MaterialDesignIcons(named: itemInfo.iconName, fallback: .scriptTextOutlineIcon)
        case .script:
            icon = MaterialDesignIcons(serversideValueNamed: itemInfo.iconName, fallback: .scriptTextOutlineIcon)
        }

        return icon.image(
            ofSize: .init(width: 24, height: 24),
            color: .init(hex: itemInfo.customization?.iconColor)
        )
    }
}

#Preview {
    MaterialDesignIcons.register()
    return List {
        WatchHomeRowView(
            item: .init(id: "1", serverId: "1", type: .script),
            itemInfo: .init(
                id: "1",
                name: "New script",
                iconName: "mdi:door-closed-lock",
                customization: .init(backgroundColor: "#ff00ff")
            )
        ) { _, _ in }
        WatchHomeRowView(
            item: .init(id: "1", serverId: "1", type: .action),
            itemInfo: .init(id: "1", name: "New Action", iconName: "earth")
        ) { _, _ in }
    }
    .background(Color.red)
}
