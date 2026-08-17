import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: RailStore
    @State private var selectedTab = 0

    var body: some View {
        if !store.onboardingDone {
            OnboardingView()
                .environmentObject(store)
        } else {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        TableView()
                            .environmentObject(store)
                    case 1:
                        NavigationView { DepotView().environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { OrdersView().environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { LearnView().environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { JournalView().environmentObject(store) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, icon: .table, label: "Table")
            tabButton(1, icon: .depot, label: "Depot")
            tabButton(2, icon: .orders, label: "Orders")
            tabButton(3, icon: .learn, label: "Learn")
            tabButton(4, icon: .journal, label: "Journal")
        }
        .padding(.top, 9)
        .padding(.bottom, 3)
        .background(
            RailTheme.paper
                .overlay(Rectangle().fill(RailTheme.ink.opacity(0.08)).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, icon: RIconKind, label: String) -> some View {
        Button {
            if selectedTab != index {
                selectedTab = index
                RailHaptics.tap()
            }
        } label: {
            VStack(spacing: 3) {
                RIcon(kind: icon, size: 23, color: selectedTab == index ? RailTheme.pine : RailTheme.inkFaint.opacity(0.75))
                Text(label)
                    .font(RailTheme.body(10))
                    .foregroundColor(selectedTab == index ? RailTheme.pine : RailTheme.inkFaint.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
