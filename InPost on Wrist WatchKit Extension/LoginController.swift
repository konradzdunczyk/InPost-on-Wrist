//
//  LoginController.swift
//  InPost on Wrist WatchKit Extension
//
//  Created by Konrad Zdunczyk on 26/05/2020.
//  Copyright © 2020 Konrad Zdunczyk. All rights reserved.
//

import WatchKit
import RxRelay
import RxCocoa

protocol LoginViewModelType {
    var textFieldPlaceholder: String { get }
    var nextButtonName: String { get }

    var rx_loginInfo: BehaviorRelay<String?> { get }

    func newLoginInfoValue(_ value: String?)
    func next()
}

class LoginViewModel: LoginViewModelType {
    var completionHandler: ((String) -> Void)!

    let textFieldPlaceholder: String
    let nextButtonName: String

    let rx_loginInfo = BehaviorRelay<String?>(value: nil)

    init(fieldInitValue: String?, textFieldPlaceholder: String, nextButtonName: String) {
        self.textFieldPlaceholder = textFieldPlaceholder
        self.nextButtonName = nextButtonName

        rx_loginInfo.accept(fieldInitValue)
    }

    func newLoginInfoValue(_ value: String?) {
        guard let value = value else { return }
        print("new value: \(value)")
        rx_loginInfo.accept(value)
    }

    func next() {
        // TODO: Validation
        guard let value = rx_loginInfo.value else { return }
        completionHandler(value)
    }
}

class LoginController: WKInterfaceController {
    @IBOutlet private var tfLoginInfo: WKInterfaceTextField!
    @IBOutlet private var btnNext: WKInterfaceButton!

    private var _viewModel: LoginViewModelType!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard let vm = context as? LoginViewModelType else {
            fatalError("Wrong VM type")
        }

        _viewModel = vm
        applyValues()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    private func applyValues() {
        tfLoginInfo.setText(_viewModel.rx_loginInfo.value)
        tfLoginInfo.setPlaceholder(_viewModel.textFieldPlaceholder)

        btnNext.setTitle(_viewModel.nextButtonName)
    }

    @IBAction private func loginInfoValue(_ value: NSString?) {
        let newValue = value as String?
        _viewModel.newLoginInfoValue(newValue)
    }

    @IBAction func nextButtonTap() {
        _viewModel.next()
    }
}
