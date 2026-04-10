# YALArchitectureGuide

## MVC 分层

- `App/Delegate`
  负责应用入口和场景生命周期。
- `Common/Base/Controller`
  放基础控制器，做全局通用行为承接。
- `Home` `Login` `Map` `Memory` `Message` `Mine` `PostDetail` `Register` `Release` `TimeLine`
  每个业务模块内部按 `Controller / View / Model / Manager` 拆分。
- `Network/Manager`
  放全局网络与鉴权管理，作为跨模块基础设施层。

## 搜索页讲法

- 搜索页采用 `UISegmentedControl + 单 UITableView`。
- `segment` 只负责切换当前数据域，不承担具体渲染逻辑。
- `tableView` 作为统一结果容器，内容页显示 `AI + 内容列表`，用户页显示 `用户列表`。
- 这样做的好处是状态收敛、复用率高、面试时更容易解释“一个页面一个主列表，切换的是数据源而不是页面容器”。

## 命名规范

- 业务源码统一使用 `YAL` 前缀。
- 目录统一使用 `Controller / View / Model / Manager`。
- 控制器尽量只做状态协调和页面编排，网络与数据解析下沉到 `Manager` 和 `Model`。
