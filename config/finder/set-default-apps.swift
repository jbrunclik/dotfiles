// Sets Finder's default app per file type from a list file (see default-apps).
//
//   set-default-apps [--check] <list-file>
//
// Uses NSWorkspace.setDefaultApplication, which unlike duti also handles
// extensions no app declares a UTI for (.go, .rs, .toml — "dynamic" types).
// Each change that differs from the current handler triggers macOS's consent
// dialog; changes run sequentially so only one dialog is up at a time.
// --check reports what would change and exits 1 if anything would, without
// touching anything.
import AppKit
import UniformTypeIdentifiers

var args = Array(CommandLine.arguments.dropFirst())
let checkOnly = args.first == "--check"
if checkOnly { args.removeFirst() }
guard args.count == 1, let contents = try? String(contentsOfFile: args[0], encoding: .utf8) else {
    FileHandle.standardError.write("usage: set-default-apps [--check] <list-file>\n".data(using: .utf8)!)
    exit(2)
}

let ws = NSWorkspace.shared
var failures = 0

func bundleID(_ url: URL?) -> String? {
    url.flatMap { Bundle(url: $0)?.bundleIdentifier }
}

for rawLine in contents.split(separator: "\n") {
    let line = rawLine.trimmingCharacters(in: .whitespaces)
    if line.isEmpty || line.hasPrefix("#") { continue }
    let fields = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    guard fields.count == 2 else { print("  ?  malformed line: \(line)"); failures += 1; continue }
    let (appID, typeSpec) = (fields[0], fields[1])

    guard let appURL = ws.urlForApplication(withBundleIdentifier: appID) else {
        print("  ✗  \(typeSpec): \(appID) is not installed"); failures += 1; continue
    }
    let type = typeSpec.hasPrefix(".")
        ? UTType(filenameExtension: String(typeSpec.dropFirst()))
        : UTType(typeSpec)
    guard let type else { print("  ✗  \(typeSpec): unknown type"); failures += 1; continue }

    let current = bundleID(ws.urlForApplication(toOpen: type)) ?? "(none)"
    if current.caseInsensitiveCompare(appID) == .orderedSame {
        print("  ✓  \(typeSpec) -> \(appID)"); continue
    }
    if checkOnly {
        print("  ✗  \(typeSpec) -> \(current) (expected \(appID))"); failures += 1; continue
    }

    let done = DispatchSemaphore(value: 0)
    var failure: Error?
    ws.setDefaultApplication(at: appURL, toOpen: type) { failure = $0; done.signal() }
    done.wait()
    if let failure {
        print("  ✗  \(typeSpec): \(failure.localizedDescription)"); failures += 1
    } else {
        print("  ✓  \(typeSpec) -> \(appID) (was \(current))")
    }
}
exit(failures == 0 ? 0 : 1)
