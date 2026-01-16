//
//  XSRefreshComponent.swift
//  XSRefreshSwiftUI
//
//  Created by 韩云智 on 2026/1/13.
//

import SwiftUI

enum XSRefreshComponentType: Equatable {
    case header, footer_auto, footer_back, content
}

struct XSRefreshComponent<Label: View> {
    let type: XSRefreshComponentType
    let label: () -> Label
    init(type: XSRefreshComponentType, label: @escaping () -> Label) {
        self.type = type
        self.label = label
    }
}

public struct XSRefreshHeader {
    var state: XSRefreshState
    var date: Date?
    init(state: XSRefreshState, date: Date?) {
        self.state = state
        self.date = date
    }
}

public struct XSRefreshFooter {
    var state: XSRefreshState
    let type: XSRefreshComponentType
    init(state: XSRefreshState, type: XSRefreshComponentType) {
        self.state = state
        self.type = type
    }
}

extension XSRefreshComponent: View {
    var body: some View {
        label().frame(maxWidth: .infinity).xsRefreshAnchor(type)
    }
}

extension XSRefreshHeader: View {
    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                switch state {
                case .refreshing: XSActivityView()
                case .endRefresh: Image(systemName: "checkmark")
                default:
                    let angle = Angle(degrees: state == .idle ? 0 : 180)
                    Image(systemName: "arrow.down")
                        .resizable(capInsets: EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                        .frame(width: 15, height: 25)
                        .rotationEffect(-angle)
                        .animation(.default, value: angle)
                }
                
            }.frame(width: 30, height: 30)
            VStack(spacing: 12) {
                if state == .endRefresh {
                    Text("已经完成数据刷新")
                    Text("最后更新：" + dateStr)
                } else {
                    switch state {
                    case .refreshing: Text("正在刷新数据中...")
                    case .pulling: Text("松开立即刷新")
                    default: Text("下拉可以刷新")
                    }
                    Text("最后更新：" + dateStr)
                }
            }
        }
        .padding()
        .lineLimit(1)
    }
    private var dateStr: String {
        guard let date = date else { return "无记录" }
        // 1.获得年月日
        let calendar = Calendar(identifier: .gregorian)
        let fm = DateFormatter()
        if calendar.isDateInToday(date) { // 今天
            fm.dateFormat = "今天 HH:mm"
        } else if calendar.compare(date, to: Date(), toGranularity: .year) == .orderedSame { // 今年
            fm.dateFormat = "MM-dd HH:mm"
        } else {
            fm.dateFormat = "yyyy-MM-dd HH:mm"
        }
        return fm.string(from: date)
    }
}

extension XSRefreshFooter: View {
    public var body: some View {
        HStack(spacing: 12) {
            if type == .footer_back {
                if state == .noMoreData {
                    Text("已经全部加载完毕")
                } else {
                    ZStack {
                        switch state {
                        case .refreshing: XSActivityView()
                        case .endRefresh: Image(systemName: "checkmark")
                        default:
                            let angle = Angle(degrees: state == .idle ? 180 : 0)
                            Image(systemName: "arrow.down")
                                .resizable(capInsets: EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                                .frame(width: 15, height: 25)
                                .rotationEffect(-angle)
                                .animation(.default, value: angle)
                        }
                        
                    }.frame(width: 30, height: 30)
                    switch state {
                    case .endRefresh: Text("已经完成数据加载")
                    case .refreshing: Text("正在加载更多的数据...")
                    case .pulling: Text("松开立即加载更多")
                    default: Text("上拉可以加载更多")
                    }
                }
            } else {
                switch state {
                case .noMoreData: Text("已经全部加载完毕")
                case .refreshing: Text("正在加载更多的数据...")
                default: Text("点击或上拉加载更多")
                }
            }
        }
        .padding()
        .lineLimit(1)
    }
}

public struct XSActivityView: View {
    public var body: some View {
        if #available(iOS 14.0, *) {
            ProgressView()
        } else {
            ActivityIndicator(isAnimating: true, style: .medium)
        }
    }
    private struct ActivityIndicator: UIViewRepresentable {
        var isAnimating: Bool
        let style: UIActivityIndicatorView.Style

        func makeUIView(context: Context) -> UIActivityIndicatorView {
            UIActivityIndicatorView(style: style)
        }

        func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
            isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        }
    }
}
