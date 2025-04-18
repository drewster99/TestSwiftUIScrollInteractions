//
//  MyScrollerView.swift
//  TestSwiftUIScrollInteractions
//
//  Created by Andrew Benson on 4/17/25.
//

import Foundation
import SwiftUI
import Combine

/// Example of how to make a scrollview automaticallly scroll to the bottom
/// when content is updated -- AND -- also not fight the user when they scroll
struct MyScrollerView: View {

    // MARK: - Stuff for the example (unrelated to scrolling)

    /// A bunch of fixed data - prior "messages"
    ///
    /// This is only part of the example, not part of the scrolling solution
    let oldMessages: [String]

    /// Frequently updated message, which is the last (current) one in the list
    ///
    /// This is only part of the example, not part of the scrolling solution
    @Binding public var currentMessage: String

    /// An identifier for the current message.  This is so
    /// we can pull it out of the `ForEach` and (hopefully) not re-render ALL
    /// of the content when the current message changes.
    ///
    /// This is only part of the example, not part of the scrolling solution
    @Namespace private var currentMessageNamespace

    // MARK: - State used as part of the scrolling solution

    /// `true` if the bottom of the scroll view is visible
    @State private var isBottomOfScrollViewContentVisible = false

    @Namespace private var bottomOfScrollView

    var body: some View {
        Self._printChanges(); return
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading) {
                    // All of the "old" messages - this content won't change often
                    ForEach(oldMessages, id: \.self) { message in
                        MessageView(message: message, isActive: false)
                            .id(message)
                    }

                    // The currently-stremaing message.  This one will change VERY often
                    MessageView(message: currentMessage, isActive: true)
                        .id(currentMessageNamespace)


                    Text("")
                        .onScrollVisibilityChange { visible in
                            isBottomOfScrollViewContentVisible = visible
                        }
                        .id(bottomOfScrollView)
                }
                .scrollTargetLayout()
            }
            .onChange(of: oldMessages + [currentMessage]) {
                // We got new content - if we can see the bottom of the
                // ScrollView, then we should scroll to the bottom (of the
                // new content)
                if isBottomOfScrollViewContentVisible {
                    scrollProxy.scrollTo(bottomOfScrollView, anchor: .bottom)

                }
            }
        }
    }
}

