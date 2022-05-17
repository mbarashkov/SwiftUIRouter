import CoreGraphics

public enum ModalTransition: ReversibleTransition {
	public static func appearingParameters(size: CGSize, action: NavigationAction.Action) -> TransitionParameters {
		var initial = TransitionParameters.State(frame: CGRect(origin: .zero, size: size), alpha: 1)
		let final = initial

		switch action {
		case .push:
			initial.frame.origin.y = initial.frame.height

		case .back: break
		}

		return TransitionParameters(initial: initial, final: final)
	}
}
