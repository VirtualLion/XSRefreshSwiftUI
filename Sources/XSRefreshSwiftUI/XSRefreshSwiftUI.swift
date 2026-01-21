// 
//  XSRefreshSwiftUI
//
//  Created by 韩云智 on 2026/1/13.
//
// https://docs.swift.org/swift-book

import SwiftUI

public enum XSRefresh {
    static var headerLastUpdatedTimeKey: String { "XSRefreshHeaderLastUpdatedTimeKey" }
}

public enum XSRefreshState: Equatable {
    case none
    /** 普通闲置状态 */
    case idle
    /** 松开就可以进行刷新的状态 */
    case pulling
    /** 正在刷新中的状态 */
    case refreshing
    /** 完成刷新的状态 */
    case endRefresh
    /** 所有数据加载完毕，没有更多的数据了 */
    case noMoreData
}

extension Binding<XSRefreshState> {
    @MainActor
    public func endRefresh(noMore: Bool = false) {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            wrappedValue = noMore ? .noMoreData : .endRefresh
        }
    }
}


