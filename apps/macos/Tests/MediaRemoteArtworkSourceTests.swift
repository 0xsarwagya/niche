import Foundation
import Testing
@testable import Niche

struct MediaRemoteArtworkSourceTests {
    @Test func decodesBase64Artwork() throws {
        let bytes = Data([0x89, 0x50, 0x4e, 0x47])
        let json = Data(#"{"artworkData":"\#(bytes.base64EncodedString())"}"#.utf8)
        let decoded = try #require(MediaRemoteArtworkSource.artworkData(fromGetOutput: json))
        #expect(decoded == bytes)
    }

    @Test func missingArtworkReturnsNil() {
        let json = Data(#"{"title":"x"}"#.utf8)
        #expect(MediaRemoteArtworkSource.artworkData(fromGetOutput: json) == nil)
    }
}
