import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TripListViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 260), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.trips) { trip in
                    TripCardView(trip: trip)
                }
            }
            .padding(20)
        }
        .navigationTitle("Trips")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.regenerateTrips() }
                } label: {
                    Label("重新智能整理", systemImage: "sparkles")
                }
            }
        }
        .task {
            await viewModel.requestAccessIfNeeded()
            await viewModel.regenerateTrips()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("智能整理中...")
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .alert("无法访问照片", isPresented: $viewModel.showPermissionAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("请在系统设置中为应用开启照片访问权限。")
        }
    }
}

#Preview {
    NavigationStack {
        ContentView(viewModel: TripListViewModel.preview)
    }
}
