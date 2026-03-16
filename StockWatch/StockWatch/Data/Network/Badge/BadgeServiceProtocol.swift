//
//  BadgeServiceProtocol.swift
//  StockWatch
//

protocol BadgeServiceProtocol {
    func decrement() async
}

struct LiveBadgeService: BadgeServiceProtocol {
    func decrement() async {
        await BadgeResetService.decrement()
    }
}
