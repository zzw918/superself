import SwiftUI
import UserNotifications

extension ContentView {
    enum FastingNotification: String, CaseIterable {
        case eatingSoon
        case eatingStart
        case fastingSoon
        case fastingStart

        var identifier: String { "fasting.\(rawValue)" }

        var title: String {
            switch self {
            case .eatingSoon: return "还有 1 小时进食"
            case .eatingStart: return "进食时间到啦"
            case .fastingSoon: return "还有 1 小时开始断食"
            case .fastingStart: return "断食时间到啦"
            }
        }

        var body: String {
            switch self {
            case .eatingSoon: return "再坚持一下，1 小时后就能吃东西了。"
            case .eatingStart: return "断食目标已完成，可以好好吃一顿了。"
            case .fastingSoon: return "进食时间快结束了，准备开始断食吧。"
            case .fastingStart: return "进食窗口结束，开始新一轮断食。"
            }
        }
    }

    var anyFastingNotificationEnabled: Bool {
        notifyEatingSoon || notifyEatingStart || notifyFastingSoon || notifyFastingStart
    }

    /// 请求一次通知授权，回调在主线程返回是否已授权。
    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// 根据当前阶段和开关，重新安排所有断食相关的本地通知。
    func rescheduleFastingNotifications() {
        let center = UNUserNotificationCenter.current()
        let allIdentifiers = FastingNotification.allCases.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

        guard anyFastingNotificationEnabled else { return }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

            let endDate = self.phaseEndDate
            let oneHourBefore = endDate.addingTimeInterval(-3600)

            var requests: [(FastingNotification, Date)] = []
            if self.isFasting {
                if self.notifyEatingSoon { requests.append((.eatingSoon, oneHourBefore)) }
                if self.notifyEatingStart { requests.append((.eatingStart, endDate)) }
            } else {
                if self.notifyFastingSoon { requests.append((.fastingSoon, oneHourBefore)) }
                if self.notifyFastingStart { requests.append((.fastingStart, endDate)) }
            }

            let now = Date()
            for (notification, fireDate) in requests where fireDate > now {
                let content = UNMutableNotificationContent()
                content.title = notification.title
                content.body = notification.body
                content.sound = .default

                let interval = fireDate.timeIntervalSince(now)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    /// 用户切换某个通知开关：首次开启时申请授权，随后重排。
    func handleNotificationToggleChange() {
        guard anyFastingNotificationEnabled else {
            rescheduleFastingNotifications()
            return
        }

        requestNotificationAuthorization { granted in
            if granted {
                self.rescheduleFastingNotifications()
            } else {
                self.notifyEatingSoon = false
                self.notifyEatingStart = false
                self.notifyFastingSoon = false
                self.notifyFastingStart = false
            }
        }
    }
}
