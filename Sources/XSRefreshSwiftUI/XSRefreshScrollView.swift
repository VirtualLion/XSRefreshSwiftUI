//
//  XSRefreshScrollView.swift
//  XSRefreshSwiftUI
//
//  Created by 韩云智 on 2026/1/13.
//

import SwiftUI
import Combine

extension XSRefreshScrollView {
    public typealias HeaderScroll<T: View> = XSRefreshScrollView<Content, T, Footer>
    public func customHeader<T: View>(_ state: Binding<XSRefreshState>, timeKey: String? = nil, action: @escaping () -> Void, label: @escaping (XSRefreshState, Date?) -> T) -> HeaderScroll<T> { // 特别注意横向自定义 必须设定宽度
        HeaderScroll<T>(
            header: { state, date in XSRefreshComponent(type: .header) { label(state, date) } },
            headerAction: action,
            headerState: state,
            headerProgress: $headerProgress,
            headerLastUpdatedTimeKey: timeKey ?? headerLastUpdatedTimeKey,
            
            footer: footer,
            footerAction: footerAction,
            footerState: $footerState,
            footerProgress: $footerProgress,
            footerType: footerType,
            
            axes: axes,
            content: content
        )
    }
    public func normalHeader(_ state: Binding<XSRefreshState>, timeKey: String? = nil, action: @escaping () -> Void) -> HeaderScroll<XSRefreshTrailer> {
        customHeader(state, timeKey: timeKey, action: action) { state, date in
//            XSRefreshHeader(state: state, date: date)
            XSRefreshTrailer(axes, state: state, date: date)
        }
    }
    public func headerProgress(_ progress: Binding<Double>) -> Self {
        var view = self
        view._headerProgress = progress
        return view
    }
    
    public typealias FooterScroll<T: View> = XSRefreshScrollView<Content, Header, T>
    private func customFooter<T: View>(_ state: Binding<XSRefreshState>, type: XSRefreshComponentType, action: @escaping () -> Void, label: @escaping (XSRefreshState) -> T) -> FooterScroll<T> {
        FooterScroll<T>(
            header: header,
            headerAction: headerAction,
            headerState: $headerState,
            headerProgress: $headerProgress,
            headerLastUpdatedTimeKey: headerLastUpdatedTimeKey,
            
            footer: { state in XSRefreshComponent(type: type) { label(state) } },
            footerAction: action,
            footerState: state,
            footerProgress: $footerProgress,
            footerType: type,
            
            axes: axes,
            content: content
        )
    }
    public func customAutoFooter<T: View>(_ state: Binding<XSRefreshState>, action: @escaping () -> Void, label: @escaping (XSRefreshState) -> T) -> FooterScroll<T> {
        customFooter(state, type: .footer_auto, action: action, label: label)
    }
    public func normalAutoFooter(_ state: Binding<XSRefreshState>, action: @escaping () -> Void) -> FooterScroll<XSRefreshTrailer> {
        customFooter(state, type: .footer_auto, action: action) { state in
//            XSRefreshFooter(state: state, type: .footer_auto)
            XSRefreshTrailer(axes, state: state, type: .footer_auto)
        }
    }
    public func customBackFooter<T: View>(_ state: Binding<XSRefreshState>, action: @escaping () -> Void, label: @escaping (XSRefreshState) -> T) -> FooterScroll<T> {
        customFooter(state, type: .footer_back, action: action, label: label)
    }
    public func normalBackFooter(_ state: Binding<XSRefreshState>, action: @escaping () -> Void) -> FooterScroll<XSRefreshTrailer> {
        customFooter(state, type: .footer_back, action: action) { state in
//            XSRefreshFooter(state: state, type: .footer_back)
            XSRefreshTrailer(axes, state: state, type: .footer_back)
        }
    }
    public func footerProgress(_ progress: Binding<Double>) -> Self {
        var view = self
        view._footerProgress = progress
        return view
    }
}

public struct XSRefreshScrollView<Content: View, Header: View, Footer: View> {
    @State private var headerPadding = EdgeInsets()
    private var header: ((XSRefreshState, Date?)->XSRefreshComponent<Header>)?
    private var headerAction: (()->Void)?
    @Binding private var headerState: XSRefreshState
    @Binding private var headerProgress: Double
    private var headerLastUpdatedTimeKey = XSRefresh.headerLastUpdatedTimeKey
    
    @State private var footerPadding = EdgeInsets()
    private var footer: ((XSRefreshState)->XSRefreshComponent<Footer>)?
    private var footerAction: (()->Void)?
    @Binding private var footerState: XSRefreshState
    @Binding private var footerProgress: Double
    private var footerType = XSRefreshComponentType.footer_auto
    
    @State private var id = UUID()
    private var axes: Axis.Set = .vertical
    @ViewBuilder var content: () -> Content
}

extension XSRefreshScrollView where Header == EmptyView, Footer == EmptyView {
    public init(_ axes: Axis.Set = .vertical, @ViewBuilder content: @escaping () -> Content)  {
        self.content = content
        self.axes = axes
        self._headerState = .constant(.none)
        self._headerProgress = .constant(0)
        self._footerState = .constant(.none)
        self._footerProgress = .constant(0)
    }
}

extension XSRefreshScrollView: View {
    private var headerLastUpdatedTime: Date? { UserDefaults.standard.value(forKey: headerLastUpdatedTimeKey) as? Date }
    public var body: some View {
        ScrollView(axes) {
            XSRefreshContentView(axes: axes) {
                if let header = header, headerState != .none, footerState != .refreshing {
                    header(headerState, headerState == .endRefresh ? Date() : headerLastUpdatedTime)
                        .padding(headerPadding)
                        .onReceive(Just(headerState)) { value in
                            if value == .endRefresh {
                                UserDefaults.standard.set(Date(), forKey: headerLastUpdatedTimeKey)
                                UserDefaults.standard.synchronize()
                            }
                        }
                }
                content().xsRefreshAnchor()
                if let footer = footer, footerState != .none, headerState != .refreshing {
                    if footerType == .footer_back {
                        footer(footerState)
                            .padding(footerPadding)
                    } else {
                        footer(footerState)
                            .onTapGesture {
                                switch footerState {
                                case .idle, .endRefresh:
                                    footerState = .refreshing
                                    footerAction?()
                                default: break
                                }
                            }
                    }
                }
            }
        }
        .animation(headerState == .endRefresh ? .default : nil, value: headerPadding)
        .modifier(XSRefreshModifier(axes: axes, update: update))
        .id(id)
    }
    
    private func update(proxy: GeometryProxy, value: XSRefreshKey.Value, isDragging: Bool) {
        guard value.count > 1 else { return }
        updateAutoFooter(proxy: proxy, value: value, isDragging: isDragging)
        updateBackFooter(proxy: proxy, value: value, isDragging: isDragging)
        updateHeader(proxy: proxy, value: value, isDragging: isDragging)
    }
    private func updateHeader(proxy: GeometryProxy, value: XSRefreshKey.Value, isDragging: Bool) {
        guard header != nil, let item = value.first(where: { $0.type == .header }) else { return }
        let bounds = proxy[item.bounds]
        if axes == .horizontal {
            headerPadding.trailing = proxy.safeAreaInsets.leading
            guard headerState != .none, footerState != .refreshing, bounds.maxX >= -proxy.safeAreaInsets.leading else { return }
            if headerState == .refreshing {
                if headerPadding.leading < 0, bounds.minX <= 0 {
                    headerPadding.leading = 0
                    id = UUID()
                }
            } else {
                if isDragging {
                    let progress = max(0, (bounds.maxX) / bounds.width)
                    headerProgress = min(1, progress)
                    if headerState == .endRefresh {
                        headerState = .idle
                    }
                    if headerState == .idle, progress > 1 {
                        headerState = .pulling
                    } else if headerState == .pulling, progress <= 1 {
                        headerState = .idle
                    }
                } else if headerState == .pulling {
                    headerProgress = 0
                    headerState = .refreshing
                    if footerType == .footer_back {
                        footerPadding.leading = proxy.size.width + proxy.safeAreaInsets.trailing
                    }
                    headerAction?()
                }
                headerPadding.leading = -(bounds.width+proxy.safeAreaInsets.leading)
            }
        } else {
            headerPadding.bottom = proxy.safeAreaInsets.top
            guard headerState != .none, footerState != .refreshing, bounds.maxY >= -proxy.safeAreaInsets.top else { return }
            if headerState == .refreshing {
                if headerPadding.top < 0, bounds.minY <= 0 {
                    headerPadding.top = 0
                    id = UUID()
                }
            } else {
                if isDragging {
                    let progress = max(0, (bounds.maxY) / bounds.height)
                    headerProgress = min(1, progress)
                    if headerState == .endRefresh {
                        headerState = .idle
                    }
                    if headerState == .idle, progress > 1 {
                        headerState = .pulling
                    } else if headerState == .pulling, progress <= 1 {
                        headerState = .idle
                    }
                } else if headerState == .pulling {
                    headerProgress = 0
                    headerState = .refreshing
                    if footerType == .footer_back {
                        footerPadding.top = proxy.size.height + proxy.safeAreaInsets.bottom
                    }
                    headerAction?()
                }
                headerPadding.top = -(bounds.height+proxy.safeAreaInsets.top)
            }
        }
    }
    private func updateAutoFooter(proxy: GeometryProxy, value: XSRefreshKey.Value, isDragging: Bool) {
        guard footer != nil, footerType == .footer_auto, headerState != .refreshing else { return }
        switch footerState {
        case .idle, .endRefresh: break
        default: return
        }
        guard let item = value.first(where: { $0.type == .footer_auto }), let content = value.first(where: { $0.type == .content }) else { return }
        let bounds = proxy[item.bounds]
        if axes == .horizontal {
            let top = min(proxy.size.width+proxy.safeAreaInsets.trailing, proxy[content.bounds].width)
            if bounds.maxX <= top {
                footerState = .refreshing
                footerAction?()
            }
        } else {
            let top = min(proxy.size.height+proxy.safeAreaInsets.bottom, proxy[content.bounds].height)
            if bounds.maxY <= top {
                footerState = .refreshing
                footerAction?()
            }
        }
    }
    private func updateBackFooter(proxy: GeometryProxy, value: XSRefreshKey.Value, isDragging: Bool) {
        guard footer != nil, footerType == .footer_back, let item = value.first(where: { $0.type == .footer_back }), let content = value.first(where: { $0.type == .content }) else { return }
        let bounds = proxy[item.bounds]
        if axes == .horizontal {
            footerPadding.leading = max(0, proxy.size.width - proxy[content.bounds].width) + proxy.safeAreaInsets.trailing
            guard footerState != .none, headerState != .refreshing, bounds.minX <= proxy.size.width+proxy.safeAreaInsets.trailing else { return }
            if footerState == .noMoreData {
                footerPadding.trailing = -(bounds.width+proxy.safeAreaInsets.trailing)
            } else if footerState == .refreshing {
                if footerPadding.trailing < 0, bounds.maxX >= proxy.size.width {
                    footerPadding.trailing = 0
                }
            } else {
                if isDragging {
                    let progress = max(0, (proxy.size.width-bounds.minX) / bounds.width)
                    footerProgress = min(1, progress)
                    if footerState == .endRefresh {
                        footerState = .idle
                    }
                    if footerState == .idle, progress > 1 {
                        footerState = .pulling
                    } else if footerState == .pulling, progress <= 1 {
                        footerState = .idle
                    }
                } else if footerState == .pulling {
                    footerProgress = 0
                    footerState = .refreshing
                    footerAction?()
                }
                footerPadding.trailing = -(bounds.width+proxy.safeAreaInsets.trailing)
            }
        } else {
            footerPadding.top = max(0, proxy.size.height - proxy[content.bounds].height) + proxy.safeAreaInsets.bottom
            guard footerState != .none, headerState != .refreshing, bounds.minY <= proxy.size.height+proxy.safeAreaInsets.bottom else { return }
            if footerState == .noMoreData {
                footerPadding.bottom = -(bounds.height+proxy.safeAreaInsets.bottom)
            } else if footerState == .refreshing {
                if footerPadding.bottom < 0, bounds.maxY >= proxy.size.height {
                    footerPadding.bottom = 0
                }
            } else {
                if isDragging {
                    let progress = max(0, (proxy.size.height-bounds.minY) / bounds.height)
                    footerProgress = min(1, progress)
                    if footerState == .endRefresh {
                        footerState = .idle
                    }
                    if footerState == .idle, progress > 1 {
                        footerState = .pulling
                    } else if footerState == .pulling, progress <= 1 {
                        footerState = .idle
                    }
                } else if footerState == .pulling {
                    footerProgress = 0
                    footerState = .refreshing
                    footerAction?()
                }
                footerPadding.bottom = -(bounds.height+proxy.safeAreaInsets.bottom)
            }
        }
    }
}
