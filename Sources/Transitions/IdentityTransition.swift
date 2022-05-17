import CoreGraphics

public enum IdentityTransition: ReversibleTransition {
	public static func appearingParameters(size: CGSize, action: NavigationAction.Action) -> TransitionParameters {
		let state =	TransitionParameters.State(frame: .init(origin: .zero, size: size), alpha: 1)
		return TransitionParameters(initial: state, final: state)
	}
}
