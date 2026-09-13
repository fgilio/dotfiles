import Foundation

// Runs bin/sublime-session-backup with this bundle's TCC identity.
//
// The job writes into ~/Library/CloudStorage, which macOS gates behind a
// per-app "Files and Folders" grant for the File Provider (Google Drive). A
// LaunchAgent that runs a bash script has nothing to grant: measured on macOS
// 26, every read, listing, overwrite, rename and delete of a synced item fails
// with EPERM and no prompt is ever shown; only creating a new file works. A
// child process inherits its parent's TCC responsibility, so running the
// script from inside an ad-hoc signed .app gives it this bundle's identity:
// the first run prompts for Google Drive access once, and the grant is keyed
// to the bundle ID, so rebuilds keep it.
@main
struct SublimeSessionBackup {
    static func main() {
        let script = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".dotfiles/bin/sublime-session-backup")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script.path]
        do {
            try process.run()
        } catch {
            fputs("error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
        process.waitUntilExit()
        exit(process.terminationStatus)
    }
}
