# XSRefreshSwiftUI

XSRefreshSwiftUI 是一个专为 SwiftUI 设计的下拉刷新和上拉加载组件库，提供流畅的用户体验和灵活的定制选项。

由于SwiftUI不能没有MJRefresh, 所以抽空写了这个项目。目前只是做了初步的功能样式实现，并未做充分测试以及性能方面的考虑。如遇问题或有优化想法欢迎提交。

- 0.0.6 - 支持搭配 SwiftUIIntrospect 使用
- 0.0.5 - 优化了 endRefresh 方式
- 0.0.3 - 支持了横向拖拽的刷新和加载(特别注意: 横向自定义 Header 必须设定宽度)

## ✨ 特性

- 🚀 **简单易用** - 通过简单的修饰符即可实现下拉刷新和上拉加载功能
- 📱 **兼容性强** - 支持 iOS 13+ 和 macOS 11+
- 🎨 **高度可定制** - 支持自定义刷新组件的外观和行为
- 🔄 **多种状态** - 支持空闲、拉动、刷新中、完成等各种状态
- ⚡ **性能优化** - 采用 SwiftUI 原生实现，性能优异

## 🛠 使用方法

### 基本用法

```swift
import SwiftUI
import XSRefreshSwiftUI

struct ContentView: View {
    @State private var items = [String]()
    @State private var header = XSRefreshState.idle
    @State private var footer = XSRefreshState.none // 默认none 方便开始没请求数据时不显示footer
    
    var body: some View {
        XSRefreshScrollView {
            VStack {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .frame(height: 50)
                }
            }
        }
        .normalHeader($header) {
            loadData()
        }
        .normalAutoFooter($footer) { // 可替换 normalBackFooter
            loadMore()
        }
    }
    private func loadData() async {
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            items = ["Item 1", "Item 2", "Item 3"]
            $header.endRefresh()
            footer = .idle
        }
    }
    private func loadMore() async {
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            items += ["Item 1", "Item 2", "Item 3"]
            $footer.endRefresh(noMore: false) // 没用更多时使用  .noMoreData
        }
    }
}
```

### 进阶用法

```swift
    /// 监听 header footer 拖拽进度
    .headerProgress(_ progress: Binding<Double>)
    .footerProgress(_ progress: Binding<Double>)
    
    /// 自定义样式
    .customHeader(...)
    .customAutoFooter(...)
    .customBackFooter(...)
    
    /// 自定义获取 UIScrollView 的方法
    XSRefresh.getScrollAction = { content, getScroll in
        AnyView(
            content.introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18, .v26)) { scrollView in
                getScroll(scrollView)
            }
        )
    }
```

## 🎯 刷新状态

XSRefreshSwiftUI 提供以下刷新状态：

- `none` - 不显示
- `idle` - 普通闲置状态
- `pulling` - 松开就可以进行刷新的状态  
- `refreshing` - 正在刷新中的状态
- `endRefresh` - 完成刷新的状态
- `noMoreData` - 所有数据加载完毕，没有更多的数据了

## 📦 安装

### Swift Package Manager

在 Xcode 中添加包依赖：

1. 打开 Xcode 项目
2. 选择 `File` → `Add Package Dependency`
3. 输入仓库 URL：`https://github.com/VirtualLion/XSRefreshSwiftUI.git`
4. 选择版本规则并添加

## 🎨 环境要求

- iOS 13+ macOS 11+
- Xcode 11+
- Swift 5+


## 🙏 致谢

感谢以下优秀的开源项目，为本项目的开发提供了宝贵的参考和灵感：

- [MJRefresh](https://github.com/CoderMJLee/MJRefresh) - iOS 下拉刷新、上拉加载更多第三方组件
- [Refresh](https://github.com/wxxsw/Refresh) - 为 SwiftUI 设计的下拉刷新组件

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。
