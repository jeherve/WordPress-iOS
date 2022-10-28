import WidgetKit

enum StatsWidgetEntry: TimelineEntry {
    case siteSelected(HomeWidgetData, TimelineProviderContext)
    case loggedOut(StatsWidgetKind)
    case noStats(StatsWidgetKind)

    var date: Date {
        switch self {
        case .siteSelected(let widgetData, _):
            return widgetData.date
        case .loggedOut, .noStats:
            return Date()
        }
    }
}
