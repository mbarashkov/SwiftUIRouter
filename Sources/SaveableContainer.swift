import SwiftUI

struct SaveableContainer<Content: View, Data>: UIViewControllerRepresentable {
	let contentData: Data?
	
	let transition: FinalTransition
	let action: NavigationAction.Action
	@ViewBuilder
	let content: (Data) -> Content

	init(
		contentData: Data?,
		transition: FinalTransition,
		action: NavigationAction.Action,
		@ViewBuilder content: @escaping (Data) -> Content
	) {
		self.contentData = contentData
		self.transition = transition
		self.action = action
		self.content = content
	}

	func makeUIViewController(context: Context) -> HostingControllerWrapper<Content, Data> {
		HostingControllerWrapper(content: content)
	}

	func updateUIViewController(_ uiViewController: HostingControllerWrapper<Content, Data>, context: Context) {
		uiViewController.content = content
		uiViewController.contentData = contentData
		uiViewController.transition = transition
		uiViewController.action = action
		uiViewController.animateIfNeeded()
	}
}

final class HostingControllerWrapper<Content: View, Data>: UIViewController {
	private enum PresenceState {
		case hidden
		case appearing
		case visible
		case disappearing
	}

	var hostingController: UIHostingController<Content>!

	init(content: @escaping (Data) -> Content) {
		self.content = content
		super.init(nibName: nil, bundle: nil)
		view.backgroundColor = .clear
		view.clipsToBounds = true
		view.isUserInteractionEnabled = false
	}

	var content: (Data) -> Content {
		didSet {
			updateContentIfNeeded()
		}
	}
	var transition: FinalTransition = FinalTransition.identity
	var action: NavigationAction.Action = .push
	var contentData: Data?

	private func updateContentIfNeeded() {
		if let contentData = savedContentData, state != .hidden {
			hostingController.rootView = content(contentData)
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		hostingController.view.frame.size = view.bounds.size

		// prevent safe area related layout change during animation
		hostingController.additionalSafeAreaInsets = view.safeAreaInsets - hostingController.view.safeAreaInsets
	}

	private var state = PresenceState.hidden
	private var savedContentData: Data?
	private var animator: UIViewPropertyAnimator!

	func animateIfNeeded() {
		if contentData != nil {
			savedContentData = contentData
		}
		if contentData != nil && state != .hidden || contentData == nil && state == .hidden {
			return
		}
		let initialState: PresenceState
		if let contentData = contentData {
			initialState = .appearing
			if hostingController == nil {
				hostingController = UIHostingController(rootView: content(contentData))
				hostingController.view.backgroundColor = .clear
			} else {
				updateContentIfNeeded()
			}
			view.addSubview(hostingController.view)
		} else {
			initialState = .disappearing
		}
		state = initialState
		let visible = contentData != nil
		if visible {
			addChild(hostingController)
		}

		let transitionBuilder = transition.type.transitionBuilder
		let createParameters = visible ? transitionBuilder.appearingParameters : transitionBuilder.disappearingParameters

		view.layoutIfNeeded()
		view.isUserInteractionEnabled = false

		let transitionParameters = createParameters(view.bounds.size, action)

		let animations = { [self] in
			transitionParameters.final.apply(to: hostingController.view)
			view.setNeedsLayout()
			view.layoutIfNeeded()
		}
		let animationCompletion = { [self] in
			if visible {
				state = .visible
				view.isUserInteractionEnabled = true
				view.setNeedsLayout()
			} else {
				state = .hidden
				hostingController.view.removeFromSuperview()
				hostingController.removeFromParent()
			}
			if visible {
				hostingController.didMove(toParent: self)
			}
		}

		let animated = transition.duration > 0 && transition.type != .identity
		if animated {
			transitionParameters.initial.apply(to: hostingController.view)
			animator?.stopAnimation(true)
			animator = UIViewPropertyAnimator(
				duration: transition.duration,
				curve: transition.curve
			)
			if transitionParameters.initial == transitionParameters.final {
				let fakeAnimationView = UIView(frame: .zero)
				view.addSubview(fakeAnimationView)
				animator.addAnimations {
					fakeAnimationView.alpha = 0
				}
				animator.addCompletion { _ in
					fakeAnimationView.removeFromSuperview()
				}
			} else {
				animator.addAnimations(animations)
			}
			animator.addCompletion { position in
				guard position == .end else { return }
				animationCompletion()
			}
			animator.startAnimation()
		} else {
			animations()
			animationCompletion()
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

private extension UIEdgeInsets {
	static func - (lhs: Self, rhs: Self) -> Self {
		Self(top: lhs.top - rhs.top, left: lhs.left - rhs.left, bottom: lhs.bottom - rhs.bottom, right: lhs.right - rhs.right)
	}
}

private extension TransitionParameters.State {
	func apply(to view: UIView) {
		view.frame = frame
		view.alpha = alpha
	}
}
