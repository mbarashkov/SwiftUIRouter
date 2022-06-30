//
//  SwiftUI Router
//  Created by Freek (github.com/frzi) 2021
//

import SwiftUI

/// EnvironmentObject storing the state of a Router.
///
/// Use this object to programmatically navigate to a new path, to jump forward or back in the history, to clear the
/// history, or to find out whether the user can go back or forward.
///
/// - Note: This EnvironmentObject is available inside the hierarchy of a `Router`.
///
/// ```swift
/// @EnvironmentObject var navigator: Navigator
/// ```
public final class Navigator: ObservableObject {
	struct HistoryStackItem {
		let path: String
		let transition: FinalTransition
	}

	var historyStack: [HistoryStackItem]

	/// Last navigation that occurred.
	public private(set) var lastAction: NavigationAction? {
		didSet {
			// hack around the bug, which causes @Publised to be called before value is updated
			objectWillChange.send()
		}
	}
	
	private let initialPath: String

	let defaultTransition: FinalTransition
	let minGoBackPanGestureDistance: CGFloat
	
	/// Initialize a `Navigator` to be fed to `Router` manually.
	///
	/// Initialize an instance of `Navigator` to keep a reference to outside of the SwiftUI lifecycle.
	///
	/// - Important: This is considered an advanced usecase for *SwiftUI Router* used for specific design patterns.
	/// It is strongly advised to reference the `Navigator` via the provided Environment Object instead.
	///
	/// - Parameter initialPath: The initial path the `Navigator` should start at once initialized.
	public init(
		initialPath: String = "/",
		defaultTransition: FinalTransition,
		minGoBackPanGestureDistance: CGFloat
	) {
		self.initialPath = initialPath
		self.defaultTransition = defaultTransition
		self.minGoBackPanGestureDistance = minGoBackPanGestureDistance
		self.historyStack = [HistoryStackItem(path: initialPath, transition: FinalTransition(type: .identity, duration: 0, curve: .linear))]
	}

	// MARK: Getters.
	/// Current navigation path of the Router environment.
	public var path: String {
		historyStack.last?.path ?? initialPath
	}

	public var canGoBack: Bool {
		historyStack.filter { $0.path != initialPath }.count > 1
	}

	public var currentStackIndex: Int {
		historyStack.count - 1
	}
	
	// MARK: Methods.
	/// Navigate to a new location.
	///
	/// The given path is always relative to the current environment path.
	/// This means you can use `/` to navigate using an absolute path and `..` to go up a directory.
	///
	/// ```swift
	/// navigator.navigate("news") // Relative.
	/// navigator.navigate("/settings/user") // Absolute.
	/// navigator.navigate("..") // Up one, relatively.
	/// ```
	///
	/// Navigating to the same path as the current path is a noop. If the `DEBUG` flag is enabled, a warning
	/// will be printed to the console.
	///
	/// - Parameter path: Path of the new location to navigate to.
	/// - Parameter replace: if `true` will replace the last path in the history stack with the new path.
	public func navigate(
		_ path: String,
		transition: Transition = Transition(),
		replace: Bool = false
	) {
		let path = resolvePaths(self.path, path)
		let previousPath = self.path
		let previousStackIndex = historyStack.count - 1
		
		guard path != previousPath else {
			#if DEBUG
			print("SwiftUIRouter: Navigating to the same path ignored.")
			#endif
			return
		}
		if let index = historyStack.firstIndex(where: { $0.path == path }) {
			goBack(total: historyStack.count - index - 1, transition: transition)
		} else {
			let finalTransition = FinalTransition(
				optionalableTransition: transition,
				defaultTransition: defaultTransition
			)
		
			let stackItem = HistoryStackItem(
				path: path,
				transition: finalTransition
			)

			if replace && !historyStack.isEmpty {
				historyStack[historyStack.endIndex - 1] = stackItem
			}
			else {
				historyStack.append(stackItem)
			}
			lastAction = NavigationAction(
				currentPath: path,
				previousPath: previousPath,
				previousStackIndex: previousStackIndex,
				action: .push,
				transition: finalTransition
			)
		}
		
	}

	/// Go back *n* steps in the navigation history.
	///
	/// `total` will always be clamped and thus prevent from going out of bounds.
	///
	/// - Parameter total: Total steps to go back.
	public func goBack(total: Int = 1, transition: Transition = Transition()) {
		guard canGoBack else {
			return
		}
		let previousPath = path
		let previousStackIndex = historyStack.count - 1
		let transition = FinalTransition(
			optionalableTransition: transition,
			defaultTransition: historyStack.last?.transition ?? defaultTransition
		)

		let total = min(total, historyStack.count)
		historyStack.removeLast(total)
		
		lastAction = NavigationAction(
			currentPath: path,
			previousPath: previousPath,
			previousStackIndex: previousStackIndex,
			action: .back,
			transition: transition
		)
	}
	
	/// Clear the entire navigation history.
	public func clear() {
		historyStack = [HistoryStackItem(path: initialPath, transition: .identity)]
		lastAction = nil
	}
}

extension Navigator: Equatable {
	public static func == (lhs: Navigator, rhs: Navigator) -> Bool {
		lhs === rhs
	}
}


// MARK: -
/// Information about a navigation that occurred.
public struct NavigationAction: Equatable {
	/// The kind of navigation that occurred.
	public enum Action {
		/// Navigated to a new path.
		case push
		/// Navigated back in the stack.
		case back
	}
	
	public let currentPath: String
	public let previousPath: String
	public let previousStackIndex: Int
	public let action: Action
	public let transition: FinalTransition

	public static func == (lhs: NavigationAction, rhs: NavigationAction) -> Bool {
		lhs.currentPath == rhs.currentPath &&
		lhs.previousPath == rhs.previousPath &&
		lhs.action == rhs.action &&
		lhs.transition == rhs.transition
	}
}
