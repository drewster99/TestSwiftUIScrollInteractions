//
//  ContentView.swift
//  TestSwiftUIScrollInteractions
//
//  Created by Andrew Benson on 4/16/25.
//

import Foundation
import SwiftUI
import Combine

struct ContentView: View {
    struct AutoScrollState: Equatable, Hashable {
        var scrollIdleStartTime: Date = .distantPast {
            didSet {
                print(">>> scrollIdleStartTime: \(scrollIdleStartTime)")
            }
        }

        enum AutoScrollPhase: Equatable, Hashable {
            case userScrollInProgress
            case autoScrollInProgress
            case idle
            case timerExpiredIdle

            var text: String {
                switch self {
                case .autoScrollInProgress: "AUTO SCROLLING"
                case .userScrollInProgress: "USER SCROLLING"
                case .idle: "idle"
                case .timerExpiredIdle: "idle [timer expired]"
                }
            }
        }
        var autoscrollPhase: AutoScrollPhase = .idle {
            didSet {
                print(">>> autoscrollPhase: \(autoscrollPhase.text)")
            }
        }

    }
    @State private var oldMessages: [String] = []
    @State private var currentMessage: String = ""
    @State private var junkGenerator = JunkGenerator()
    @State private var bottomMessageScrollVisible = true
    @State private var bottomMessageIsHalfVisible = true

    @State private var autoScrollState = AutoScrollState()


    @State private var scrollPhaseText = ""

    @State private var newContent = false
    @State private var timerTick: Date = .distantPast

    @State private var updateTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    @State private var isAutoScrollingEnabled = true

    private func start() {
        junkGenerator.startGenerating()
    }

    private func stop() {
        junkGenerator.stopGenerating()
        oldMessages.append(junkGenerator.text)
        currentMessage = ""
    }

    private func next() {
        if junkGenerator.isGenerating {
            stop()
        }
        start()
    }

    private func autoNext() {
        next()
        Task.detached {
            let delaySeconds = Double.random(in: 1.50 ... 10.00)
            let delayMilliseconds = Int(delaySeconds * 1000)
            try? await Task.sleep(for: .milliseconds(delayMilliseconds))

            Task { @MainActor in
                next()
            }
        }
    }

    private func scrollToBottomIfAllowed(_ scrollProxy: ScrollViewProxy) {
        guard autoScrollState.autoscrollPhase == .timerExpiredIdle else {
            print(">>> scroll to bottom -- not allowed")
            return
        }
        print(">>> scrolling to bottom")
        autoScrollState.autoscrollPhase = .autoScrollInProgress
        scrollProxy.scrollTo("vstack")
    }

    private func handlePeriodicTimer(_ scrollProxy: ScrollViewProxy) {
        print(">>> timer")
        if Date().timeIntervalSince(autoScrollState.scrollIdleStartTime) > 10.0, autoScrollState.autoscrollPhase == .idle {
            print(">>> timer EXPIRED idle")
            autoScrollState.autoscrollPhase = .timerExpiredIdle
        }

        let currentMessageText = junkGenerator.text
        if currentMessageText != currentMessage {
            withAnimation(.none) {
                currentMessage = currentMessageText
            }
            newContent = true
            print(">>> new content")
        } else {
            newContent = false
        }
        scrollToBottomIfAllowed(scrollProxy)
    }

    private func handleScrollPhaseChange(_ oldPhase: ScrollPhase, newPhase: ScrollPhase) {
        let newPhaseText = switch newPhase {
        case .animating: "animating"
        case .tracking: "tracking"
        case .idle: "IDLE"
        case .decelerating: "decelerating"
        case .interacting: "interacting"
        }

        scrollPhaseText = newPhaseText
        print(">>> \(newPhaseText)")

        var newState = autoScrollState
        switch newPhase {
        case .idle:
            newState.autoscrollPhase = .idle
            if oldPhase != .idle {
                // we just started idling
                newState.scrollIdleStartTime = Date()
            }

        default:
            if oldPhase == .idle {
                switch autoScrollState.autoscrollPhase {
                case .autoScrollInProgress, .userScrollInProgress:
                    break
                case .idle:
                    // user is doing something
                    newState.scrollIdleStartTime = .distantFuture
                    newState.autoscrollPhase = .userScrollInProgress
                case .timerExpiredIdle:
                    newState.autoscrollPhase = .autoScrollInProgress
                }
            }
        }
        if newState != autoScrollState {
            autoScrollState = newState
        }
    }
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Button {
                        start()
                    } label: {
                        Text("Start")
                    }

                    Button {
                        stop()
                    } label: {
                        Text("Stop")
                    }

                    Button {
                        next()
                    } label: {
                        Text("Next")
                    }

                    Button {
                        autoNext()
                    } label: {
                        Text("Auto")
                    }
                }
                .buttonStyle(.bordered)
                .padding()

                MyScrollerView(oldMessages: oldMessages, currentMessage: $currentMessage)
                    .onChange(of: junkGenerator.text) {
                        currentMessage = junkGenerator.text
                    }
                    .onAppear {
                        currentMessage = junkGenerator.text
                        start()
                    }
                    .disabled(false)
            }
        }
    }
}

struct MessageView: View {
    let message: String
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(message)
                .multilineTextAlignment(.leading)
            
            Button(role: .none) {
                //
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.footnote)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 13.0, style: .continuous)
                .fill(
                    isActive ? Color.blue.opacity(0.1) : Color.green.opacity(0.1)
                )
        )
        .padding(4)
    }
}
