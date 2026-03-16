//
//  StrategyConfigView.swift
//  StockWatch
//

import SwiftUI

/// 전략 파라미터 설정 + 즉시 확인 + 알림 등록 화면
struct StrategyConfigView: View {

    @ObservedObject var store: ApplyStrategyStore
    let strategy: Strategy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 전략 헤더
                strategyHeader

                Divider()

                // 파라미터 설정
                parameterSection

                Divider()

                // 즉시 확인
                evaluationSection

                Divider()

                // 알림 등록
                notificationSection

                // 적용하기 버튼
                applyButton
            }
            .padding()
        }
        .navigationTitle("\(strategy.shortName) 설정")
        .navigationBarTitleDisplayMode(.inline)
        .alert("저장 완료", isPresented: Binding(
            get: { store.state.isSaved },
            set: { _ in store.action(.deselectStrategy) }
        )) {
            Button("확인") { dismiss() }
        } message: {
            Text("조건이 저장되었습니다.")
        }
    }

    // MARK: - Strategy Header

    private var strategyHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(strategy.shortName)
                    .font(.title2.bold())
                    .foregroundStyle(.blue)

                Text(strategy.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            Text(strategy.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Parameter Section

    @ViewBuilder
    private var parameterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("파라미터 설정")
                .font(.headline)

            switch strategy.id {
            case "sma_cross", "ema_cross":
                crossParameterControls
            case "rsi":
                rsiParameterControls
            default:
                EmptyView()
            }
        }
    }

    @State private var shortPeriodText: String = ""
    @State private var longPeriodText: String = ""
    @State private var shortPeriodError: Bool = false
    @State private var longPeriodError: Bool = false

    @State private var rsiPeriodText: String = ""
    @State private var rsiPeriodError: Bool = false
    @State private var oversoldText: String = ""
    @State private var oversoldError: Bool = false
    @State private var overboughtText: String = ""
    @State private var overboughtError: Bool = false

    private var crossOrderError: Bool {
        let short = Int(shortPeriodText) ?? 0
        let long = Int(longPeriodText) ?? 0
        return !shortPeriodError && !longPeriodError
            && short >= 1 && short <= 1000
            && long >= 1 && long <= 1000
            && short >= long
    }

    private var isCrossInputValid: Bool {
        guard strategy.id == "sma_cross" || strategy.id == "ema_cross" else { return true }
        let short = Int(shortPeriodText) ?? 0
        let long = Int(longPeriodText) ?? 0
        return !shortPeriodText.isEmpty && !longPeriodText.isEmpty
            && short >= 1 && short <= 1000
            && long >= 1 && long <= 1000
    }

    private var isRSIInputValid: Bool {
        guard strategy.id == "rsi" else { return true }
        return !rsiPeriodText.isEmpty && !oversoldText.isEmpty && !overboughtText.isEmpty
    }

    private var crossParameterControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("단기 기간")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("", text: $shortPeriodText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(shortPeriodError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: shortPeriodText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { shortPeriodText = filtered }
                            if let value = Int(filtered), value >= 1, value <= 1000 {
                                shortPeriodError = false
                                store.action(.updateShortPeriod(value))
                            } else {
                                shortPeriodError = true
                            }
                        }
                    Text("일")
                        .foregroundStyle(.secondary)
                }
                if shortPeriodError {
                    Text("1~1,000까지 입력해주세요.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("장기 기간")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("", text: $longPeriodText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(longPeriodError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: longPeriodText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { longPeriodText = filtered }
                            if let value = Int(filtered), value >= 1, value <= 1000 {
                                longPeriodError = false
                                store.action(.updateLongPeriod(value))
                            } else {
                                longPeriodError = true
                            }
                        }
                    Text("일")
                        .foregroundStyle(.secondary)
                }
                if longPeriodError {
                    Text("1~1,000까지 입력해주세요.")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            if crossOrderError {
                Text("단기 기간은 장기 기간보다 작아야 합니다")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            shortPeriodText = "\(store.state.shortPeriod)"
            longPeriodText = "\(store.state.longPeriod)"
        }
    }

    private var rsiParameterControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("기간")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("", text: $rsiPeriodText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(rsiPeriodError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: rsiPeriodText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { rsiPeriodText = filtered }
                            if let value = Int(filtered), value >= 1, value <= 250 {
                                rsiPeriodError = false
                                store.action(.updateRSIPeriod(value))
                            } else {
                                rsiPeriodError = !filtered.isEmpty
                            }
                        }
                    Text("일")
                        .foregroundStyle(.secondary)
                }
                if rsiPeriodError {
                    Text("1~250 사이의 정수를 입력해주세요")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("과매도 임계값")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("", text: $oversoldText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(oversoldError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: oversoldText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { oversoldText = filtered }
                            if let value = Int(filtered), value >= 1, value <= 99 {
                                oversoldError = false
                                store.action(.updateOversoldThreshold(Double(value)))
                            } else {
                                oversoldError = !filtered.isEmpty
                            }
                        }
                }
                if oversoldError {
                    Text("1~99 사이의 정수를 입력해주세요")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("과매수 임계값")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("", text: $overboughtText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(overboughtError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: overboughtText) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { overboughtText = filtered }
                            if let value = Int(filtered), value >= 1, value <= 99 {
                                overboughtError = false
                                store.action(.updateOverboughtThreshold(Double(value)))
                            } else {
                                overboughtError = !filtered.isEmpty
                            }
                        }
                }
                if overboughtError {
                    Text("1~99 사이의 정수를 입력해주세요")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .onAppear {
            rsiPeriodText = "\(store.state.rsiPeriod)"
            oversoldText = "\(Int(store.state.oversoldThreshold))"
            overboughtText = "\(Int(store.state.overboughtThreshold))"
        }
    }

    // MARK: - Evaluation Section

    private var evaluationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("현재 상태 확인")
                .font(.headline)

            if store.state.isEvaluating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("평가 중...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } else if let signal = store.state.signal {
                signalCard(signal: signal)
            } else {
                Button {
                    store.action(.evaluate)
                } label: {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("즉시 확인")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if let errorMessage = store.state.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func signalCard(signal: StrategySignal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                signalBadge(signal.signalType)
                Spacer()
                Button {
                    store.action(.evaluate)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Text(signal.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(signalBackgroundColor(signal.signalType).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func signalBadge(_ type: SignalType) -> some View {
        Text(type.rawValue)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(signalBackgroundColor(type))
            .clipShape(Capsule())
    }

    private func signalBackgroundColor(_ type: SignalType) -> Color {
        switch type {
        case .buy: return .green
        case .sell: return .red
        case .neutral: return .gray
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("알림 설정")
                .font(.headline)

            Toggle(isOn: Binding(
                get: { store.state.isNotificationEnabled },
                set: { _ in store.action(.toggleNotification) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("조건 충족 시 알림")
                    Text("조건이 충족되면 푸시 알림을 받습니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if store.state.isNotificationEnabled {
                HStack {
                    Text("알림 시간")
                    Spacer()
                    Picker("알림 시간", selection: Binding(
                        get: {
                            let kst = TimeZone(identifier: "Asia/Seoul")!
                            return Calendar.current.dateComponents(in: kst, from: store.state.notificationTime).hour ?? 9
                        },
                        set: { hour in
                            var components = DateComponents()
                            components.hour = hour
                            components.minute = 0
                            components.timeZone = TimeZone(identifier: "Asia/Seoul")!
                            if let date = Calendar.current.date(from: components) {
                                store.action(.updateNotificationTime(date))
                            }
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Text("매일 설정한 시간에 전략 조건을 확인합니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Apply Button

    private var applyButton: some View {
        Button {
            store.action(.saveCondition)
        } label: {
            if store.state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("적용하기")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.state.isLoading || !store.state.canApply || !isRSIInputValid || !isCrossInputValid)
    }
}
