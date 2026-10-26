import Cocoa

// MARK: - Notification dispatch

extension AppDelegate {
    @IBAction func triggerPickForeground(_: Any) {
        notificationCenter.post(name: .triggerPickForeground, object: self)
    }

    @IBAction func triggerPickBackground(_: Any) {
        notificationCenter.post(name: .triggerPickBackground, object: self)
    }

    @IBAction func triggerPickContrast(_: Any) {
        notificationCenter.post(name: .triggerPickForeground, object: self, userInfo: ["chain": true])
        notificationCenter.post(name: .triggerPickPair, object: self)
    }

    @IBAction func triggerCopyForeground(_: Any) {
        notificationCenter.post(name: .triggerCopyForeground, object: self)
    }

    @IBAction func triggerCopyBackground(_: Any) {
        notificationCenter.post(name: .triggerCopyBackground, object: self)
    }

    @IBAction func triggerSystemPickerForeground(_: Any) {
        notificationCenter.post(name: .triggerSystemPickerForeground, object: self)
    }

    @IBAction func triggerSystemPickerBackground(_: Any) {
        notificationCenter.post(name: .triggerSystemPickerBackground, object: self)
    }

    @IBAction func triggerToggleHistory(_: Any) {
        notificationCenter.post(name: .toggleHistory, object: self)
    }

    @IBAction func triggerToggleColorPreview(_: Any) {
        notificationCenter.post(name: .toggleColorPreview, object: self)
    }

    @IBAction func triggerToggleCompliance(_: Any) {
        notificationCenter.post(name: .toggleCompliance, object: self)
    }

    @IBAction func triggerHistoryPrevious(_: Any) {
        notificationCenter.post(name: .historyPrevious, object: self)
    }

    @IBAction func triggerHistoryNext(_: Any) {
        notificationCenter.post(name: .historyNext, object: self)
    }

    @IBAction func triggerHistoryDelete(_: Any) {
        notificationCenter.post(name: .historyDelete, object: self)
    }

    @IBAction func triggerSwap(_: Any) {
        notificationCenter.post(name: .triggerSwap, object: self)
    }

    /// The `NSTextView` field editor of whichever `ScrubTextField` is currently being edited, if
    /// any — `ScrubTextField.becomeFirstResponder` makes the field editor (not the field itself)
    /// the window's first responder while editing, so this is the one place both `triggerUndo`
    /// and `triggerRedo` need to check to keep Cmd-Z scoped to "whatever the user is actually
    /// looking at": a value being typed, if one is focused, otherwise colour-pick history.
    private var focusedFieldUndoManager: UndoManager? {
        guard let editor = NSApp.keyWindow?.firstResponder as? NSTextView, editor.isFieldEditor else { return nil }
        return editor.undoManager
    }

    @IBAction func triggerUndo(_: Any) {
        if let manager = focusedFieldUndoManager, manager.canUndo {
            manager.undo()
            return
        }
        notificationCenter.post(name: .triggerUndo, object: self)
        eyedroppers.undo()
    }

    @IBAction func triggerRedo(_: Any) {
        if let manager = focusedFieldUndoManager, manager.canRedo {
            manager.redo()
            return
        }
        notificationCenter.post(name: .triggerRedo, object: self)
        eyedroppers.redo()
    }

    @IBAction func triggerCopyText(_: Any) {
        notificationCenter.post(name: .triggerCopyText, object: self)
    }

    @IBAction func triggerCopyData(_: Any) {
        notificationCenter.post(name: .triggerCopyData, object: self)
    }

    @IBAction func triggerFormatHex(_: Any) {
        notificationCenter.post(name: .triggerFormatHex, object: self)
    }

    @IBAction func triggerFormatRGB(_: Any) {
        notificationCenter.post(name: .triggerFormatRGB, object: self)
    }

    @IBAction func triggerFormatHSB(_: Any) {
        notificationCenter.post(name: .triggerFormatHSB, object: self)
    }

    @IBAction func triggerFormatHSL(_: Any) {
        notificationCenter.post(name: .triggerFormatHSL, object: self)
    }

    @IBAction func triggerFormatOpenGL(_: Any) {
        notificationCenter.post(name: .triggerFormatOpenGL, object: self)
    }

    @IBAction func triggerFormatLAB(_: Any) {
        notificationCenter.post(name: .triggerFormatLAB, object: self)
    }

    @IBAction func triggerFormatOKLCH(_: Any) {
        notificationCenter.post(name: .triggerFormatOKLCH, object: self)
    }
}
