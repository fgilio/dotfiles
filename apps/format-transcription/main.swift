import Foundation
import FoundationModels

@main
struct FormatTranscription {
    static func main() async {
        do {
            try await run()
            exit(0)
        } catch {
            fputs("error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    static func run() async throws {
        let args = Array(CommandLine.arguments.dropFirst())
        guard args.count == 2 else {
            fputs("usage: FormatTranscription <input.txt> <output.md>\n", stderr)
            throw ExitError()
        }

        let inputURL = URL(fileURLWithPath: args[0]).standardizedFileURL
        let outputURL = URL(fileURLWithPath: args[1]).standardizedFileURL

        let input = try String(contentsOf: inputURL, encoding: .utf8)
        guard !input.isEmpty else {
            fputs("error: input file is empty\n", stderr)
            throw ExitError()
        }

        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            fputs("model unavailable: \(model.availability)\n", stderr)
            throw ExitError()
        }

        let session = LanguageModelSession()
        let response = try await session.respond(to: """
            Format this raw audio transcription into clean, readable Markdown. \
            Fix punctuation, add paragraph breaks, use headers if there are distinct topics. \
            Keep the ORIGINAL LANGUAGE of the transcription - do NOT translate. \
            Do NOT add content that isn't in the original. Output ONLY the formatted Markdown, \
            without wrapping it in code fences.

            Transcription:
            \(input)
            """)

        try response.content.write(to: outputURL, atomically: true, encoding: .utf8)
    }
}

struct ExitError: Error {}
