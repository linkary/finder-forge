#!/usr/bin/env swift

import Foundation

struct WorkflowExpectation {
    let bundlePath: String
    let key: String
    let expectedByPreference: [(String, String)]
}

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let expectations: [WorkflowExpectation] = [
    .init(
        bundlePath: "workflows/New Text File Here.workflow",
        key: "New Text File Here",
        expectedByPreference: [
            ("zh-Hans", "在此新建文本文件"),
            ("zh-Hant", "在此新增文字檔"),
            ("fr", "New Text File Here"),
        ]
    ),
    .init(
        bundlePath: "workflows/Open in Qoder.workflow",
        key: "Open in Qoder",
        expectedByPreference: [
            ("zh-Hans", "在 Qoder 中打开"),
            ("zh-Hant", "在 Qoder 中打開"),
            ("fr", "Open in Qoder"),
        ]
    ),
    .init(
        bundlePath: "workflows/Open in Cursor.workflow",
        key: "Open in Cursor",
        expectedByPreference: [
            ("zh-Hans", "在 Cursor 中打开"),
            ("zh-Hant", "在 Cursor 中打開"),
            ("fr", "Open in Cursor"),
        ]
    ),
    .init(
        bundlePath: "workflows/Open in Code.workflow",
        key: "Open in Code",
        expectedByPreference: [
            ("zh-Hans", "在 Code 中打开"),
            ("zh-Hant", "在 Code 中打開"),
            ("fr", "Open in Code"),
        ]
    ),
]

func resolvedString(bundle: Bundle, key: String, preferredLanguages: [String]) -> (String?, String) {
    let chosenLocalizations = Bundle.preferredLocalizations(from: bundle.localizations, forPreferences: preferredLanguages)
    if let chosen = chosenLocalizations.first,
       let lproj = bundle.path(forResource: chosen, ofType: "lproj"),
       let localizedBundle = Bundle(path: lproj) {
        return (chosen, localizedBundle.localizedString(forKey: key, value: nil, table: "ServicesMenu"))
    }

    return (nil, bundle.localizedString(forKey: key, value: nil, table: "ServicesMenu"))
}

var failures: [String] = []

for expectation in expectations {
    let bundleURL = repoRoot.appendingPathComponent(expectation.bundlePath)
    guard let bundle = Bundle(path: bundleURL.path) else {
        failures.append("Missing bundle: \(expectation.bundlePath)")
        continue
    }

    for (preferredLanguage, expected) in expectation.expectedByPreference {
        let (resolvedLocalization, resolvedValue) = resolvedString(
            bundle: bundle,
            key: expectation.key,
            preferredLanguages: [preferredLanguage]
        )

        let localizationLabel = resolvedLocalization ?? "fallback"
        if resolvedValue == expected {
            print("PASS \(expectation.bundlePath) [\(preferredLanguage) -> \(localizationLabel)] = \(resolvedValue)")
        } else {
            failures.append(
                "FAIL \(expectation.bundlePath) [\(preferredLanguage) -> \(localizationLabel)] expected '\(expected)' got '\(resolvedValue)'"
            )
        }
    }
}

if failures.isEmpty {
    print("All workflow localizations resolved as expected.")
    exit(0)
}

for failure in failures {
    fputs(failure + "\n", stderr)
}
exit(1)
