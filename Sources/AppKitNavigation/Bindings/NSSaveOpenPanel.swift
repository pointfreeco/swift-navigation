#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit
import AppKitNavigationShim

extension NSSavePanel {
    public convenience init(url: UIBinding<URL?>) {
        self.init()
        bind(url: url)
    }

    @discardableResult
    public func bind(url binding: UIBinding<URL?>) -> ObserveToken {
        appKitNavigation_onFinalURL = { url in
            binding.wrappedValue = url
        }

        let observationToken = ObserveToken { [weak self] in
            guard let self else { return }
            MainActor._assumeIsolated {
                self.appKitNavigation_onFinalURL = nil
            }
        }
        observationTokens[\NSSavePanel.url] = observationToken
        return observationToken
    }

    public func unbindURL() {
        observationTokens[\NSSavePanel.url]?.cancel()
        observationTokens[\NSSavePanel.url] = nil
    }
}

extension NSOpenPanel {
    public convenience init(urls: UIBinding<[URL]>) {
        self.init()
        bind(urls: urls)
    }

    @discardableResult
    public func bind(urls binding: UIBinding<[URL]>) -> ObserveToken {
        appKitNavigation_onFinalURLs = { urls in
            binding.wrappedValue = urls
        }

        let observationToken = ObserveToken { [weak self] in
            guard let self else { return }
            MainActor._assumeIsolated {
                self.appKitNavigation_onFinalURLs = nil
            }
        }
        observationTokens[\NSOpenPanel.urls] = observationToken
        return observationToken
    }

    public func unbindURLs() {
        observationTokens[\NSOpenPanel.urls]?.cancel()
        observationTokens[\NSOpenPanel.urls] = nil
    }
}

#endif
