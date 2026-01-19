//
//  XSRefreshModifier.swift
//  XSRefreshSwiftUI
//
//  Created by 韩云智 on 2026/1/13.
//

import SwiftUI

struct XSRefreshModifier: ViewModifier {
    let axes: Axis.Set
    let update: (GeometryProxy, XSRefreshKey.Value, Bool) -> Void
    private let scrollModel = _ScrollModel()
    private class _ScrollModel {
        var scroll: UIScrollView?
        var isDragging: Bool { scroll?.isDragging ?? false }
    }
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .clipShape(XSRefreshSafeAreaShape(insets: proxy.safeAreaInsets))
                .backgroundPreferenceValue(XSRefreshKey.self) { v -> Color in
                    DispatchQueue.main.async { update(proxy, v, scrollModel.isDragging) }
                    return Color.clear
                }
                .background(XSRefreshGetScrollRepresentable(axes: axes) { scrollModel.scroll = $0 })
        }
    }
}

struct XSRefreshGetScrollRepresentable: UIViewRepresentable {
    let axes: Axis.Set
    var updateScroll: ((UIScrollView)->Void)?
    func makeUIView(context: Context) -> UIView {
        UIView()
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            guard let viewHost = uiView.superview?.superview?.superview ?? uiView.superview?.superview, let sv = self.scrollView(root: viewHost) else { return }
            updateScroll?(sv)
            if axes == .horizontal {
                sv.alwaysBounceHorizontal = true
            } else {
                sv.alwaysBounceVertical = true
            }
        }
    }
    private func scrollView(root: UIView) -> UIScrollView? {
        for subview in root.subviews {
            if subview.isKind(of: UIScrollView.self) {
                return subview as? UIScrollView
            } else if let scroll = scrollView(root: subview) {
                return scroll
            }
        }
        return nil
    }
}

struct XSRefreshSafeAreaShape: Shape {
    let insets: EdgeInsets
    func path(in rect: CGRect) -> Path {
        let rect = rect.inset(by: UIEdgeInsets(top: -insets.top, left: -insets.leading, bottom: -insets.bottom, right: -insets.trailing))
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct XSRefreshContentView<Content: View>: View {
    let axes: Axis.Set
    @ViewBuilder var content: () -> Content
    var body: some View {
        if axes == .horizontal {
            HStack(spacing: 0) {
                content()
            }.frame(maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                content()
            }.frame(maxWidth: .infinity)
        }
    }
}
