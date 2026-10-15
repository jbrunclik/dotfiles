// Renders the printable cheatsheet: an A4 landscape PDF, one page per entry.
//
//   Page 1: every Hyper binding, from the JSON written by
//           hyperCheatsheetExport() in init.lua (what the hold-Hyper overlay
//           shows).
//   Then:   the GUIDE sections listed in `pages` below — their tables, and
//           `command  # explanation` lines from their code blocks.
//
// Everything comes from the config and GUIDE.md, nothing is listed by hand, so
// the printout can't drift. A listed section missing from GUIDE.md is an error
// rather than a silently shorter sheet. Each page shrinks its font until it
// fits. Rendering uses WebKit's createPDF and PDFKit — macOS only, no other
// dependencies. Run via the hyper-cheatsheet script:
//   cheatsheet-pdf <bindings.json> <GUIDE.md> <out.pdf>

import AppKit
import PDFKit
import WebKit

// GUIDE.md headings (## or ###, exact text) shown on each page after Hyper.
// Keyboard shortcuts only: command-line usage doesn't need a printout.
let pages: [(title: String, sections: [String])] = [
    ("Keyboard", [
        "Terminal (Ghostty)", "Line editing (readline)", "Fuzzy finder (fzf)",
        "Text editing everywhere (macOS)", "macOS essentials",
    ]),
]

struct Entry: Decodable { let key: String; let desc: String }
struct Section: Decodable { let name: String; let note: String?; let entries: [Entry] }
struct Sheet: Decodable { let sections: [Section]; let caps: String? }

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

let args = CommandLine.arguments
guard args.count == 4 else { fail("usage: cheatsheet-pdf <bindings.json> <GUIDE.md> <out.pdf>") }
guard let data = FileManager.default.contents(atPath: args[1]),
      let hyper = try? JSONDecoder().decode(Sheet.self, from: data) else {
    fail("cannot read cheatsheet JSON from \(args[1])")
}
guard let guide = try? String(contentsOfFile: args[2], encoding: .utf8) else {
    fail("cannot read \(args[2])")
}
let output = URL(fileURLWithPath: args[3])

// MARK: - GUIDE.md parsing

func esc(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
     .replacingOccurrences(of: "<", with: "&lt;")
     .replacingOccurrences(of: ">", with: "&gt;")
}

// Escape, then the little inline Markdown the GUIDE tables use. Code spans
// first, and bold/links only outside them: `vim **` must keep its asterisks.
// Double-backtick spans (``Ctrl+` ``) hold a literal backtick, so they're
// swapped for placeholders before splitting on single backticks.
func inline(_ s: String) -> String {
    var text = esc(s)
    var literal: [String] = []
    while let m = text.range(of: #"``\s?(.+?)\s?``"#, options: .regularExpression) {
        let inner = String(text[m].dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespaces)
        literal.append("<code>\(inner)</code>")
        text.replaceSubrange(m, with: "\u{1}\(literal.count - 1)\u{1}")
    }
    let parts = text.components(separatedBy: "`")  // odd indices are code
    var out = ""
    var i = 0
    while i < parts.count {
        if i % 2 == 1 && i < parts.count - 1 {
            out += "<code>\(parts[i])</code>"
        } else {
            out += parts[i]
                .replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
                .replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "<b>$1</b>", options: .regularExpression)
        }
        i += 1
    }
    for (n, code) in literal.enumerated() {
        out = out.replacingOccurrences(of: "\u{1}\(n)\u{1}", with: code)
    }
    return out
}

struct Row { let key: String; let desc: String }  // already HTML

// Body of the section headed `name`: up to the next ## or ### heading
func guideSection(_ name: String) -> [String]? {
    let lines = guide.components(separatedBy: "\n")
    var inCode = false
    var start: Int?
    for (i, l) in lines.enumerated() {
        if l.hasPrefix("```") { inCode.toggle() }
        if !inCode && (l == "## \(name)" || l == "### \(name)") { start = i; break }
    }
    guard let start else { return nil }
    var body: [String] = []
    inCode = false
    for l in lines[(start + 1)...] {
        if l.hasPrefix("```") { inCode.toggle() }
        if !inCode && (l.hasPrefix("## ") || l.hasPrefix("### ")) { break }
        body.append(l)
    }
    return body
}

func cells(_ line: String) -> [String] {
    line.trimmingCharacters(in: CharacterSet(charactersIn: "| "))
        .components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
}

func rows(of body: [String]) -> [Row] {
    var result: [Row] = []
    var i = 0
    while i < body.count {
        let line = body[i]
        if line.hasPrefix("```") {
            // Code block: keep `command   # explanation` lines
            i += 1
            while i < body.count && !body[i].hasPrefix("```") {
                let l = body[i]
                if !l.hasPrefix("#"), let hash = l.range(of: #"\s{2,}#\s"#, options: .regularExpression) {
                    let cmd = l[..<hash.lowerBound].trimmingCharacters(in: .whitespaces)
                    let desc = l[hash.upperBound...].trimmingCharacters(in: .whitespaces)
                    result.append(Row(key: "<code>\(esc(cmd))</code>", desc: inline(desc)))
                }
                i += 1
            }
        } else if line.hasPrefix("|"), i + 1 < body.count,
                  body[i + 1].range(of: #"^\|[-| :]+\|$"#, options: .regularExpression) != nil {
            // Table: the Shortcut/Keys/Command column is the key, the other the text
            let header = cells(line).map { $0.lowercased() }
            let keyCol = header.firstIndex(where: { ["shortcut", "keys", "command"].contains($0) }) ?? 1
            let descCol = keyCol == 0 ? 1 : 0
            i += 2
            while i < body.count && body[i].hasPrefix("|") {
                let c = cells(body[i])
                if c.count > max(keyCol, descCol) {
                    result.append(Row(key: inline(c[keyCol]), desc: inline(c[descCol])))
                }
                i += 1
            }
            continue
        }
        i += 1
    }
    return result
}

// MARK: - HTML

func sectionHTML(_ name: String, note: String?, rows: [Row]) -> String {
    let n = note.map { " <small>· \(esc($0))</small>" } ?? ""
    let r = rows.map { "<tr><td class=k>\($0.key)</td><td>\($0.desc)</td></tr>" }.joined()
    return "<section><h2>\(esc(name))\(n)</h2><table>\(r)</table></section>"
}

// A4 landscape in points; WebKit's PDF output maps 1 CSS px to 1 point
let page = CGSize(width: 842, height: 595)
let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)

// keyWidth: share of each column for the key; long GUIDE shortcuts need more
func pageHTML(title: String, subtitle: String, body: String, source: String, keyWidth: Int) -> String {
    """
    <!doctype html><meta charset=utf-8>
    <style>
      html { font-size: 12.5px }
      html, body { margin: 0; background: #fff }
      body { width: \(Int(page.width))px; height: \(Int(page.height))px; box-sizing: border-box;
             padding: 32px 40px 20px; display: flex; flex-direction: column; overflow: hidden;
             font-family: "Maple Mono NF", Menlo, monospace; color: #4c4f69 }
      h1 { margin: 0; font-size: 1.9rem; color: #8839ef }
      .sub { margin-top: .4rem; font-size: .88rem; line-height: 1.5; color: #6c6f85 }
      .cols { flex: 1; min-height: 0; margin-top: 1.2rem; column-count: 3; column-gap: 30px;
              column-fill: balance }
      /* inline-block: WebKit otherwise offsets a section that starts a column */
      section { display: inline-block; width: 100%; break-inside: avoid; margin-bottom: 1.1rem }
      h2 { margin: 0 0 .45rem; padding-bottom: .25rem; font-size: 1.1rem; color: #1e66f5;
           border-bottom: 1px solid #ccd0da }
      h2 small { font-weight: normal; font-size: .85rem; color: #6c6f85 }
      /* fixed layout: long keys wrap inside their cell instead of spilling into
         the next column, where they'd overlap it */
      table { border-collapse: collapse; width: 100%; table-layout: fixed }
      td { padding: .22rem .6rem .22rem 0; vertical-align: top; overflow-wrap: anywhere }
      td.k { width: \(keyWidth)%; font-weight: bold; color: #8839ef }
      code { font-family: inherit }
      footer { margin-top: .5rem; font-size: .72rem; color: #9ca0b0 }
    </style>
    <h1>\(esc(title))</h1>
    <div class=sub>\(subtitle)</div>
    <div class=cols>\(body)</div>
    <footer>Generated \(esc(date)) from \(source) · regenerate with <b>hyper-cheatsheet</b></footer>
    <script>
      // Shrink until every section sits whole inside the columns area: not
      // split across columns, not past its bottom, no extra column to the right
      function overflowing() {
        const box = document.querySelector('.cols').getBoundingClientRect();
        return [...document.querySelectorAll('section')].some(s => {
          const r = s.getBoundingClientRect();
          return s.getClientRects().length > 1 || r.bottom > box.bottom + 1 || r.right > box.right + 1;
        });
      }
      function fit() {
        const root = document.documentElement;
        let size = 12.5;
        while (size > 6 && overflowing()) {
          size -= 0.25;
          root.style.fontSize = size + 'px';
        }
        return size;
      }
    </script>
    """
}

var documents: [String] = []

let hyperBody = hyper.sections.map { s in
    sectionHTML(s.name, note: s.note, rows: s.entries.map { Row(key: esc($0.key), desc: esc($0.desc)) })
}.joined()
documents.append(pageHTML(
    title: "Hyper",
    subtitle: "Hold Caps Lock (or the Keyboardio Hyper key) = Cmd+Opt+Ctrl+Shift, then press a key."
        + (hyper.caps.map { "<br>" + esc($0) } ?? ""),
    body: hyperBody,
    source: "bindHyper (init.lua) and karabiner.json",
    keyWidth: 26))

for p in pages {
    let body = p.sections.map { name -> String in
        guard let lines = guideSection(name) else {
            fail("GUIDE.md has no section \"\(name)\" — update `pages` in cheatsheet-pdf.swift")
        }
        let r = rows(of: lines)
        if r.isEmpty { fail("GUIDE.md section \"\(name)\" has no table or commented commands") }
        return sectionHTML(name, note: nil, rows: r)
    }.joined()
    documents.append(pageHTML(
        title: p.title,
        subtitle: "From the dotfiles GUIDE — pick a few to learn at a time.",
        body: body,
        source: "GUIDE.md",
        keyWidth: 46))
}

// MARK: - Rendering

final class Renderer: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    var index = 0
    let result = PDFDocument()

    init(webView: WKWebView) {
        self.webView = webView
        super.init()
        webView.navigationDelegate = self
    }

    func start() { webView.loadHTMLString(documents[index], baseURL: nil) }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Fit only once fonts are in, or it measures the fallback font
        webView.callAsyncJavaScript("await document.fonts.ready; return fit();",
                                    arguments: [:], in: nil, in: .page) { fitted in
            if case .failure(let error) = fitted { fail("fitting page \(self.index + 1) failed: \(error)") }
            let config = WKPDFConfiguration()
            config.rect = CGRect(origin: .zero, size: page)
            webView.createPDF(configuration: config) { pdf in
                guard case .success(let data) = pdf, let doc = PDFDocument(data: data),
                      let rendered = doc.page(at: 0) else {
                    fail("PDF rendering failed for page \(self.index + 1)")
                }
                self.result.insert(rendered, at: self.result.pageCount)
                self.index += 1
                if self.index < documents.count {
                    self.start()
                } else {
                    guard self.result.write(to: output) else { fail("cannot write \(output.path)") }
                    exit(0)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail("HTML load failed: \(error)")
    }
}

_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)
let renderer = Renderer(webView: WKWebView(frame: NSRect(origin: .zero, size: page)))
renderer.start()
RunLoop.main.run()
