//
//  NoteText.swift
//  shinobuetuner
//
//  音名・階名・運指名を ♯/♭ 付きで表示する Text を生成する共通ヘルパー

import SwiftUI

extension Text {
    /// ♯/♭ を小さく上付きで表示する Text を生成する
    /// - AttributedString を使用（iOS 26 で Text + Text が deprecated のため）
    /// - 記号は本文の50%サイズ・25%分ベースラインを上げて表示
    /// - Parameters:
    ///   - text: 表示する文字列（例: "ファ♯", "B♭4"）
    ///   - size: 本文のフォントサイズ
    ///   - weight: 本文のフォントウェイト
    ///   - design: 本文のフォントデザイン
    static func note(
        _ text: String,
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design = .default
    ) -> Text {
        let symbolSize = size * 0.50
        let offset = size * 0.25
        var attrStr = AttributedString()
        var buffer = ""
        for char in text {
            if char == "♯" || char == "♭" {
                if !buffer.isEmpty {
                    var part = AttributedString(buffer)
                    part.font = Font.system(size: size, weight: weight, design: design)
                    attrStr.append(part)
                    buffer = ""
                }
                var sym = AttributedString(String(char))
                sym.font = Font.system(size: symbolSize, weight: weight)
                sym.baselineOffset = offset
                attrStr.append(sym)
            } else {
                buffer.append(char)
            }
        }
        if !buffer.isEmpty {
            var part = AttributedString(buffer)
            part.font = Font.system(size: size, weight: weight, design: design)
            attrStr.append(part)
        }
        return Text(attrStr)
    }
}
