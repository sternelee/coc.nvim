# Changelog

Notable changes of coc.nvim:

## 2025-07-30

- Add configurable kind for dialog messages, through the use of the new configuration
  'messageDialogKind' which can be set to 'menu', 'notification', or 'confirm'.

## 2025-07-18

- Add `extensionDependencies` support, declare dependencies on other extensions: `"extensionDependencies": ["extension-1", "extension-2"]`

## 2025-07-17

- Add notifications history, view with `:CocList notifications`

## 2025-06-11

- LSP 3.18 and latest vscode-languageclient features:
    - SnippetTextEdit support
        - Add `SnippetTextEdit` interface and namespace.
        - The `TextDocumentEdit.edits` array now allows `SnippetTextEdit`.
        - API `workspace.applyEdits()` now accepts `SnippetTextEdit`.
        - Introduced `StringValue` to represent snippet strings (kind: 'snippet', value: string).
    - Inline completion support, see `:h coc-inlineCompletion`
        - Add `InlineCompletionItem` `InlineCompletionList` interface and namespace.
        - Add enum `InlineCompletionTriggerKind`.
        - Add interfaces `InlineCompletionContext` `InlineCompletionItemProvider`.
        - Add method `languages.registerInlineCompletionItemProvider()`.
        - Inline completion support of LanguageClient.
        - Support `LanguageClient.getFeature('textDocument/inlineCompletion')`.
        - Support inline completion middleware `Middleware.provideInlineCompletionItems`.
    - Workspace‐edit metadata & applyEdit
        - Add `metadata` to `ApplyWorkspaceEditParams`.
        - Add `metadata` parameter to `workspace.applyEdit()`.
    - Richer `ErrorHandler.error()` and `ErrorHandler.closed()` return types
        - New interfaces `ErrorHandlerResult` and `CloseHandlerResult` (include
            `action`, optional `message`, optional `handled` flag)
        - `error()` and `closed()` may now return these richer results instead of bare enums.
    - Trace & output‐channel improvements.
        - Add `traceOutputChannel` to `LanguageClientOptions`.
        - Middleware can now intercept all requests and notifications via
            `sendRequest` and `sendNotification`.
    - Delayed “didOpen” notifications
        - Option `textSynchronization.delayOpenNotifications` was added to
            `LanguageClientOptions` so that `didOpen` can wait until a document is
            actually visible (or until another message is sent).
    - Text‐document‐content provider support
        - Registration type workspace/textDocumentContent to support custom‐
            scheme content providers.
        - Support `middleware.provideTextDocumentContent` of LanguageClient.
        - Support `LanguageClient.getFeature('workspace/textDocumentContent')`.
    - Support `transport` of `Executable` server option.  Transport could be
      `pipe` and `socket`

## 2025-06-02

- Add function keys support to notification popups on vim9.
- Use notification dialogs with actions (instead of menu picker) when
  'enableMessageDialog' is enabled.

## 2025-05-21

- Perform format on save after execute `editor.codeActionsOnSave`, the same as
  VSCode.

## 2025-05-20

- Add `winid` (current window ID) to `CursorHold` and `CursorHoldI` events handler.

## 2025-05-19

- Add `ModeChanged` event and `mode` property to `events`.

## 2025-05-13

- Change document highlight priority to -1 to avoid override search highlight
  on vim9.
- `start_incl` and `end_incl` options works on neovim.

## 2025-05-08

- For terminal created by `coc#ui#open_terminal`, close the terminal window on
  terminal finish, make the behavior on vim9 the same as nvim.
- Use lua and vim9 for highlight functions.

## 2025-05-04

- Execute python on snippet resolve, disable snippet synchronize on completion.
- Change of none primary placeholder would not update placeholders with same
  index, like UltiSnip does.
- Add API `snippetManager.insertBufferSnippets()`.

## 2025-05-03

- The performance with popupmenu navigation on vim9 have improved, for some
  cases, it's more than 10 times faster.
- Break change: current line is not synchronized after use the pum API like
  `coc#pum#select()`, see `:h coc#pum#select()`, functions used as expr
  key-mappings should be not affected.
- Break change: configuration `suggest.segmentChinese` replaced with
  `suggest.segmenterLocales`, see `:h coc-config-suggest-segmenterLocales`.
- Add `CompleteStart` event to `events` module.

## 2025-04-25

- Add `-level` argument support to diagnostics list.
- Make lines event send before TextChange events on vim9.

## 2025-04-23

- Add configuration `inlayHint.maximumLength`, default to `0`

## 2025-04-21

- Add `WindowVisible` event to `events`.
- Add `onVisible()` support to `BufferSyncItem`.
- Improve inlay hint:
    - Use lua and vim9 for virtual text api.
    - Add `coc#vtext#set()` for set multiple virtual texts.
    - Render all inlay hints for the first time.
    - Use `WindowVisible` event.

## 2025-04-18

- Add `nvim.createAugroup()`, `nvim.createAutocmd()` and `nvim.deleteAutocmd()`.
- Add `buffer` `once` and `nested` support to `workspace.registerAutocmd()`.
- Not throw error from autocmd callback, log the error instead.
- Add configuration `editor.autocmdTimeout`.

## 2025-04-17

- Support `$COC_VIM_CHANNEL_ENABLE` for enable channel log on vim9.
- Add `nvim.callVim()`, `nvim.evalVim()` and `nvim.exVim()`.

## 2025-04-15

- Support 'title' for configuration `suggest.floatConfig` and `suggest.pumFloatConfig`.
- Use timer for `CocStatusChange` autocmd to avoid cursor vanish caused by `redraws`.
- Use vim9 script for api.vim and refactor related functions.
- Add `coc#compat#call` for call api functions on vim or neovim.
- Add `special` to interface `KeymapOption` (vim9 only).

## 2025-04-06

- Add `cmd` option to interface `KeymapOption`.
- Add `KeymapOption` support to `workspace.registerLocalKeymap()`

## 2025-04-04

- Add `right_gravity` property to `VirtualTextOption`.

## 2025-04-03

- Add `disposables` argument to `workspace.registerAutocmd()`
- Change behavior for failure autocmd request, echo message instead of throw
  error.

## 2025-04-02

- Add method `window.getVisibleRanges()` to typings.
- Break change: set `w:cocViewId` to upper case letters, see `:h w:cocViewId`

## 2025-04-01

- Add configuration `workspace.removeEmptyWorkspaceFolder` default to `false`.
- Add configuration `editor.codeActionsOnSave`, similar to VSCode.

## 2025-03-31

- Change `placeHolder`to `placeholder` for `QuickPickOptions` like VSCode (old
  option still works).
- Change interface `DocumentSelector`, could also be `DocumentFilter` or
  `string`, not only array of them.
- Add `context.extensionUri` like VSCode.
- Add `document` property to `DidChangeTextDocumentParams`, like VSCode.
- Add `before()` and `after()` methods to `LinkedMap`, same as VSCode.
- Add `onFocus` and `match()` to `DiagnosticPullOptions`.
- Add `onFocus` to `DiagnosticPullMode` and export `DiagnosticPullMode`
- Add interface `InlineValuesProvider`, `DiagnosticProvider` to typings.
- Add missing properties to `LanguageClient` class, including
  `createDefaultErrorHandler()`, `state` `middleware` `isInDebugMode`
  `isRunning()` `dispose()` `getFeature()`

## 2025-03-29

- Add `bufnr` to `WinScrolled` event.

## 2025-03-28

- Improve vim9 highlight by vim9 script #5285.

## 2025-03-27

- Reworked snippets for UltiSnips options and actions support, see `:h coc-snippets` and #5282.

## 2025-03-13

- Add `coc.preferences.autoApplySingleQuickfix` configuration

## 2025-03-07

- Support `extensions.recommendations` configuration.
- Support for UltiSnip options `t` `m` `s`.

## 2025-03-05

- Export method `workspace.fixWin32unixFilepath` for filepath convert.
- Add commands `document.enableInlayHint` and `document.disableInlayHint`.
- Refresh popup menu when completing incomplete sources.

## 2025-03-04

- Add VSCode command `workbench.action.openSettingsJson`.
- Add `workspace.isTrusted` property.

## 2025-03-03

- Add command `workspace.openLocalConfig`.
- Support vim built with win32unix enabled, including cygwin, git bash, WSL etc.

## 2025-02-24

- Configurations for file system watch, see `:h coc-config-fileSystemWatch`.

## 2025-02-23

- All global properties works with extensions #5222.
- Return true or false for boolean option on vim (same as neovim).
- Support completion sources using vim9script module.

## 2025-02-22

- QuickPick works with vim without terminal support.

## 2025-02-21

- To avoid unexpected signature help window close, signature help will be triggered after placeholder jump by default, when autocmd `CocJumpPlaceholder call CocActionAsync('showSignatureHelp')` not exists.
- Support `global.formatFilepath` function for customize filepath displayed in symbols & location list.

## 2025-02-20

Use `extensions` section for extension related configurations. Deprecated configuration sections: `coc.preferences.extensionUpdateCheck`, `coc.preferences.extensionUpdateUIInTab` and `coc.preferences.silentAutoupdate`.

## 2025-01-03

- Add `diagnostic.displayByVimDiagnostic` configuration, set diagnostics to `vim.diagnostic` on nvim, and prevent coc.nvim's handler to display in virtualText/sign/floating etc.

## 2024-12-10

- Floating window can be set to fixed position, try `diagnostic.floatConfig`
- `ensureDocument` and `hasProvider` support to accept specified bufnr

## 2024-11-29

- Increase `g:coc_highlight_maximum_count` default to 500 for better performance.
- Add `uriConverter.code2Protocol` for extensions

## 2024-10-25

- Mention [davidosomething/coc-diagnostics-shim.nvim](https://github.com/davidosomething/coc-diagnostics-shim.nvim) as alternative to ALE for diagnostics display.

## 2024-08-28

- Add configuration `codeLens.display`

## 2024-08-20

- Add `CocAction('removeWorkspaceFolder')`.
- Expanded the quick pick API in typings

## 2024-08-12

- Added `coc.preferences.formatterExtension` configuration

## 2024-07-04

- Added `NVIM_APPNAME` support

## 2024-06-27

- Added `inlayHint.position` configuration, with `inline` and `eol` options

## 2024-06-20

- Added `coc.preferences.extensionUpdateUIInTab` to open `CocUpdate` UI in tab

## 2024-05-29

- Break change: increase minimum vim/nvim version requirement
  - vim 9.0.0438
  - nvim 0.8.0

## 2024-05-14

- Added `suggest.reTriggerAfterIndent` to control re-trigger or not after indent changes

## 2024-05-07

- Allow `CocInstall` to install extension from Github in development mode

## 2024-04-12

- Change scope of codeLens configuration to `language-overridable`

## 2024-03-26

- Added new `--workspace-folder` argument for diagnostics lists
- Added new `--buffer` argument for diagnostics lists

## 2024-02-28

- Increase `g:coc_highlight_maximum_count` default to 200
- Break change: semanticTokens highlight groups changed:
  - `CocSem + type` to `CocSemType + type`
  - `CocSem + modifier + type` to `CocSemTypeMod + type + modifier`

## 2024-03-06

- add `outline.autoHide` configuration to automatically hide the outline window when an item is clicked

## 2024-02-27

- Add `g:coc_disable_mappings_check` to disable key-mappings checking
- Add `suggest.chineseSegments` configuration to control whether to divide Chinese sentences into segments or not

## 2023-09-02

- Support `g:coc_list_preview_filetype`.

## 2023-08-31

- Minimal node version changed from 14.14.0 to 16.18.0.
- Inlay hint support requires neovim >= 0.10.0.
- Removed configurations:
  - `inlayHint.subSeparator`
  - `inlayHint.typeSeparator`
  - `inlayHint.parameterSeparator`

## 2023-01-30

- Always show `cancellable` progress as notification without check
  `notification.statusLineProgress`.

## 2023-01-29

- Exclude `source` actions when request code actions with range.
- Any character can be used for channel name.

## 2023-01-26

- Add escape support to `coc#status()`.

## 2023-01-24

- Add `encoding` and `CancellationToken` support for `runCommand` function.

## 2023-01-23

- Make `vscode.open` command work with file uri.
- Cancel option for `workspace.registerExprKeymap()`.
- Support `suggest.filterOnBackspace` configuration.

## 2023-01-22

- `maxRestartCount` configuration for configured language server.

## 2022-12-25

- Create symbol tree from SymbolInformation list.

## 2022-12-23

- Support `URI` as param for API `workspace.jumpTo()`.

## 2022-12-22

- Support popup window for window related APIs.

## 2022-12-21

- When create `CocSem` highlight group, replace invalid character of token types
  and token modifiers with underline.

## 2022-12-20

- Export `Buffer.setKeymap` and `Buffer.deleteKeymap` with vim and neovim support.
- Make `workspace.registerLocalKeymap` accept bufnr argument.

## 2022-12-12

- Allow configuration of `window` scoped used by folder configuration file, like
  VSCode.
- Add location support for `getHover` action.
- Use unique id for each tab on vim.
- Chinese word segmentation for keywords.

## 2022-12-05

- Add `switchConsole` method to `LanguageClient`

## 2022-12-03

- Add configuration `suggest.insertMode`.

## 2022-12-02

- Expand variables for string configuration value.

## 2022-11-30

- File fragment support for `workspace.jumpTo()`.
- Support `g:coc_open_url_command`.
- Support `contributes.configuration` from extension as array.

## 2022-11-29

- Add documentations for develop of coc.nvim extensions.
- Remove unused variable `g:coc_channel_timeout`.

## 2022-11-28

- Placeholder and update value support for `InputBox` and `QuickPick`.
- `triggerOnly` option property for vim completion source.
- Export `getExtensionById` from `extensions` module.

## 2022-11-26

- Use CTRL-R expression instead of timer for pum related functions:

  - `coc#pum#insert()`
  - `coc#pum#one_more()`
  - `coc#pum#next()`
  - `coc#pum#prev()`
  - `coc#pum#stop()`
  - `coc#pum#cancel()`
  - `coc#pum#confirm()`

## 2022-11-25

- Avoid view change on list create.
- Add configurations `links.enable` and `links.highlight`.
- Use cursorline for list on neovim (to have correct highlight).
- Fix highlight not work on neovim 0.5.0 by use `luaeval`.

## 2022-11-22

- Add command `document.toggleCodeLens`.

## 2022-11-21

- Add `CocAction('addWorkspaceFolder')`.

## 2022-11-20

- Support code lens feature on vim9.
- `codeLens.subseparator` default changed to `|`, like VSCode.
- Add configuration `coc.preferences.enableGFMBreaksInMarkdownDocument`, default to `true`
- Add key-mappings `<Plug>(coc-codeaction-selected)` and `<Plug>(coc-codeaction-refactor-selected)`.

## 2022-11-19

- Create highlights after VimEnter.
- Action 'organizeImport' return false instead of throw error when import code
  action not found.

## 2022-11-18

- Throw error when rpc request error, instead of echo message.

## 2022-11-13

- Plugin emit ready after extensions activated.

## 2022-11-12

- Not cancel completion when request for in complete sources.

## 2022-11-11

- Support filter and display completion items with different start positions.
- Remove configuration `suggest.fixInsertedWord`, insert word would always
  be fixed.
- Configuration `suggest.invalidInsertCharacters` default to line break
  characters.

## 2022-11-10

- Not reset 'Search' highlight on float window as it could be used.
- Note remap `<esc>` on float preview window.
- Add new action `feedkeys!` to list.
- Add new configuration `list.floatPreview`.

## 2022-11-07

- Add API `CocAction('snippetInsert')` for snippet insert from vim plugin.
- Snippet support for vim source, snippet item should have `isSnippet` to be
  `true` and `insertText` to be snippet text, when `on_complete` function exists,
  the snippet expand should be handled completion source.

## 2022-11-06

- `window.createQuickPick()` API that show QuickPick by default, call `show()`
- Fix change value property for QuickPick not works.

## 2022-10-30

- Add configuration `colors.enable`, mark `colors.filetypes` deprecated.
- Add command `document.toggleColors` for toggle colors of current buffer.
- Changed filter of completion to use code from VSCode.
- Add configuration `suggest.filterGraceful`

## 2022-10-39

- Add configuration `suggest.enableFloat` back.

## 2022-10-27

- Use `workspace.rootPatterns` replace `coc.preferences.rootPatterns`, old
  configuration still works when exists.
- Store configurations with configuration registry.

## 2022-10-25

- Add `--height` support to `CocList`.

## 2022-10-24

- Use builtin static words source for snippet choices.
- Remove configuration `"snippet.choicesMenuPicker"`
- Remove unused internal functions `coc#complete_indent()` and
  `coc#_do_complete()`

## 2022-10-21

- Consider utf-16 code unit instead of unicode code point.
- Add `coc#string#character_index()` `coc#string#byte_index()` and
  `coc#string#character_length()`.

## 2022-10-20

- Add `coc#pum#one_more()`

## 2022-10-19

- Trigger for trigger sources when no filter results available.

## 2022-10-18

- Change `suggest.maxCompleteItemCount` default to 256.

## 2022-10-17

- Set `g:coc_service_initialized` to `0` before service restart.
- Show warning when diagnostic jump failed.
- Use strwidth.wasm module for string display width.
- Add API `workspace.getDisplayWidth`.

## 2022-10-15

- Add configuration `inlayHint.display`.

## 2022-10-07

- Use `CocFloatActive` for highlight active parameters.

## 2022-09-28

- Limit popupmenu width when exceed screen to &pumwidth, instead of change
  completion column.
- Make escape of `${name}` for ultisnip snippets the same behavior as
  Ultisnip.vim.

## 2022-09-27

- Use fuzzy.wasm for native fuzzy match.
- Add `binarySearch` and `isFalsyOrEmpty` functions for array.
- `suggest.localityBonus` works like VSCode, using selection ranges.
- Add and export `workspace.computeWordRanges`.
- Rework keywords parse for better performance (parse changed lines only and use
  yield to reduce iteration).

## 2022-09-12

- All configurations are now scoped #4185
- No `onDidChangeConfiguration` event fired when workspace folder changed.
- Deprecated configuration `suggest.detailMaxLength`, use `suggest.labelMaxLength` instead.
- Deprecated configuration `inlayHint.filetypes`, use `inlayHint.enable` with scoped languages instead.
- Deprecated configuration `semanticTokens.filetypes`, use `semanticTokens.enable` with scoped languages instead.
- Use `workspaceFolderValue` instead of `workspaceValue` for `ConfigurationInspect` returned by `WorkspaceConfiguration.inspect()`.

## 2022-09-04

- Add configuration "snippet.choicesMenuPicker".

## 2022-09-03

- Send "WinClosed" event to node client.
- Add `onDidFilterStateChange` and `onDidCursorMoved` to `TreeView`.
- Support `autoPreview` for outline.

## 2022-09-02

- Support `diagnostic.virtualTextFormat`.
- Add command `workspace.writeHeapSnapshot`.

## 2022-09-01

- Add configuration "suggest.asciiMatch"
- Support `b:coc_force_attach`.

## 2022-08-31

- Add configuration "suggest.reversePumAboveCursor".
- Use `DiagnosticSign*` highlight groups when possible.
- Use `DiagnosticUnderline*` highlight groups when possible.

## 2022-08-30

- Export `LineBuilder` class.

## 2022-08-29

- Fix semanticTokens highlights unexpected cleared
- Fix range of `doQuickfix` action.
- Check reverse of `CocFloating`, use `border` and `Normal` highlight when reversed.
- Make `CocInlayHint` use background of `SignColumn`.
- Add command `document.toggleInlayHint`.

## 2022-08-28

- Make `CocMenuSel` use background of `PmenuSel`.
- Snippet related configuration changed (old configuration still works until next release)
  - "coc.preferences.snippetStatusText" -> "snippet.statusText"
  - "coc.preferences.snippetHighlight" -> "snippet.highlight"
  - "coc.preferences.nextPlaceholderOnDelete" -> "snippet.nextPlaceholderOnDelete"
- Add configuration `"list.smartCase"`
- Add configurations for inlay hint
  - "inlayHint.refreshOnInsertMode"
  - "inlayHint.enableParameter"
  - "inlayHint.typeSeparator"
  - "inlayHint.parameterSeparator"
  - "inlayHint.subSeparator"

## 2022-08-27

- Avoid use `EasyMotion#is_active`, use autocmd to disable linting.
- Show message when call hierarchy provider not found or bad position.

## 2022-08-26

- Remove `completeOpt` from `workspace.env`.
- Add configuration `"diagnostic.virtualTextAlign"`.
- Add warning when required features not compiled with vim.
- Not echo error for semanticTokens request (log only).
- Merge results form providers when possible.

## 2022-08-24

- Virtual text of suggest on vim9.
- Virtual text of diagnostics on vim9.
- Add configuration `inlayHint.filetypes`.
- Inlay hint support on vim9.

## 2022-08-23

- Retry semanticTokens request on server cancel (LSP 3.17).
- `RelativePattern` support for `workspace.createFileSystemWatcher()`.
- `relativePatternSupport` for `DidChangeWatchedFiles` (LSP 3.17).
- Not echo error on `doComplete()`.

## 2022-08-21

- Added `window.createFloatFactory()`, deprecated `FloatFactory` class.
- Support `labelDetails` field of `CompleteItem`(LSP 3.17).
- Added `triggerKind` to `CodeActionContext`, export `CodeActionTriggerKind`.

## 2022-08-20

- Support pull diagnostics `:h coc-pullDiagnostics`.
- Break change: avoid extension overwrite builtin configuration defaults.
- Change default value of configuration "diagnostic.format".
- 'line' changes to 'currline' for `CocAction('codeAction')`.
- Check NodeJS version on syntax error.

## 2022-08-10

- Change "notification.highlightGroup" default to "Normal".

## 2022-08-07

- Add configuration 'suggest.pumFloatConfig'.

## 2022-08-04

- Make diagnostic float window with the same background as CocFloating.

## 2022-08-03

- Add highlight group 'CocFloatingDividingLine'.

## 2022-08-01

- Use custom popup menu, #3862.
- Use "first" instead of "none" for configuration `suggest.selection`.
- Make "first" default for `suggest.selection`, like VSCode.
- Add default blue color for hlgroup `CocMenuSel`.

## 2022-06-14

- Add highlight groups `CocListLine` and `CocListSearch`.

## 2022-06-11

- Add configuration "notification.disabledProgressSources"
- Add "rounded" property to "floatConfig"

## 2022-06-04

- Add configuration `workspace.openOutputCommand`.
- Log channel message of vim when `g:node_client_debug` enabled.

## 2022-05-30

- Disable `progressOnInitialization` for language client by default.

## 2022-05-28

- Support `repeat#set` for commands that make changes only.

## 2022-05-24

- Add transition and annotation support for `workspace.applyEdits()`.
- Add command `workspace.undo` and `workspace.redo`.
- Remove configuration `coc.preferences.promptWorkspaceEdit`.
- Remove command `CocAction` and `CocFix`.

## 2022-05-22

- Check for previous position when not able to find completion match.
- Add `content` support to `window.showMenuPicker()`

## 2022-05-17

- Add `QuickPick` module.
- Add API `window.showQuickPick()` and `window.createQuickPick()`.

## 2022-05-16

- Add properties `title`, `loading` & `borderhighlight` to `InputBox`

## 2022-05-14

- Add `InputOption` support to `window.requestInput`
- Add API `window.createInputBox()`.

## 2022-05-13

- Notification support like VSCode <https://github.com/neoclide/coc.nvim/discussions/3813>
- Add configuration `notification.minProgressWidth`
- Add configuration `notification.preferMenuPicker`
- Support `source` in notification windows.

## 2022-05-07

- Show sort method as description in outline view.
- Add configuration `outline.switchSortKey`, default to `<C-s>`.
- Add configuration `outline.detailAsDescription`, default to `true`.
- Add variable `g:coc_max_treeview_width`.
- Add `position: 'center'` support to `window.showMenuPicker()`

## 2022-05-06

- Use menu for `window.showQuickpick()`.
- Add configuration `outline.autoWidth`, default to `true`.

## 2022-05-05

- Add key bindings to dialog (created by `window.showDialog()`) on neovim.

## 2022-05-04

- Add `languages.registerInlayHintsProvider()` for inlay hint support.

## 2022-04-25

- Add `LinkedEditing` support

## 2022-04-23

- Add `WinScrolled` event to events.

## 2022-04-20

- Select recent item when input is empty and selection is `recentUsedByPrefix`.
- Add `coc#snippet#prev()` and `coc#snippet#next()`.
- Add command `document.checkBuffer`.
- Add `region` param to `window.diffHighlights()`.

## 2022-04-06

- `workspace.onDidOpenTextDocument` fire `contentChanges` as empty array when
  document changed with same lines.

## 2022-04-04

- Avoid `CompleteDone` cancel next completion.
- Avoid indent change on `<C-n>` and `<C-p>` during completion.
- Support `joinUndo` and `move` with `document.applyEdits()`.

## 2022-04-02

- Change `suggest.triggerCompletionWait` default to `0`.
- Not trigger completion on `TextChangedP`.
- Remove configuration `suggest.echodocSupport`.
- Fix complettion triggered after `<C-e>`.

## 2022-03-31

- Check buffer rename on write.

## 2022-03-30

- Improve words parse performance.
- Remove configurations `coc.source.around.firstMatch` and `coc.source.buffer.firstMatch`.
- Fix `coc.source.buffer.ignoreGitignore` not works
- Check document reload on detach.

## 2022-03-29

- Add menu actions to refactor buffer.

## 2022-03-12

- Avoid use `<sapce><bs>` for cancel completion.

## 2022-03-05

- Make `WinClosed` event fires on `CursorHold` to support vim8.
- Add events `TabNew` and `TabClose`.
- Make outline reuse TreeView buffer.

## 2022-03-02

- Add ultisnip option to `snippetManager.insertSnippet()` and
  `snippetManager.resolveSnippet()`.
- Support ultisnip regex option: `/a` (ascii option).
- Support transform replacement of ultisnip, including:
  - Variable placeholders, `$0`, `$1` etc.
  - Escape sequence `\u` `\l` `\U` `\L` `\E` `\n` `\t`
  - Conditional replacement: `(?no:text:other text)`

## 2022-02-28

- Change `workspace.ignoredFiletypes` default value to `[]`

## 2022-02-24

- Add `window.activeTextEditor`, `window.visibleTextEditors`.
- Add events `window.onDidChangeActiveTextEditor` `window.onDidChangeVisibleTextEditors`.
- Add class `RelativePattern`.
- Add `workspace.findFiles()`.

## 2022-02-23

- Add `workspace.openTextDocument()`
- Add `Workspace.getRelativePath()`.
- Add `window.terminals` `window.onDidOpenTerminal` `window.onDidCloseTerminal`
  and `window.createTerminal`.
- Add `exitStatus` property to `Terminal`.
- Support `strictEnv` in `TerminalOptions` on neovim.
- Deprecated warning for `workspace.createTerminal()`,
  `workspace.onDidOpenTerminal` and `workspace.onDidCloseTerminal`

## 2022-02-18

- Clear all highlights created by coc.nvim before restart.
- Support strike through for ansiparse.
- Support `highlights` for `Documentation` in float window.

## 2022-02-17

- Change workspace configuration throw error when workspace folder can't be
  resolved.
- Remove configuration `diagnostic.highlightOffset`.

## 2022-02-15

- Add `events.race`.
- Change default `suggest.triggerCompletionWait` to 50.
- Support trigger completion after indent fix.

## 2022-02-14

- Add `pumvisible` property to events.

## 2022-02-10

- Add shortcut support for `window.showMenuPicker()`.
- Add configuration `dialog.shortcutHighlight` for shortcut highlight.
- Add configuration `list.menuAction` for choose action by menu picker.

## 2022-02-09

- Add error log to `nvim_error_event`.
- Add `nvim.lua()` which replace `nvim.executeLua()` to typings.d.ts.

## 2022-02-08

- Support `MenuItem` with disabled property for `window.showMenuPicker`
- Support show disabled code actions in menu picker.

## 2022-02-07

- Change `:CocLocalConfig` to open configuration file of current workspace
  folder.

## 2022-02-05

- Support `version` from `textDocument/publishDiagnostics` notification's parameter.
- Support `codeDescription` of diagnostics by add href to float window.
- Support `showDocument` request from language server.
- Support `label` from DocumentSymbolOptions in outline tree.
- Support extra url use regexp under cursor with `openLink` action.
- Support `activeParameter` from signature information.
- Add `trimTrailingWhitespace`, `insertFinalNewline` and `trimFinalNewlines` to FormattingOptions.
- Add configuration `links.tooltip`, default to `false`.

## 2022-02-04

- Add `--reverse` option to list.
- Add `<esc>` key-mapping to cancel list in preview window (neovim only).

## 2022-02-02

- Remove `disableWorkspaceFolders` `disableDiagnostics` and `disableCompletion`
  from language client option.
- Add configuration `documentHighlight.timeout`.
- Add `tabPersist` option to `ListAction`.
- Add `refactor` to `LocationList`

## 2022-01-30

- Add configuration `diagnostics.virtualTextLevel`.
- Remove configuration `suggest.numberSelect`

## 2022-01-26

- Use `nvim_buf_set_text` when possible to keep extmarks.

## 2022-01-25

- Not trigger completion when filtered is succeed.
- Move methods `workspace.getSelectedRange` `workspace.selectRange` to `window`
  module, show deprecated warning when using old methods.

## 2022-01-23

- Support semantic tokens highlights from range provider.

## 2022-01-22

- Not set `gravity` with api `nvim_buf_set_extmark` because highlight bug, wait neovim fix.
- Support watch later created workspace folders for file events.

## 2022-01-21

- Changed semantic token highlight prefix from `CocSem_` to `CocSem`.
- Changed semantic token highlight disabled by default, use configuration
  `semanticTokens.filetypes`
- Add configuration `semanticTokens.filetypes`.
- Add configuration `semanticTokens.highlightPriority`.
- Add configuration `semanticTokens.incrementTypes`.
- Add configuration `semanticTokens.combinedModifiers`.
- Add configuration `workspace.ignoredFolders`.
- Add configuration `workspace.workspaceFolderFallbackCwd`.
- Add command `semanticTokens.refreshCurrent`.
- Add command `semanticTokens.inspect`.
- Add action `inspectSemanticToken`.
- Rework command `semanticTokens.checkCurrent` to show highlight information.
- Support semantic tokens highlight group composed with type and modifier.

## 2022-01-20

- Remove deprecated method `workspace.resolveRootFolder`.

## 2022-01-17

- Extend `buffer.updateHighlights` to support `priority`, `combine`, `start_incl` and `end_incl`.
- Add configuration `diagnostic.highlightPriority`.
- Add configuration `colors.filetypes` and `colors.highlightPriority`.

## 2022-01-16

- Add configuration `codeLens.position`.

## 2022-01-14

- Add configuration `suggest.selection`.

## 2022-01-13

- `codeLens.separator` now defaults to `""` and will be placed above lines on neovim >= 0.6.0 .
- Add configurations 'diagnostic.locationlistLevel', 'diagnostic.signLevel', 'diagnostic.messageLevel'.

## 2022-01-12

- Add document.lineAt(), export TextLine class.
- Upgrade node-client, support nvim.exec().
- Add documentHighlight.priority configuration.

## 2019-08-18 0.0.74

- feat(cursors): support multiple cursors.
- feat(extensions): install missing extensions by CocInstall.
- feat(extensions): add command `extensions.forceUpdateAll`.
- feat(completion): rework preselect feature.
- feat(extension): use request for fetch package info.
- feat(language-client): support disableDynamicRegister configuration.
- feat(list): paste from vim register support on insert mode #1088.
- feat(plugin): add CocHasProvider(), close #1087.
- refactor(outline): not exclude variables and callback.
- refactor(diagnostic): remove timeout on InsertLeave.

## 2019-07-11 0.0.73

- fix(completion): fix map of number select
- fix(languages): fix cursor position with snippet
- fix(completion): fix cursor position with additionalTextEdits
- fix(position): fix rangeOverlap check #961
- fix(list): not change guicursor when it's empty
- fix(list): fix filter not work on loading
- fix(list): fix custom location list command not work
- fix(util): highlight & render on vim8
- fix(handler): fix getCommands
- fix(handler): not check lastInsert on trigger signatureHelp
- fix(handler): fix check of signature help trigger
- fix(language-client): configuration for configured server, closes #930
- fix(diagnostic): clear diagnostics on filetype change
- feat(plugin): add download & fetch modules
- feat(plugin): add highlighter module
- feat(refactor): add `<Plug>(coc-refactor)` for refactor window
- feat(extension): use mv module for folder rename
- feat(extension): support install tagged extension
- feat(extension): support custom extension root `g:coc_extension_root`
- feat(handler): close signature float window on ')'
- feat(list): support `g:coc_quickfix_open_command`
- feat(list): add eval action
- feat(list): add --tab list option
- feat(list): use highlighter module for showHelp
- feat(terminal): add noa on window jump
- feat(terminal): support vim8
- feat(diagnostic): add diagnosticRelated support
- feat(diagnostic): use text properties on vim8
- feat(handler): improve signature float window

## 2019-07-01

- feat(plugin): add CocStatusChange autocmd
- feat(extension): support both npm and yarn.
- feat(plugin): work on vim 8.0
- feat(extensions): add lock & doc actions to extension source
- feat(extension): add proxy auth support (#920)
- feat(source): not change startcol for file source
- feat(completion): no numberSelect for number input
- feat(extensions): Use yarn when npm not found
- feat(completion): no popup for command line buffer
- feat(plugin): support only for codeActions action
- feat(task): debounce stdout
- feat(plugin): add keymaps for selection ranges
- feat(plugin): add function textobj
- feat(list): restore window height, closes #905
- feat(handler): support signature.floatTimeout
- feat(configuration): support change of workspace configuration
- feat(diagnostic): add keymaps for jump error diagnostics
- feat(plugin): delay start on gvim, fix #659

## 2019-06-15

- feat(plugin): add popup support of vim
- refactor(completion): improve float support
- refactor(floating): remove unused code
- refactor(workspace): replace find-up
- refactor(handler): improve message for fold method
- fix(virtualtext): invalid highlight tag (#874)
- fix(snippets): fix plaintext check
- fix(highlight): catch error of child_process.spawn
- fix(highlight): use v:progpath, fix #871
- fix(floatFactory): escape feedkeys
- fix(handler): fix getCurrentFunctionSymbol not work

## 2019-06-12

- feat(document): add getVar method
- fix(util): not break selection on message
- fix(workspace): fix jumpTo not work on vim8
- fix(completion): trigger completion with word character
- refactor(handler): return boolean result
- perf(workspace): improve jump performance
- fix(util): Escape filename for jump (#862)
- refactor(plugin): not show empty hover
- feat(outline): ignore callback function
- feat(workspace): support list of events with registerAutocmd
- fix(workspace): fix jump with tab drop
- refactor(language-client): change API of selectionRanges

## 2019-06-09

- **Break change** `CocHighlightText` link to `CursorColumn` by default.
- **Break change** logger folder changed to `$XDG_RUNTIME_DIR` when exists.
- Add `<PageUp>` and `<PageDown>` support for list, #825.
- Add function `coc#add_command()`.
- Add `disableDiagnostics` & `disableCompletion` to languageclient configuration.
- Add `signature.triggerSignatureWait` configuration.
- Add vim-repeat support for run command and quickfix.
- Add preferred `codeAction` support.
- Add `prompt.paste` action to list.
- Add title as argument support for `codeAction` action.
- Add `suggest.floatEnable` configuration.
- Add `editor.action.organizeImport` command.
- Add `:CocAction` and `:CocFix` commands.
- Add `codeActions` action.
- Fix issues with list.

## 2019-05-30

- **Break change** logger folder changed.
- Add support of vim-repeat for `<Plug>` keymaps.
- Add `CocRegistNotification()` function.
- Add argument to rename action.
- Add `suggest.disableMenuShortcut` configuration.
- Add glob support for root patterns.
- Add `<esc>` keymap to list window.
- Add shortcut in sources list.
- Add `list.previewSplitRight` configuration.
- Add `triggerOnly` property to source.
- Add warning for duplicate extension.
- Bug fixes.

## 2019-05-07

- **New feature** load extensions from coc-extensions folder.
- Add `workspace.renameCurrentFile` command.
- Add `FloatBuffer`, `FloatFactory` and `URI` to exports.
- Add `resolveItem` support to list.
- Fix prompt can't work when execute list action.
- Fix ansiparser for empty color ranges.
- Fix highlight only work with first 8 items.

## 2019-04-27

- **Break change** vim-node-rpc not required on vim.
- **Break change** python not required on vim.
- **Break change** complete items would refreshed after 500ms when not finished.
- Add `additionalSchemes` for configured language server.
- Add support for jumpCommand as false.
- Fix `diagnostic.level` not work.

## 2019-04-09

- **Break change** `--strictMatch` option of list renamed to `--strict`
- **Break change** `suggest.reloadPumOnInsertChar` support removed.
- **Break change** no more binary release.
- **Break change** logic for resolve workspace folder changed.
- Add `Task` module.
- Add `getCurrentFunctionSymbol` action.
- Add `list.source.outline.ctagsFiletypes` setting.
- Add `suggest.disableMenu` and `suggest.disableMenu` settings.
- Add `equal` support for complete items.
- Add support for do action with visual select lines of list.
- Add expand tilder support for language server command.
- Add switch matcher support to list.
- Add select all support to list.
- Add quickfix action to list.
- Add `selectionRanges` of LSP.
- Add load extensions for &rtp support.
- Add `coc#on_enter()` for formatOnType and add new lines on enter.
- Improve completion by support trigger completion when pumvisible.
- Remove document check on `BufWritePre`.

## 2019-03-31

- **Break change** not using vim-node-rpc from npm modules any more.
- **Break change** rename `<Plug>_` to `<Plug>CocRefresh`.
- Fix wrong format options send to server.
- Fix throw error when extension root not created.
- Fix MarkedString not considered as markdown.
- Fix echo message on vim exit.
- Fix error throw on file watch.
- Fix unexpected update of user configuration.

## 2019-03-28

- Add `workspace.resolveRootFolder`.
- Add `diagnostic.joinMessageLines` setting.
- Add `suggest.completionItemKindLabels` setting.
- Add `memento` support for extension.
- Add `workspace.getSelectedRange`.
- Add `Terminal` module.
- Add command `workbench.action.reloadWindow`.
- Fix extension not activated by command.
- Fix broken undo with floating window.
- Fix document create possible wrong uri & filetype.
- Improve highlight with floating window.

## 2019-03-24

- **Break change** make number input not trigger completion.
- **Break change** make none keywords character doesn't filter completion.
- Add functions for check snippet state.
- Add setting `diagnostic.checkCurrentLine`.
- Fix `signature.target` not work.
- Fix flick of signature window.
- Fix EPIPE error of node-client.
- Fix wrong root of FileWatchSysmtem.

## 2019-03-19

- **Break change** signature settings now starts `signature`.
- **Break change** default request timeout changed to 5s.
- **Break change** `commands.executeCommand` return promise.
- Add `coc.preferences.signatureHelpTarget`.
- Add `diagnostic.maxWindowHeight` & `signature.maxWindowHeight`.
- Add `diagnostic.enableSign`.
- Add support for `$COC_NO_PLUGINS`.
- Add keymaps: `<Plug>(coc-float-hide)` and `<Plug>(coc-float-jump)`.
- Add `coc.preferences.enableFloatHighlight`.
- Fix issues with floating window.
- Fix critical performance issue on diff text.
- Improve color of `CocHighlightText`.
- Improve sort of complete items.
- Improve extension list with version and open action.

## 2019-03-16

- **Break change** change vim config home on windows to '\$HOME/vimfiles'.
- Add highlights to float windows.
- Add CocLocationsAsync().
- Add support for `b:coc_suggest_disable`.
- Add support for `b:coc_suggest_blacklist`.
- Add setting `diagnostic.messageTarget`.
- Add floating window support for signatures.
- Fix issues with diagnostic float.
- Fix info of completion item not shown.
- Fix CocUpdateSync not work without service start.
- Fix wrong indent spaces of snippets.

## 2019-03-11

- **Break change** change buffers instead of disk file for `workspace.applyEdits`.
- **Break change** add config errors to diagnostic list instead of jump locations.
- **Break change** hack for popup menu flicker is removed, use `suggest.reloadPumOnInsertChar` to enable it.
- **Break change** use `nvim_select_popupmenu_item` for number select completion.
- Add floating window for completion items.
- Add floating window support for diagnostics.
- Add floating window support for hover documentation.
- Add `coc#on_enter()` for notify enter pressed.
- Add setting `coc.preferences.useQuickfixForLocations`.
- Add support of `g:coc_watch_extensions` for automatic reload extensions.
- Add command: `editor.action.doCodeAction`.
- Fix service on restarted on windows after rebuild.
- Fix config of airline.
- Fix relative path of watchman.
- Improve Mru model.

## 2019-03-03

- **Break change** signature change of `workspace.registerKeymap`.
- **Break change** `<esc>` of CocList can't be remapped any more.
- **Break change** use `yarnpkg` command instead of `yarn` when possible.
- **Break change** `noinsert` is removed from `completeopt` when `noselect` is
  enabled, `<CR>` would break line by default.
- Add setting `diagnostic.refreshAfterSave`.
- Add chinese documentation.
- Add support of multiple line placeholder.
- Fix edit of nested snippet placeholders.
- Fix possible infinite create of documents.
- Fix check for resume completion.

## 2019-02-25

- **Break change** default of `suggest.detailMaxLength` changed to 100.
- **Break change** option of `workspace.registerKeymap` changed.
- Add settings: `suggest.detailField`.
- Add check for autocmd in health check.
- Add trigger patterns support for complete sources.
- Add support of `coc-snippets-expand-jump`
- Add `source` option for completion start.
- Add `sources.createSource` method.

## 2019-02-22

- **Break change** some configurations have been renamed, checkout #462.
- **Break change** no longer automatic trigger for CursorHoldI #452.
- **Break change** add preview option of `completeopt` according to `suggest.enablePreview`.
- Add statusItem for CocUpdate.
- Add `-sync` option for `:CocInstall`
- Add support for floating preview window.
- Add more module export.
- Fix check of vim-node-rpc throw error.
- Fix wrong line for TextEdit of complete item.
- Fix diagnostics not cleared on service restart.

## 2019-02-17

- **Break change** completion resolve requires CompleteChanged autocmd.
- **Break change** mapping of space on insert mode of list removed.
- **Break change** kind of completion item use single letter.
- Fix snippet not works on GUI vim.
- Fix cursor vanish on vim by use timer hacks.
- Fix behavior of list preview window.
- Fix python check on vim.
- Fix CocJumpPlaceholder not fired.
- Fix vscode-open command not work.

## 2019-02-12

- **Break change** function `coc#util#clearmatches` signature changed.
- Add check for python gtk module.
- Add check for vim-node-rpc update error.
- Fix source name of diagnostics.
- Fix empty buffers created on preview.
- Fix trigger of `CursorHoldI`.

## 2019-02-11

- **Break change:** internal filetype of settings file changed to jsonc.
- **Break change:** `coc#util#install` changed to synchronize by default.
- **Break change:** no document highlight would be added for colored symbol.
- **Break change:** remove `coc.preferences.openResourceCommand`.
- Add fallback rename implementation which rename symbols on current buffer.
- Add command `:CocUpdateSync`.
- Add `coc.preferences.detailMaxLength` for slice detail on completion menu.
- Add cancel support for completion.
- Add `ctags` as fallback of document symbols list.
- Add default key-mappings for location actions.
- Add python check on vim.
- Add `disableSyntaxes` support for completion sources.
- Add support for change `isProgress` of `StatusBarItem`
- Add check of coc.nvim version for `CocUpdate`
- Add `coc.preferences.previewAutoClose`, default true.
- Add `workspace.add registerAutocmd`.
- Fix highlight not cleared on vim
- Fix health check of service state.
- Fix CursorHoldI not triggered on neovim.
- Fix sort of list not stable.

## 2019-02-04

- **Break change:** no messages when documentSymbol and workspaceSymbol provider
  not found.
- Add support for configure sign in statusline.
- Add help action for list.
- Fix parse error on extensions update.
- Fix wrong uri on windows.
- Fix cancel list without close ui.
- Improve startup time by remove jobwait.

## 2019-02-02

- **Break change:** extensions now update automatically, prompt is removed.
- Add check for extension compatibility.
- Add transform support for placeholder.
- Add check for node version.
- Add error check for list.
- Add settings: `coc.preferences.diagnostic.virtualTextLines`.
- Fix preview window not shown.
- Fix highlight not cleared on vim.
- Fix highlight commands of list block vim on start.
- Improve extension load.
- Improve list experience.

## 2019-01-28

- **Break change:** `coc.preferences.diagnostic.echoMessage` changed to enum.
- Add mru support for commands and lists list.
- Add `coc.preferences.diagnostic.refreshOnInsertMode`
- Add `Mru` module.
- Improve highlight for lists, support empty `filterLabel`.
- Fix `findLocations` not work with nest locations.
- Fix cursor position after apply additionalTextEdits.

## 2019-01-24

- **Break change:** python code for denite support moved to separated repo.
- **Break change:** Quickfix list no longer used.
- Add list support.
- Add configuration: `coc.preferences.diagnostic.virtualText`.
- Add watch for `&rtp` change.
- Add support for configure `g:coc_user_config` and `g:coc_global_extensions`
- Add support for send request to coc on vim start.
- Add `g:coc_start_at_startup` support.
- Add configuration: `coc.preferences.invalidInsertCharacters`.
- Add configuration: `coc.preferences.snippetStatusText`.
- Add `coc#_insert_key()` for insert keymap.
- Add `workspace.registerExprKeymap()`.
- Add detect for `vim-node-rpc` abnormal exist.
- Add `requireRootPattern` to languageserver configuration.
- Fix git check, always generate keywords.
- Fix crash when `righleft` set to 1 on neovim.
- Fix snippet position could be wrong.

## 2019-01-09

- **Break change:** throw error when languageserver id is invalid.
- Add watcher for languageserver configuration change.
- Fix possible invalid package.json.
- Fix applyEdits not work sometimes.
- Fix server still started when command search failed.
- Fix log file not writeable.
- Improve completion performance.

## 2019-01-03

- **Break change:** using of `g:rooter_patterns` is removed.
- **Break change:** diagnostics would be updated in insert mode now.
- Add configuration: `coc.preferences.rootPatterns`
- Add `TM_SELECTED_TEXT` and `CLIPBOARD` support for snippets.
- Fix check of latest insert char failed.
- Fix highlight not cleared sometimes.

## 2019-01-01

- Fix issues with completion.

## 2018-12-31

- **Break change:** created keymaps use rpcrequest instead of rpcnotify.
- **Break change:** snippets provider is removed, use `coc-snippets` for
  extension snippets.
- Add command: `coc.action.insertSnippet`
- Fix position of snippets.
- Fix modifier of registered keymaps.
- Fix completion triggered on complete done.
- Fix closure function possible conflict.
- Fix unexpected snippet cancel.
- Fix document applyEdits, always use current lines.
- Fix fail of yarn global command.
- Fix check of changedtick on completion done.
- Fix line used for textEdit of completion.
- Fix snippet canceled by `formatOnType`.
- Fix `CocJumpPlaceholder` not fired
- Optimize content synchronize.

## 2018-12-27

- **Break change:** no more message on service ready.
- **Break change:** vim source now registered as extension.
- **Break change:** complete item sort have reworked.
- **Break change:** request send to coc would throw when service not ready.
- Add support for check current state on diagnostic update.
- Add `env` opinion for registered command languageserver.
- Add outputChannel for watchman.
- Add `coc#_select_confirm()` for trigger select and confirm.
- Add `coc.preferences.numberSelect`.
- Add priority support for format provider.
- Add `workspace.watchGlobal` and `workspace.watchOption` methods.
- Fix cursor disappear on `TextChangedP` with vim.
- Fix coc process not killed when update on windows.
- Fix snippet broken on vim.
- Fix support of startcol of completion result.
- Fix `labelOffsetSupport` wrong position.
- Fix flicking on neovim.
- Fix unicide not considered as iskeyword.
- Fix watchman client not initialized sometimes.
- Improve performance for parse iskeyword.
- Not echo message on vim exit.
- Not send empty configuration change to languageserver.

## 2018-12-20

- **Break change** configuration for module language server, transport now
  require specified value.
- **Break change** new algorithm for socre complete items.
- Add command `workspace.clearWatchman`.
- Add `quickfixs`, `doCodeAction` and `doQuickfix` actions.
- Add `g:vim_node_rpc_args` for debug purpose.
- Add `coc#add_extension()` for specify extensions to install.
- Fix clients not restarted on CocRestart.
- Fix `execArgv` and `runtime` not work for node language server.
- Fix detail of complete item not echoed sometimes.
- Fix actions missing when registered with same clientId.
- Fix issues with signature echo.
- Fix uri is wrong with whitespace.
- Improve highlight performance with `nvim_call_atomic`.

## 2018-12-17

- **Break change** `vim-node-rpc` now upgrade in background.
- Add `ignoredRootPaths` to `languageserver` option.
- Add detect of vim running state.
- Add `client.vim` for create clients.
- Fix possible wrong current line of `completeResolve`.
- Fix snippet not work with `set virtualedit=all`.
- Fix default timeout to 2000.
- Fix file mode of log file.

## 2018-12-12

- **Break change** `fixInsertedWord` fix inserted word which ends with word
  after.
- **Break change** `onCompleteSelect` is removed.
- Add `workspace.registerKeymap` for register keymap.
- Add match score for sort complete items.
- Fix possible connection lost.
- Fix priority of diagnostic signs.
- Fix possible wrong uri.
- Fix `RevealOutputChannelOn` not default to `never`.
- Fix possible wrong line used for textEdit of complete item.
- Fix possible wrong cursor position of snippet after inserted.

## 2018-12-08

- **Break change** default rootPath would be directory of current file, not cwd.
- **Break change** codeLens feature now disabled by default.
- **Break change** diagnostic prev/next now loop diagnostics.
- Add support of neovim highlight namespace.
- Add support for undo `additionalTextEdits` on neovim
- Fix configuration resolve could be wrong.
- Fix word of completion item could be wrong.
- Fix rootPath could be null.
- Fix highlight not cleared on restart.

## 2018-12-06

- **Break change** `RevealOutputChannelOn` of language client default to
  `never`.
- Fix can't install on windows vim.
- Fix `displayByAle` not clearing diagnostics.
- Add check for `vim-node-rpc` update on vim.
- Add `Resolver` module.
- Improve apply `WorkspaceEdit`, support `0` as document version and merge
  edits for same document.

## 2018-12-05

- Add `CocJumpPlaceholder` autocmd.
- Add `rootPatterns` to `languageserver` config.
- Add setting: `coc.preferences.hoverTarget`, support use echo.
- Add setting `coc.preferences.diagnostic.displayByAle` for use ale to display errors.
- Add setting `coc.preferences.extensionUpdateCheck` for control update check of
  extensions.
- Add `coc#config` for set configuration in vim.
- Fix rootPath not resolved on initialize.
- Fix possible wrong `tabSize` by use `shiftwidth` option.
- Fix trigger of `documentColors` request.
- Fix `vim-node-rpc` service not work on windows vim.
- Fix `codeLens` not works.
- Fix highlight of signatureHelp.
- Fix watchman watching same root multiple times.
- Fix completion throw undefined error.
- Fix `open_terminal` not works on vim.
- Fix possible connection lost by use notification when possible.
- Fix process not terminated when connection lost.
- Rework diagnostics with task sequence.
- Rework configuration with more tests.

## 2018-11-28

- _Break change_ signature help reworked, vim API for echo signature changed.
- Add `:CocInfo` command.
- Add trigger for signature help after function expand.
- Add echo message when provider not found for some actions.
- Add support for `formatexpr`
- Add support for locality bonus like VSCode.
- Add support of `applyAdditionalLEdits` on item selected by `<esc>`
- Add `coc.preferences.useQuickfixForLocations`
- Add `coc.preferences.messageLevel`
- Add support for trigger command which not registered by server.
- Add `g:coc_denite_quickfix_action`
- Fix insert unwanted word when trigger `commitCharacter`.
- Fix rpc request throw on vim.
- Fix `data` of complete item conflict.
- Fix code action not work sometime.
- Fix `coc.preferences.diagnostic.locationlist` not work.
- Fix `coc.preference.preferCompleteThanJumpPlaceholder`.
- Fix `workspace.jumpTo` not work sometime.
- Fix line indent for snippet.
- Fix trigger of `signatureHelp` and `onTypeFormat`.

## 2018-11-24

- **Break change** sources excluding `around`, `buffer` or `file` are extracted
  as extensions.
- **Break change** custom source doesn't exist any more.
- Add `coc.preferences.preferCompleteThanJumpPlaceholder` to make jump
  placeholder behavior as confirm completion when possible.
- Add `CocDiagnosticChange` autocmd for force statusline update.
- Add `onDidUnloadExtension` event on extension unload.
- Fix `getDiagnosticsInRange`, consider all interactive ranges.
- Fix completion throw when `data` on complete item is `string`.
- Fix `commitCharacters` not works.
- Fix workspace methods: `renameFile`, `deleteFile` and `resolveRoot`.
- Fix textEdit of builtin sources not works.

## 2018-11-19

- **Break change** snippet support reworked: support nest snippets, independent
  session in each buffer and lots of fixes.
- **Break change** diagnostic list now sort by severity first.
- Add commands: `:CocUninstall` and `:CocOpenLog`
- Add cterm color for highlights.
- Add line highlight support for diagnostic.
- Add `coc.preferences.fixInsertedWord` to make complete item replace current word.
- Fix check confirm not works on vim sometimes.
- Fix check of `vim-node-rpc`.
- Fix preselect complete item not first sometimes.
- Improve completion sort result by consider more abort priority and recent
  selected.
- Improve colors module, only highlight current buffer and when buffer changed.
- Improve `doc/coc.txt`

## 2018-11-13

- **Break change** default completion timeout changed to 2s.
- **Break change** snippet session not canceled on `InsertLeave`, use
  `<esc>` in normal mode to cancel.
- Add document color support.
- Add CocAction 'pickColor' and 'colorPresentation'.
- Add prompt for install vim-node-rpc module.
- Add support for `inComplete` completion result.
- Add status item for snippet session.
- Add support for fix inserted text of snippet completion item.
- Fix document highlight not cleared.
- Fix cancel behavior of snippet.
- Fix range check of edit on snippet session.
- Fix check of completion confirm.
- Fix highlight group 'CocHighlightWrite' not work.
- Fix command `editor.action.rename` not works.
- Fix throw error before initialize.
- Fix `g:coc_node_path` not working.
- Fix file source throw undefined error.
- Improve logic of sorting completion items, strict match items comes first.

## 2018-11-07

- **Break change** word source removed from custom sources, enabled for markdown
  by default.
- **Break change** ignore sortText when input.length > 3.
- **Break change** show prompt for install `coc-json` when not found.
- Fix document content synchronize could be wrong.
- Fix filetype not converted on completion.
- Fix complete item possible not resolved.
- Improve document highlight, no highlight when cursor moved.
- Improve completion score, use fuzzaldrin-plus replace fuzzaldrin.

## 2018-11-02

- **Break change** no items from snippets source when input is empty.
- **Break change** `javascript.jsx` would changed to `javascriptreact` as languageId.
- **Break change** `typescript.tsx` would changed to `typescriptreact` as languageId.
- Add support for `commitCharacters` and `coc.preferences.acceptSuggestionOnCommitCharacter`.
- Add setting: `coc.preferences.diagnostic.level`.
- Add `g:coc_filetype_map` for customize mapping between filetype and languageId.
- Add `g:coc_node_path` for custom node executable.
- Add `workspaceFolders` feature to language client.
- Add `~` to complete item of snippet source.
- Add `onDidChangeWorkspaceFolder` event
- Fix `eol` issue by check `eol` option.
- Fix `workspace.document` could be null.
- Fix `workspaceFolder` could be null.
- Fix diagnostic for quickfix buffer.
- Fix resolve of `coc.preferences.rootPath`

## 2018-10-29

- **Break change** diagnostic reworked, no refresh on insert mode.
- **Break change** keep `sortText` on filter for better result.
- **Break change** prefer trigger completion than filter, same as VSCode.
- **Break change** filetype of document would be first part of `&filetype` split by `.`.
- **Break change** prefer label as abbr for complete item.
- Fix creating wrong `textEdit` for snippet.
- Fix `startcol` of `CompleteResult` not working.
- Fix `workspaceConfiguration.toJSON` return invalid result.
- Fix `workspace.readFile` not synchronized with buffer.
- Fix `workspace.rootPath` not resolved as expected.
- Fix `CompletionItem` resolved multiple times.
- Fix check of `latestInsert` on completion.
- Fix `formatOnType` possible add unnecessary indent.
- Fix document content synchronized on vim.
- Fix confirm check of completion for all source.
- Fix document possible register multiple times.
- Fix completion always stopped when input is empty.
- Add warning message when definition not found.
- Add `redraw` after `g:coc_status` changed.
- Remove change of `virtualedit` option of snippet.
- Improved performance of filter completion items.

## 2018-10-25

- Fix `implementation` and `typeDefinition` of language client not working.
- Fix `diffLines` return wrong range.
- Fix `setqflist` and `setloclist` not works on vim.
- Fix snippets and `additionalTextEdits` not works on vim.
- Fix append lines not works on vim.
- Fix highlight action not works on vim.
- Fix null version of `TextDocumentIdentifier` not handled.
- Add `workspace.registerTextDocumentContentProvider` for handle custom uri.
- Add `workspace.createStatusBarItem` method.

## 2018-10-21

- **Break change**: `triggerAfterInsertEnter` now respect `minTriggerInputLength`.
- Add `coc.preferences.minTriggerInputLength`.
- Add command: `:CocCommand`.
- Fix `position` of `provideCompletionItems`.
- Fix content change not trigger after completion.
- Fix default sorters & matchers of denite sources.
- Fix `outputChannel` wrong `buftype`.
- Fix completion not works with `textEdit` add new lines.
- Fix first item not resolved when `noselect` is disabled
- Remove using of `diff` module.

## 2018-10-18

- **Break change**: all buffers are created as document.
- **Break change**: retrieve workspace root on document create.
- Fix `uri` for all buffer types.
- Fix bad performance on parse keywords.
- Fix check of language client state.
- Fix register of `renameProvider`
- Fix `CocRequestAsync` not work.
- Fix `workspace.openResource` error with `wildignore` option.
- Fix output channel can't shown if hidden.
- Fix extension activate before document create.
- Add command `vscode.open` and `editor.action.restart`.
- Add `workspace.requestInput` method.
- Add support of `g:rooter_patterns`
- Add `storagePath` to `ExtensionContext`
- Add `workspace.env` property.
- Add support of scoped configuration.
- Disable buffer highlight on vim.

## 2018-10-14

- **Break change** API: `workspace.resoleModule` only does resolve.
- **Break change** extension would still be loaded even if current coc version
  miss match.
- **Break change** variables are removed from view of `Denite coc-symbols`
- Fix `workspace.applyEdits`
- Fix `console.log` throws in extension.
- Fix invalid `workspace.root` with custom buffer schema.
- Fix possible crash on neovim 0.3.1 by not attach terminal buffer.
- Fix jump position not stored when jump to current buffer position.
- Fix install function not works on vim.
- Add support for custom uri schema for `workspace.jumpTo` and `workspace.openResource`
- Add `workspace.findUp` for find up file of current buffer.
- Add `env` option for custom language server config.
- Add vim function: `CocRequest` and `CocRequestAsync` for send request to
  language server in vim.
- Add `coc.preferences.parseKeywordsLimitLines` and `coc.preferences.hyphenAsKeyword`
  for buffer parse.
- Rework completion for performance and accuracy.

## 2018-10-05

- **Break change**, `workspace.onDidChangeConfiguration` emit `ConfigurationChangeEvent` now.
- Add `position` to function `coc#util#open_terminal`.
- Improve performance of completion by use vim's filter when possible.
- Fix service start multiple times.
- Fix parse of `iskeyword` option, consider `@-@`.
- Fix completion of snippet: cancel on line change.

## 2018-10-01

- Improved document `didChange` before trigger completion.
- Add option `coc.preferences.triggerCompletionWait`, default 60.
- Add watch for `iskeyword` change.
- Fix snippet jump not works sometime.
- Fix possible wrong `rootPath` of language server.
- Fix highlight of highlight action not using terminal colors.
- Fix detect for insert new line character.

## 2018-09-30

- Add quickfix source of denite and fzf
- Add option `coc.preferences.rootPath`
- Add option `revealOutputChannelOn` to language server.
- Fix jump of placeholder.
- Fix empty root on language server initialize.

## 2018-09-28

- **Break change**: `coc.preferences.formatOnType` default to `false`.
- **Break change**: snippet completion disabled in `string` and `comment`.
- Add support for register local extension.
- Add title for commands in `Denite coc-command`
- Fix prompt hidden by echo message.
- Fix contribute commands not shown in denite interface.
- Fix parse of `iskeyword`, support character range.
- Fix `triggerKind` of completion.
- Fix install extension from url not reloaded.

## 2018-09-27

- **Break change**: `:CocDisable` disabled all events from vim.
- **Break change**: new snippet implementation.
  - Support multiple line snippet.
  - Support VSCode snippet extension.
  - Support completion of snippets from snippet extension.
- Add highlight groups for different severity.
- Add `coc.preferences.formatOnType` option.
- Add `coc.preferences.snippets.enable` option.
- Fix snippet not works as `insertText`.
- Fix echo message with multiple lines.
- Fix `signatureHelp` with `showcmd` disabled.
- Fix location list cleared on `:lopen`.
- Fix diagnostic info not cleared on `:CocDisable`
- Fix diagnostic info not cleared on buffer unload.
- Fix buffer highlight not cleared on `highlight` action.
- Fix format on type not work as expected.

## 2018-09-24

- **Break change**: use `CursorMove` instead of `CursorHold` for diagnostic
  message.
- **Break change**: direct move to diagnostic position would show diagnostic
  message without truncate.
- **Break change**: snippet would be canceled when mode changed to normal, no
  mapping of `<esc>` any more.
- Add format document on `insertLeave` when `onTypeFormat` is supported.
- Add buffer operations on resource edit.
- Add `uninstall` action for `Denite coc-extension`.
- Fix active extension on command not working.
- Fix delete file from resource edit not works.

## 2018-09-20

- Fix diagnostic check next offset for diagnostics.
- Add `<Plug>(coc-diagnostic-info)` for show diagnostic message without
  truncate.

## 2018-09-15

- Fix wrong configuration on update.
- Fix install command with tag version.
- Fix using of unsafe `new Buffer`.
- Add support of trace format & resource operations.
- Add support of json validation for extension.
- Add support of format on save by `coc.preferences.formatOnSaveFiletypes`

## 2018-09-10

- Add `Denite coc-extension` for manage extensions.
- Add actions for manage extension including `toggleExtension` `reloadExtension`
  `deactivateExtension`
- Add check for extension update everyday.
- Fix extensions using same process of coc itself.
- Fix `configurationSection` should be null if none was specified.

## 2018-09-07

- **Break change**: all extension all separated from core, checkout
  [Using coc extension](https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions)
- Fix `textDocumentSync` option not work when received as object.
- Fix wrong diagnostic info when using multiple lint servers.
- Use `CursorHold` for show diagnostic message.
- Add option `coc.preferences.enableMessage` to disable showing of diagnostic
  message.
- Add new events module for receive vim events.
- Add support for `prepareRename`.
- Add support for `CodeActionOptions`

## 2018-08-30

- Fix wrong `triggerKind` from VSCode.
- Add `<Plug>(coc-openlink)` for open link.
- Add `typescript.jsx` as valid typescript type.

## 2018-08-23

- Fix sometimes client status invalid.
- Add multiply provider support for all features.
- Add `documentLink` support
- Add `documentHighlight` support
- Add `foldingRange` support
- Add support of `documentSelector` same as VSCode

## 2018-08-21

- Fix diagnostic and arguments of tsserver.
- Add `keepfocus` option for `open_terminal`.
- Improve error catch of autocmds.
- Add `onTypeFormat` feature for language server
- Add `onTypeFormat` support for tsserver.
- Refactor and more tests of workspace.
- Fix `window/showMessageRequest` request.
- Use `callAsync` for async request to vim.
- Add `CocActionAsync` function send async request to server.

## 2018-08-17

- Fix exists terminal buffer not watched.
- Fix buffer not attached after `edit!`.
- Fix clean diagnostics of `tsserver.watchBuild` command.
- Fix refresh of buffer.
- Fix document not found on `BufEnter`.

  Use `rpcrequest` for `BufCreate`

- Fix no permission of log file.

  Disable create log file for root user.

- Add more command for tsserver:

  - `tsserver.reloadProjects`
  - `tsserver.openTsServerLog`
  - `tsserver.goToProjectConfig`
  - `tsserver.restart`

- Add test for workspace.

## 2018-08-16

- Improved for tsserver:

  - Add `watchBuild` command for build current project with watch in terminal.
  - Support of untitled buffer
  - Support `projectRootPath`

- Fix detach error of document.
- Fix trigger characters not works for some source.
- Fix document possible not sync before save.
- Fix denite errors with 0 as result.
- Fix wrong arguments of tsserver refactor command.
- Use `drop` for workspace `openResource`.
- Add clear coc signs on `:CocRestart`.
- **Break change** all buffer types except `nofile` `help` and `quickfix` are
  watched for changes.

## 2018-08-15

- Fix filter of completion items on fast input.
- Fix sometimes fails of include & neosnippet source.
- Fix sometimes fails to find global modules.
- Improve complete source initialization.

  - Always respect change of configuration.

- Add ability to start standalone coc service for debugging.

  - Use `NVIM_LISTEN_ADDRESS=/tmp/nvim nvim` to start
    neovim.
  - Start coc server by command like `node bin/server.js`

- Add ability to recover from unload buffer.

  Sometimes `bufReadPost` `BufEnter` could be not be fired on buffer create,
  check buffer on `CursorHold` and `TextChanged` to fix this issue.

- Add tsserver features: `tsserver.formatOnSave` and `tsserver.organizeImportOnSave`

  Both default to false.

- Add tests for completion sources.

## 2018-08-14

- Fix remote source not working.
- Fix sort of completion items.
- Fix EPIPE error from net module.
- Add `tslint.lintProject` command.
- Add config `coc.preferences.maxCompleteItemCount`.
- Add `g:coc_auto_copen`, default to `1`.

## 2018-08-12

- **Break change** `:CocRefresh` replaced with `call CocAction('refreshSource')`.
- Add support filetype change of buffer.
- Add basic test for completion.
- Improve loading speed, use child process to initialize vim sources.
- Improve install.sh, install node when it doesn't exist.
- Improve interface of workspace.
- Fix loading of configuration content.

## 2018-08-11

- Fix configuration content not saved on change.
- Fix thrown error on watchman not found.
- Fix incompatible options of `child_process`.
- Fix location list for diagnostics.

  - Reset on `BufWinEnter`.
  - Available for all windows of single buffer.
  - Use replace on change for coc location list.
  - Add debounce.

- Fix signature help behaviour, truncate messages to not overlap.
- Reworks sources use async import.

## 2018-08-10

- Fix dispose for all modules.
- Add support for multiple `addWillSaveUntilListener`.
- Fix `startcol` for json server.
- Add support filetype `javascriptreact` for tsserver.

## 2018-08-09

- Add `coc#util#install` for installation.
- Add `install.cmd` for windows.

## 2018-08-08

- Improved location list for diagnostics.
- Add `internal` option to command.

  Commands registered by server are internal.

- Add support for multiple save wait until requests.

## 2018-08-07

- Add `forceFullSync` to language server option.

## 2018-08-05

- Improve eslint extension to use workspaceFolder.
- Fix watchman not works with multiple roots.
- Add feature: dynamic root support for workspace.
- **Break change** output channel of watchman is removed.

## 2018-08-04

- Fix order of document symbols.
- Fix completion snippet with `$variable`.
- Add feature: expand snippet on confirm.
- Add feature: `<Plug>(coc-complete-custom)` for complete custom sources.

  Default customs sources: `emoji`, `include` and `word`

- **Break change** `emoji` `include` used for all filetypes by default.

## 2018-08-03

- Add command `:CocErrors` for debug.
- Support `DocumentSymbol` for 'textDocument/documentSymbol'

## 2018-08-02

- Fix error of language client with unsupported schema.

  No document event fired for unsupported schema (eg: fugitive://)

- Fix update empty configuration not works.

## 2018-07-31

- Improve file source triggered with dirname started path.

## 2018-07-30

- Fix source ultisnip not working.
- Fix custom language client with command not working.
- Fix wrong arguments passed to `runCommand` function.
- Improve module install, add `sudo` for `npm install` on Linux.
- Improve completion on backspace.
  - Completion is resumed when search is empty.
  - Completion is triggered when user try to fix search.

## 2018-07-29

- **Break change** all servers are decoupled from coc.nvim

  A prompt for download is shown when server not found.

- **Break change** `vim-node-rpc` decoupled from coc.nvim

  A prompt would be shown to help user install vim-node-rpc in vim.

- Add command `CocConfig`

## 2018-07-28

- Fix uncaught exception error on windows.
- Use plugin root for assets resolve.
- Fix emoji source not triggered by `:`.
- Improve file source to recognize `~` as user home.

## 2018-07-27

- Prompt user for download server module with big extension like `vetur` and `wxml-langserver`
- **Break change**, section of settings changed: `cssserver.[languageId]` moved to `[languageId]`

  For example: `cssserver.css` section is moved to `css` section.

  This makes coc settings of css languages the same as VSCode.

- **Break change**, `stylelint` extension is disabled by default, add

  ```json
  "stylelint.enable": true,
  ```

  to your `coc-settings.json` to enable it.

  User will be prompted to download server if `stylelint-langserver` is not
  installed globally.

- **Break change**, `triggerAfterInsertEnter` is always `true`, add

  ```json
  "coc.preferences.triggerAfterInsertEnter": false,
  ```

  to your `coc-settings.json` to disable it.

- **Break change**, when `autoTrigger` is `always` completion would be triggered
  after completion item select.

## 2018-07-24

- better statusline integration with airline and lightline.

## 2018-07-23

- Coc service start much faster.
- Add vim-node-rpc module.
- **Break change** global function `CocAutocmd` and `CocResult` are removed.
- Support Vue with vetur

## 2018-07-21

- Fix issue with `completeopt`.
- Add source `neosnippet`.
- Add source `gocode`.

## 2018-07-20

- Add documentation for language server debug.
- Rework register of functions, avoid undefined function.

## 2018-07-19

- Fix error of `isFile` check.
- Ignore undefined function on service start.

## 2018-07-17

- Add `coc.preference.jumpCommand` to settings.
- Make coc service standalone.

## 2018-07-16

- Support arguments for `runCommand` action.
- Add coc command `workspace.showOutput`.
- Support output channel for language server.
- Support `[extension].trace.server` setting for trace server communication.

## 2018-07-15

- Support location list for diagnostic.
- Add tsserver project errors command.

## 2018-07-14

- Add support for `preselect` of complete item.
- Add support for socket language server configuration.
- Fix configured language server doesn't work.
- Add `workspace.diffDocument` coc command.
- Fix buffer sometimes not attached.
- Improve completion of JSON extension.

## 2018-07-13

- **Break change:** `diagnostic` in setting.json changed to `diagnostic`.
- Fix clearHighlight arguments.
- Add eslint extension <https://github.com/Microsoft/vscode-eslint>.
- Fix snippet break with line have \$variable.
- Use jsonc-parser replace json5.
- Add `data/schema.json` for coc-settings.json.

## 2018-07-12

- Fix restart of tsserver not working.
- Fix edit of current buffer change jumplist by using `:keepjumps`.
