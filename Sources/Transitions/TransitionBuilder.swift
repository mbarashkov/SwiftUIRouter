import CoreGraphics

public struct TransitionParameters {
	public struct State: Equatable {
		public var frame: CGRect
		public var alpha: CGFloat

		public init(frame: CGRect, alpha: CGFloat) {
			self.frame = frame
			self.alpha = alpha
		}
	}

	public let initial: State
	public let final: State

	public init(initial: TransitionParameters.State, final: TransitionParameters.State) {
		self.initial = initial
		self.final = final
	}
}

public protocol TransitionBuilder {
	static func appearingParameters(size: CGSize, action: NavigationAction.Action) -> TransitionParameters
	static func disappearingParameters(size: CGSize, action: NavigationAction.Action) -> TransitionParameters
}

public protocol ReversibleTransition: TransitionBuilder {
}

extension ReversibleTransition {
	public static func disappearingParameters(size: CGSize, action: NavigationAction.Action) -> TransitionParameters {
		let appearing = appearingParameters(size: size, action: action == .push ? .back : .push)
		return TransitionParameters(initial: appearing.final, final: appearing.initial)
	}
}
