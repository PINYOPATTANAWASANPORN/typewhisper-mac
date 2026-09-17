import XCTest
import TypeWhisperPluginSDK
@_spi(Testing) import TypeWhisperPluginSDKTesting
@testable import DeepgramPlugin

final class DeepgramPluginTests: XCTestCase {
    override func tearDown() {
        PluginHTTPClientTestHarness.reset()
        super.tearDown()
    }

    func testSupportedLanguagesForNova3IncludesArabicAndKazakh() {
        let nova3Languages = DeepgramPlugin.supportedLanguages(for: "nova-3")
        XCTAssertTrue(nova3Languages.contains("ar"), "Nova-3 should support Arabic (ar)")
        XCTAssertTrue(nova3Languages.contains("kk"), "Nova-3 should support Kazakh (kk)")
        XCTAssertTrue(nova3Languages.contains("en"), "Nova-3 should support English (en)")
        XCTAssertTrue(nova3Languages.contains("de"), "Nova-3 should support German (de)")
        XCTAssertEqual(nova3Languages.count, 48)
    }

    func testSupportedLanguagesForNova2ExcludesNova3OnlyLanguages() {
        let nova2Languages = DeepgramPlugin.supportedLanguages(for: "nova-2")
        XCTAssertFalse(nova2Languages.contains("ar"), "Nova-2 should not advertise Arabic (ar)")
        XCTAssertFalse(nova2Languages.contains("kk"), "Nova-2 should not advertise Kazakh (kk)")
        XCTAssertTrue(nova2Languages.contains("en"), "Nova-2 should support English (en)")
        XCTAssertTrue(nova2Languages.contains("de"), "Nova-2 should support German (de)")
        XCTAssertEqual(nova2Languages.count, 46)
    }

    func testDynamicSupportedLanguagesFollowsSelectedModel() throws {
        let host = try PluginTestHostServices()
        let plugin = DeepgramPlugin()
        plugin.activate(host: host)

        // Default model is Nova-3
        plugin.selectModel("nova-3")
        XCTAssertTrue(plugin.supportedLanguages.contains("ar"))
        XCTAssertTrue(plugin.supportedLanguages.contains("kk"))

        // Switching to Nova-2 updates supported languages
        plugin.selectModel("nova-2")
        XCTAssertFalse(plugin.supportedLanguages.contains("ar"))
        XCTAssertFalse(plugin.supportedLanguages.contains("kk"))
        XCTAssertTrue(plugin.supportedLanguages.contains("en"))

        // Switching back to Nova-3 restores full language set
        plugin.selectModel("nova-3")
        XCTAssertTrue(plugin.supportedLanguages.contains("ar"))
        XCTAssertTrue(plugin.supportedLanguages.contains("kk"))
    }

    func testRestRequestURLPreservesSupportedLanguageParameter() throws {
        let url = try DeepgramPlugin.restRequestURL(
            baseURL: "https://api.deepgram.com",
            modelId: "nova-3",
            language: "ar",
            prompt: nil
        )

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to parse URL components")
            return
        }

        let queryItems = components.queryItems ?? []
        let languageItem = queryItems.first { $0.name == "language" }
        XCTAssertEqual(languageItem?.value, "ar")

        let modelItem = queryItems.first { $0.name == "model" }
        XCTAssertEqual(modelItem?.value, "nova-3")
    }

    func testStreamingRequestURLPreservesSupportedLanguageParameter() throws {
        let url = try DeepgramPlugin.streamingRequestURL(
            baseURL: "https://api.deepgram.com",
            modelId: "nova-3",
            language: "kk",
            prompt: nil
        )

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to parse URL components")
            return
        }

        let queryItems = components.queryItems ?? []
        let languageItem = queryItems.first { $0.name == "language" }
        XCTAssertEqual(languageItem?.value, "kk")

        let modelItem = queryItems.first { $0.name == "model" }
        XCTAssertEqual(modelItem?.value, "nova-3")
    }
}
