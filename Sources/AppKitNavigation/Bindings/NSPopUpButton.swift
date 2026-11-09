#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public import AppKit

extension NSPopUpButton {
    /// Creates a pop-up button with an item for each option, and registers the binding against
    /// the selected one.
    ///
    /// ```swift
    /// let weightPopUpButton = NSPopUpButton(
    ///   selection: $model.weight, options: Weight.allCases, title: \.displayName
    /// )
    /// ```
    ///
    /// See ``AppKit/NSPopUpButton/bind(selection:options:title:image:fileID:filePath:line:column:)-(_,[Value],_,_,_,_,_,_)``
    /// for how the items and the binding stay in step.
    ///
    /// - Parameters:
    ///   - frame: The frame rectangle for the view, measured in points.
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user chooses another one.
    ///   - options: The options, in the order of their items.
    ///   - title: The title of the item for an option.
    ///   - image: The image of the item for an option, if items show images.
    ///   - fileID: The source `#fileID` associated with the binding.
    ///   - filePath: The source `#filePath` associated with the binding.
    ///   - line: The source `#line` associated with the binding.
    ///   - column: The source `#column` associated with the binding.
    public convenience init<Value: Equatable>(
        frame: CGRect = .zero,
        selection: UIBinding<Value>,
        options: [Value],
        title: @escaping (Value) -> String,
        image: ((Value) -> NSImage?)? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.init(frame: frame, pullsDown: false)
        bind(
            selection: selection,
            options: options,
            title: title,
            image: image,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    /// Establishes a two-way connection between a binding and the item the pop-up button has
    /// selected, the item at the same position as the bound value among `options`.
    ///
    /// The pop-up button's items must match the options one for one, in order. To have the items
    /// made for you, pass a `title`, as in
    /// ``AppKit/NSPopUpButton/bind(selection:options:title:image:fileID:filePath:line:column:)-(_,[Value],_,_,_,_,_,_)``.
    /// A value that is not one of the options selects no item, and choosing an item past the last
    /// option leaves the binding alone; both are reported as issues.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user chooses another one.
    ///   - options: The options, in the order of the pop-up button's items.
    ///   - fileID: The source `#fileID` associated with the binding.
    ///   - filePath: The source `#filePath` associated with the binding.
    ///   - line: The source `#line` associated with the binding.
    ///   - column: The source `#column` associated with the binding.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Value: Equatable>(
        selection: UIBinding<Value>,
        options: [Value],
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) -> ObserveToken {
        let index = selection.optionIndex(
            among: options, fileID: fileID, filePath: filePath, line: line, column: column
        )
        return bind(index, to: \.appKitNavigationIndexOfSelectedItem) { popUpButton, index, _ in
            if index == -1 {
                reportIssue(
                    """
                    A pop-up button's selection ('\(selection.wrappedValue)') is not one of its \
                    options, so no item is selected.
                    """,
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            }
            popUpButton.appKitNavigationIndexOfSelectedItem = index
        }
    }

    /// Makes an item for each option at the top of the pop-up button's menu, and establishes a
    /// two-way connection between a binding and the chosen option.
    ///
    /// ```swift
    /// visibilityPopUpButton.bind(
    ///   selection: $model.visibilityFilter,
    ///   options: VisibilityFilter.allCases,
    ///   title: \.displayName,
    ///   image: { NSImage(systemSymbolName: $0.iconName, accessibilityDescription: $0.displayName) }
    /// )
    /// ```
    ///
    /// The binding manages only the items it makes. Items the app adds below them, such as a
    /// "New Tag…" item with an action of its own, stay where they are: choosing one leaves the
    /// binding alone, and the pop-up button shows the bound option again afterwards. Binding the
    /// pop-up button again reuses the items made before.
    ///
    /// A value that is not one of the options selects no item, and is reported as an issue.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user chooses another one.
    ///   - options: The options, in the order of their items.
    ///   - title: The title of the item for an option.
    ///   - image: The image of the item for an option, if items show images.
    ///   - fileID: The source `#fileID` associated with the binding.
    ///   - filePath: The source `#filePath` associated with the binding.
    ///   - line: The source `#line` associated with the binding.
    ///   - column: The source `#column` associated with the binding.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Value: Equatable>(
        selection: UIBinding<Value>,
        options: [Value],
        title: @escaping (Value) -> String,
        image: ((Value) -> NSImage?)? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) -> ObserveToken {
        bind(
            selection: selection,
            options: { options },
            title: title,
            image: image,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    /// Makes an item for each of the options a closure returns, and keeps the items and the chosen
    /// option in step as the options change.
    ///
    /// The options, titles and images are read in an observation, so the items follow whatever
    /// those closures read from an observable model:
    ///
    /// ```swift
    /// tagPopUpButton.bind(
    ///   selection: $model.selectedTagID,
    ///   options: { [nil] + model.tags.map(\.id) },
    ///   title: { tagID in tagID.flatMap { model.tags[id: $0]?.name } ?? "No Tag" }
    /// )
    /// ```
    ///
    /// When the number of options changes, items are added or removed at the end of the ones the
    /// binding made; otherwise the existing items are retitled in place, so a menu that is open
    /// keeps its items. Everything else works as in
    /// ``AppKit/NSPopUpButton/bind(selection:options:title:image:fileID:filePath:line:column:)-(_,[Value],_,_,_,_,_,_)``.
    ///
    /// - Parameters:
    ///   - selection: The binding to read from for the selected option, and write to when the
    ///     user chooses another one.
    ///   - options: A closure that returns the options, in the order of their items.
    ///   - title: The title of the item for an option.
    ///   - image: The image of the item for an option, if items show images.
    ///   - fileID: The source `#fileID` associated with the binding.
    ///   - filePath: The source `#filePath` associated with the binding.
    ///   - line: The source `#line` associated with the binding.
    ///   - column: The source `#column` associated with the binding.
    /// - Returns: A cancel token.
    @discardableResult
    public func bind<Value: Equatable>(
        selection: UIBinding<Value>,
        options: @escaping () -> [Value],
        title: @escaping (Value) -> String,
        image: ((Value) -> NSImage?)? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) -> ObserveToken {
        let index = selection.optionIndex(
            among: options, fileID: fileID, filePath: filePath, line: line, column: column
        )
        // NB: The key path only files the binding away, so that binding the pop-up button again
        //     replaces it. Items are matched by identity, not position, since the app may add
        //     items of its own.
        let bindingToken = establishBinding(
            index,
            to: \NSPopUpButton.appKitNavigationIndexOfSelectedItem,
            of: self,
            through: createActionProxyIfNeeded(),
            observesKeyPath: false,
            valueAfterAction: { popUpButton in
                popUpButton.indexOfChosenOption(restoringOptionAt: index.wrappedValue)
            }
        ) { popUpButton, optionIndex, _ in
            let currentOptions = options()
            popUpButton.updateOptionItems(
                titles: currentOptions.map(title),
                images: image.map { image in currentOptions.map(image) }
            )
            if optionIndex == -1 {
                reportIssue(
                    """
                    A pop-up button's selection ('\(selection.wrappedValue)') is not one of its \
                    options, so no item is selected.
                    """,
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            }
            popUpButton.selectOptionItem(at: optionIndex)
        }
        guard let menu else { return bindingToken }
        // NB: An item with an action of its own sends that action instead of the pop-up button's,
        //     so the binding hears of it only through the menu.
        let menuObserver = NotificationObserver(
            name: NSMenu.didSendActionNotification, object: menu
        ) { [weak self] notification in
            guard
                let self,
                let chosenItem = notification.userInfo?["MenuItem"] as? NSMenuItem,
                !appKitNavigationOptionItems.contains(where: { $0 === chosenItem })
            else { return }
            selectOptionItem(at: index.wrappedValue)
        }
        let token = ObserveToken {
            bindingToken.cancel()
            MainActor._assumeIsolated {
                menuObserver.invalidate()
            }
        }
        observationTokens[\NSPopUpButton.appKitNavigationIndexOfSelectedItem] = token
        return token
    }

    // NB: Exposed to Objective-C so the binding can observe it, and named after the library so
    //     that it can never replace a method AppKit has, or adds later, under the same selector.
    @objc var appKitNavigationIndexOfSelectedItem: Int {
        set { selectItem(at: newValue) }
        get { indexOfSelectedItem }
    }

    /// The items made for the options, in the order of the options.
    fileprivate var appKitNavigationOptionItems: [NSMenuItem] {
        get {
            objc_getAssociatedObject(self, optionItemsKey) as? [NSMenuItem] ?? []
        }
        set {
            objc_setAssociatedObject(self, optionItemsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Makes the items for the options match their titles and images. Items are added or removed
    /// only when the number of options changes, at the end of the items made before.
    fileprivate func updateOptionItems(titles: [String], images: [NSImage?]?) {
        guard let menu else { return }
        var optionItems = appKitNavigationOptionItems.filter { $0.menu === menu }
        while optionItems.count > titles.count {
            menu.removeItem(optionItems.removeLast())
        }
        // NB: Inserted through the menu, since 'insertItem(withTitle:at:)' first removes an item
        //     that has the same title, which would leave two options sharing one item.
        var insertionIndex = optionItems.last.map { menu.index(of: $0) + 1 } ?? 0
        while optionItems.count < titles.count {
            let optionItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            menu.insertItem(optionItem, at: insertionIndex)
            insertionIndex += 1
            optionItems.append(optionItem)
        }
        for (position, optionItem) in optionItems.enumerated() {
            optionItem.title = titles[position]
            optionItem.image = images?[position]
        }
        appKitNavigationOptionItems = optionItems
    }

    /// Selects the item for the option at a position, or no item for a position that matches none.
    fileprivate func selectOptionItem(at optionIndex: Int) {
        let optionItems = appKitNavigationOptionItems
        guard optionItems.indices.contains(optionIndex) else {
            // NB: Not 'select(nil)' followed by 'synchronizeTitleAndSelectedItem()', which
            //     selects the first item again.
            selectItem(at: -1)
            return
        }
        select(optionItems[optionIndex])
        // NB: Shows the item's title again when it was retitled in place.
        synchronizeTitleAndSelectedItem()
    }

    /// The position among the options of the item the user chose. For an item the app added, shows
    /// the bound option again and returns `nil`, so that the binding is left alone.
    fileprivate func indexOfChosenOption(restoringOptionAt boundIndex: Int) -> Int? {
        if let selectedItem,
            let position = appKitNavigationOptionItems.firstIndex(where: { $0 === selectedItem })
        {
            return position
        }
        selectOptionItem(at: boundIndex)
        return nil
    }
}

@MainActor
private let optionItemsKey = malloc(1)!
#endif
