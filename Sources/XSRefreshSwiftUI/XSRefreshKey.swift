//
//  XSRefreshKey.swift
//  XSRefreshSwiftUI
//
//  Created by 韩云智 on 2026/1/13.
//

import SwiftUI

struct XSRefreshKey {
    static let defaultValue: Value = []
}

extension XSRefreshKey: PreferenceKey {
    typealias Value = [Item]
    struct Item {
        let bounds: Anchor<CGRect>
        let type: XSRefreshComponentType
    }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    func xsRefreshAnchor(_ type: XSRefreshComponentType = .content) -> some View {
        anchorPreference(key: XSRefreshKey.self, value: .bounds) {
            [.init(bounds: $0, type: type)]
        }
    }
}
