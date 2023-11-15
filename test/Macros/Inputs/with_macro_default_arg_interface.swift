@freestanding(expression)
public macro FileID<T: ExpressibleByStringLiteral>() -> T = #externalMacro(
    module: "MacroDefinition", type: "NativeFileIDMacro"
)

@freestanding(expression)
public macro PrependHello(_ param: String) -> String = #externalMacro(
    module: "MacroDefinition", type: "PrependHelloMacro"
)

@freestanding(expression)
public macro AsIs<T>(_ param: T) -> T = #externalMacro(
    module: "MacroDefinition", type: "AsIsMacro"
)

@freestanding(expression)
public macro IntroduceShadowed<T>(_ param: T) -> T = #externalMacro(
    module: "MacroDefinition", type: "IntroduceShadowedMacro"
)

@freestanding(expression)
public macro MakeClosureCaller() -> ClosureCaller = #externalMacro(
    module: "MacroDefinition", type: "ClosureCallerMacro"
)

public func printCurrentFileDefinedInAnotherModuleInterface(
    file: String = #FileID
) {
    print(file)
}

public struct ClosureCaller {
    private let callback: @convention(thin) (Any, () -> Void) -> Void

    public init(_ callback: @convention(thin) (Any, () -> Void) -> Void) {
        self.callback = callback
    }

    public func callAsFunction(context: Any, then: () -> Void = {}) {
        callback(context, then)
    }
}

public let shadowed = "world"

public func testParameterUseVariableFromOriginalDeclContext(
    param: String = #PrependHello(shadowed)
) {
    print(param)
}

public func testMacroUseMacro(
    param: String = #PrependHello(#fileID)
) {
    print(param)
}

public func testUseShadowedFromOuterExpansion(
    param: String = #IntroduceShadowed(#PrependHello(shadowed))
) {
    print(param)
}

public func testNestedStillInOriginalDeclContext(
    param: String = #AsIs(#PrependHello(shadowed))
) {
    print(param)
}

@resultBuilder
public enum ClosureCallerBuilder {
    public static func buildBlock(
        closureCaller: ClosureCaller = #MakeClosureCaller
    ) -> ClosureCaller {
        closureCaller
    }
}
