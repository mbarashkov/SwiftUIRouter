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

class HostingControllerWrapper<Content: View, Data>: UIViewController {
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
	}

	var content: (Data) -> Content {
		didSet {
			updateContentIfNeeded()
		}
	}
	var transition: FinalTransition = FinalTransition.identity
	var action: NavigationAction.Action = .push

	private func updateContentIfNeeded() {
		if let contentData = savedContentData, state != .hidden {
			hostingController.rootView = content(contentData)
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		hostingController.view.frame = view.bounds
	}

	private var state = PresenceState.hidden

	private var savedContentData: Data?
	var contentData: Data?

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

		let transitionParameters = createParameters(hostingController.view.frame.size, action)

		let animations = { [self] in
			transitionParameters.final.apply(to: hostingController.view)
		}
		let animationCompletion = { [self] in
			if visible {
				state = .visible
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
			if transitionParameters.initial == transitionParameters.final {
				DispatchQueue.main.asyncAfter(deadline: .now() + transition.duration) { [self] in
					if state == initialState {
						animationCompletion()
					}
				}
			} else {
				let animator = UIViewPropertyAnimator(
					duration: transition.duration,
					curve: .easeOut,
					animations: animations
				)
				animator.addCompletion { position in
					guard position == .end else { return }
					animationCompletion()
				}
				animator.startAnimation()
			}

		} else {
			animations()
			animationCompletion()
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


private extension TransitionParameters.State {
	func apply(to view: UIView) {
		view.frame = frame
		view.alpha = alpha
	}
}
