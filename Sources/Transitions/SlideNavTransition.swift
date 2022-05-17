import CoreGraphics

public enum SlideNavTransition: ReversibleTransition {
	public static func appearingParameters(size: CGSize, action: NavigationAction.Action) -> TransitionParameters {
		var initial = TransitionParameters.State(frame: CGRect(origin: .zero, size: size), alpha: 1)
		let final = initial

		switch action {
		case .push:
			initial.frame.origin.x = initial.frame.width

		case .back:
			initial.frame.origin.x = -initial.frame.width / 3
		}

		return TransitionParameters(initial: initial, final: final)
	}
}
