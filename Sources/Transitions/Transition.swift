import UIKit

public struct Transition {
	let type: TransitionType?
	let duration: TimeInterval?
	let curve: UIView.AnimationCurve?

	public init(type: TransitionType? = nil, duration: TimeInterval? = nil, curve: UIView.AnimationCurve? = nil) {
		self.type = type
		self.duration = duration
		self.curve = curve
	}

	public static let identity = Transition(type: .identity)
	public static let modal = Transition(type: .modal)
	public static let sliderNav = Transition(type: .sliderNav)
	public static let overlay = Transition(type: .overlay)
}

public struct FinalTransition: Equatable {
	let type: TransitionType
	let duration: TimeInterval
	let curve: UIView.AnimationCurve

	public init(type: TransitionType, duration: TimeInterval, curve: UIView.AnimationCurve) {
		self.type = type
		self.duration = duration
		self.curve = curve
	}

	init(optionalableTransition: Transition, defaultTransition: FinalTransition) {
		self.type = optionalableTransition.type ?? defaultTransition.type
		self.duration = optionalableTransition.duration ?? defaultTransition.duration
		self.curve = optionalableTransition.curve ?? defaultTransition.curve
	}

	public static let identity = FinalTransition(type: .identity, duration: 0, curve: .linear)
}

public enum TransitionType: Equatable {
	public static func == (lhs: TransitionType, rhs: TransitionType) -> Bool {
		switch lhs {
		case .identity:
			guard case .identity = rhs else { return false }
		case .modal:
			guard case .modal = rhs else { return false }
		case .overlay:
			guard case .overlay = rhs else { return false }
		case .sliderNav:
			guard case .sliderNav = rhs else { return false }
		case .custom(let lhsBuilder):
			guard case .custom(let rhsBuilder) = rhs else { return false }
			return lhsBuilder == rhsBuilder
		}
		return true
	}

	case identity
	case modal
	case overlay
	case sliderNav
	case custom(TransitionBuilder.Type)

	var transitionBuilder: TransitionBuilder.Type {
		switch self {
		case .identity:
			return IdentityTransition.self
		case .modal:
			return ModalTransition.self
		case .overlay:
			return OverlayTransition.self
		case .sliderNav:
			return SlideNavTransition.self
		case .custom(let transition):
			return transition
		}
	}
}
