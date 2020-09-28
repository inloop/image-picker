import UIKit

/// Redbooth Added.
/// View for showing user that access is denied and to present a settings shortcut.
public class NoPermissionsView: UIView {

    fileprivate var instructionLabel: UILabel = {
        var label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        let grayLevel: CGFloat = 153/255
        label.textColor = UIColor(red: grayLevel, green: grayLevel, blue: grayLevel, alpha: 1.0)
        return label
    }()

    fileprivate var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("Go to Settings", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        return button
    }()

    fileprivate var containerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public init(_ instructionText: String) {
        super.init(frame: .zero)
        instructionLabel.text = instructionText

        setupViews()
        setupConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func navigateToSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
    }
}

fileprivate extension NoPermissionsView {

    func setupViews() {
        backgroundColor = .white
        containerView.addSubview(instructionLabel)
        containerView.addSubview(settingsButton)
        addSubview(containerView)

        settingsButton.addTarget(self, action: #selector(navigateToSettings), for: .touchUpInside)
    }

    func setupConstraints() {
        let instructionConstraints = [
            instructionLabel.leadingAnchor.constraint(equalTo: containerView.readableContentGuide.leadingAnchor),
            instructionLabel.trailingAnchor.constraint(equalTo: containerView.readableContentGuide.trailingAnchor),
            instructionLabel.topAnchor.constraint(equalTo: containerView.topAnchor)
        ]
        let buttonConstraints = [
            settingsButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.readableContentGuide.leadingAnchor),
            settingsButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.readableContentGuide.trailingAnchor),
            settingsButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            settingsButton.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 30),
            settingsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ]
        let containerConstraints = [
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: readableContentGuide.trailingAnchor)
        ]
        NSLayoutConstraint.activate(containerConstraints)
        NSLayoutConstraint.activate(instructionConstraints)
        NSLayoutConstraint.activate(buttonConstraints)
    }
}
