import _Concurrency
import _StringProcessing
import _SwiftConcurrencyShims
import AppKit
import class AppKit.NSColor
import CoreGraphics
import SwiftOnoneSupport
import SwiftUI

/// Describes a type that represents color components with an alpha channel.
public protocol AlphaColorComponents<Value>: ColorComponents.ColorComponents {
    /// The alpha component.
    var alpha: Self.Value { get }
}

public extension AlphaColorComponents {
    /// Returns whether these color components represent a clear color (`alpha` is zero).
    @inlinable var isClearColor: Bool { get }
}

/// Describes a type that represents color components whose value is a floating point type.
/// - SeeAlso: ``AlphaColorComponents`` and ``FloatingPointColorComponents``
public typealias AlphaFloatingPointColorComponents<Value> = ColorComponents.AlphaColorComponents<Value> & ColorComponents.FloatingPointColorComponents<Value>

/// An opaque black/white color components representation.
@frozen public struct BW<Value>: ColorComponents.ColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The white component.
    public var white: Value

    /// Creates new black/white components with the given value.
    /// - Parameter white: The white component.
    public init(white: Value)
}

public extension BW where Value: BinaryInteger {
    /// Creates new black/white components from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new black/white components that exactly match the values
    /// from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components.
    /// - SeeAlso: ``BinaryInteger/init(exactly:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new black/white components from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new black/white components that exactly match the values
    /// from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(exactly:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension BW where Value: BinaryFloatingPoint {
    /// Creates new black/white components from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new black/white components that exactly match the values
    /// from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(exactly:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new black/white components from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new black/white components that exactly match the values
    /// from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(exactly:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BW<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension BW: ColorComponents.FloatingPointColorComponents where Value: FloatingPoint {
    /// The brightness of these color components. Corresponds to the white value.
    @inlinable public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension BW: Sendable where Value: Sendable {}

extension BW: Encodable where Value: Encodable {}

extension BW: Decodable where Value: Decodable {}

extension BW: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension BW where Value: BinaryFloatingPoint {
    /// Creates new black/white components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new black/white components that exactly
    /// match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    /// - SeeAlso: ``BW/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension BW where Value: BinaryInteger {
    /// Creates new black/white components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new black/white components that exactly
    /// match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    /// - SeeAlso: ``BW/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension BW where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new black/white components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new black/white components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    /// - SeeAlso: ``BW/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension BW where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new black/white components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new black/white components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    /// - SeeAlso: ``BW/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension BW: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension BW where Value: BinaryFloatingPoint {
    /// Creates new black/white components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new black/white components that exactly
    /// match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``BW/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension BW where Value: BinaryInteger {
    /// Creates new black/white components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new black/white components that exactly
    /// match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``BW/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

/// A black/white color components representation with an alpha channel.
@frozen public struct BWA<Value>: ColorComponents.AlphaColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The black/white components.
    public var bw: ColorComponents.BW<Value>

    /// The alpha component.
    public var alpha: Value

    /// The white component.
    /// - SeeAlso: ``BW/white`
    @inlinable public var white: Value

    /// Creates new black/white components with an alpha channel with the given values.
    /// - Parameters:
    ///   - bw: The black/white components.
    ///   - alpha: The alpha component.
    public init(bw: ColorComponents.BW<Value>, alpha: Value)

    /// Creates new black/white components with an alpha channel with the given values.
    /// - Parameters:
    ///   - white: The white component.
    ///   - alpha: The alpha component.
    @inlinable public init(white: Value, alpha: Value)
}

public extension BWA where Value: BinaryInteger {
    /// Creates new black/white components with alpha channel from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components with alpha channel.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new black/white components with alpha channel that exactly match the values
    /// from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components with alpha channel.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new black/white components with alpha channel from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components with alpha channle.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new black/white components with alpha channel that exactly match the values
    /// from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components with alpha channel.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension BWA where Value: BinaryFloatingPoint {
    /// Creates new black/white components with alpha channel from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components with alpha channel.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new black/white components with alpha channel that exactly match the values
    /// from another b/w color components object with integer values.
    /// - Parameter other: The other black/white color components with alpha channel.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new black/white components with alpha channel from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components with alpha channel.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new black/white components with alpha channel that exactly match the values
    /// from another b/w color components object with floating point values.
    /// - Parameter other: The other black/white color components with alpha channel.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.BWA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension BWA: ColorComponents.FloatingPointColorComponents where Value: FloatingPoint {
    /// The brightness of these color components. Corresponds to the white value.
    @inlinable public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension BWA: Sendable where Value: Sendable {}

extension BWA: Encodable where Value: Encodable {}

extension BWA: Decodable where Value: Decodable {}

extension BWA: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension BWA where Value: BinaryFloatingPoint {
    /// Creates new black/white components with alpha channel from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new black/white components with alpha channel
    /// that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    /// - SeeAlso: ``BWA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension BWA where Value: BinaryInteger {
    /// Creates new black/white components with alpha channel from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new black/white components with alpha channel
    /// that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultGray``
    ///         if it is not in a known gray color space.
    /// - SeeAlso: ``BWA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension BWA where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new black/white components with alpha channel from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new black/white components with alpha channel that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    /// - SeeAlso: ``BWA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension BWA where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new black/white components with alpha channel from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new black/white components with alpha channel that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericGray` color space if necessary.
    /// - SeeAlso: ``BWA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension BWA: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension BWA where Value: BinaryFloatingPoint {
    /// Creates new black/white components with alpha channel from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new black/white components with alpha channel
    /// that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``BWA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension BWA where Value: BinaryInteger {
    /// Creates new black/white components with alpha channel from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new black/white components with alpha channel
    /// that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``BWA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

/// Namespace for all CIE components.
@frozen public enum CIE: Sendable {}

public extension CIE {
    /// An opaque XYZ color components representation.
    @frozen struct XYZ<Value>: ColorComponents.ColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
        /// The x component.
        public var x: Value

        /// The y component.
        public var y: Value

        /// The z component.
        public var z: Value

        /// Creates new XYZ components with the given values.
        /// - Parameters:
        ///   - x: The x component.
        ///   - y: The y component.
        ///   - z: The z component.
        public init(x: Value, y: Value, z: Value)
    }

    /// An XYZA (x, y, z, alpha) color components representation.
    @frozen struct XYZA<Value>: ColorComponents.AlphaColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
        /// The XYZ components.
        public var xyz: ColorComponents.CIE.XYZ<Value>

        /// The alpha component.
        public var alpha: Value

        /// The x component.
        /// - SeeAlso: ``XYZ/x``
        @inlinable public var x: Value

        /// The y component.
        /// - SeeAlso: ``XYZ/y``
        @inlinable public var y: Value

        /// The y component.
        /// - SeeAlso: ``XYZ/y``
        @inlinable public var z: Value

        /// Creates new XYZA components using the given values.
        /// - Parameters:
        ///   - xyz: The XYZ components.
        ///   - alpha: The alpha component.
        public init(xyz: ColorComponents.CIE.XYZ<Value>, alpha: Value)

        /// Creates new XYZA components using the given values.
        /// - Parameters:
        ///   - x: The x component.
        ///   - y: The y component.
        ///   - z: The z component.
        ///   - alpha: The alpha component.
        @inlinable public init(x: Value, y: Value, z: Value, alpha: Value)
    }
}

public extension CIE.XYZ where Value: BinaryFloatingPoint {
    /// Creates new XYZ components using the given RGB components.
    /// - Parameter rgb: The RGB components to convert to XYZ.
    init(rgb: ColorComponents.RGB<Value>)
}

public extension CIE.XYZ where Value: BinaryInteger {
    /// Creates new HSB components using the given RGB components.
    /// - Parameter rgb: The RGB components to convert to CIE.XYZ.
    init(rgb: ColorComponents.RGB<Value>)
}

public extension CIE.XYZ where Value: BinaryInteger {
    /// Creates new XYZ components from another XYZ color components object with integer values.
    /// - Parameter other: The other XYZ color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new XYZ components that exactly match the values
    /// from another XYZ color components object with integer values.
    /// - Parameter other: The other XYZ color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new XYZ components from another XYZ color components object with floating point values.
    /// - Parameter other: The other XYZ color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new XYZ components that exactly match the values
    /// from another XYZ color components object with floating point values.
    /// - Parameter other: The other XYZ color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension CIE.XYZ where Value: BinaryFloatingPoint {
    /// Creates new XYZ components from another XYZ color components object with integer values.
    /// - Parameter other: The other XYZ color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new XYZ components that exactly match the values
    /// from another XYZ color components object with integer values.
    /// - Parameter other: The other XYZ color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new XYZ components from another XYZ color components object with floating point values.
    /// - Parameter other: The other XYZ color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new XYZ components that exactly match the values
    /// from another XYZ color components object with floating point values.
    /// - Parameter other: The other XYZ color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZ<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension CIE.XYZ: ColorComponents.FloatingPointColorComponents where Value: ExpressibleByFloatLiteral, Value: FloatingPoint {
    /// The brightness of these color components. The x, y and z components are weighted in this.
    public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    public mutating func changeBrightness(by percent: Value)
}

extension CIE.XYZ: Sendable where Value: Sendable {}

extension CIE.XYZ: Encodable where Value: Encodable {}

extension CIE.XYZ: Decodable where Value: Decodable {}

extension CIE.XYZ: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension CIE.XYZ where Value: BinaryFloatingPoint {
    /// Creates new CIE.XYZ components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZ color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new CIE.XYZ components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZ color space.
    /// - SeeAlso: ``CIE/XYZ/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension CIE.XYZ where Value: BinaryInteger {
    /// Creates new CIE.XYZ components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZ color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new CIE.XYZ components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZ color space.
    /// - SeeAlso: ``RGB/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension CIE.XYZ where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new CIE.XYZ components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new CIE.XYZ components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    /// - SeeAlso: ``CIE/XYZ/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension CIE.XYZ where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new CIE.XYZ components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new CIE.XYZ components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    /// - SeeAlso: ``CIE/XYZ/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension CIE.XYZ: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension CIE.XYZ where Value: BinaryFloatingPoint {
    /// Creates new CIE.XYZ components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new CIE.XYZ components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``CIE/XYZ/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension CIE.XYZ where Value: BinaryInteger {
    /// Creates new CIE.XYZ components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new CIE.XYZ components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``CIE/XYZ/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

public extension CIE.XYZA where Value: BinaryFloatingPoint {
    /// Creates new XYZA components using the given RGBA components.
    /// - Parameter rgba: The XYZA components to convert to XYZA.
    /// - SeeAlso: ``CIE.XYZ.init(rgb:)``
    @inlinable init(rgba: ColorComponents.RGBA<Value>)
}

public extension CIE.XYZA where Value: BinaryInteger {
    /// Creates new CIE.XYZ components using the given RGBA components.
    /// - Parameter rgba: The RGBA components to convert to CIE.XYZ.
    /// - SeeAlso: ``CIE.XYZ.init(rgb:)``
    @inlinable init(rgba: ColorComponents.RGBA<Value>)
}

public extension CIE.XYZA where Value: BinaryInteger {
    /// Creates new XYZA components from another XYZA color components object with integer values.
    /// - Parameter other: The other XYZA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new XYZA components that exactly match the values
    /// from another XYZA color components object with integer values.
    /// - Parameter other: The other XYZA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new XYZA components from another XYZA color components object with floating point values.
    /// - Parameter other: The other XYZA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new XYZA components that exactly match the values
    /// from another XYZA color components object with floating point values.
    /// - Parameter other: The other XYZA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension CIE.XYZA where Value: BinaryFloatingPoint {
    /// Creates new XYZA components from another XYZA color components object with integer values.
    /// - Parameter other: The other XYZA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new XYZA components that exactly match the values
    /// from another XYZA color components object with integer values.
    /// - Parameter other: The other XYZA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new XYZA components from another XYZA color components object with floating point values.
    /// - Parameter other: The other XYZA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new XYZA components that exactly match the values
    /// from another XYZA color components object with floating point values.
    /// - Parameter other: The other XYZA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.CIE.XYZA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension CIE.XYZA: ColorComponents.FloatingPointColorComponents where Value: ExpressibleByFloatLiteral, Value: FloatingPoint {
    /// The brightness of these color components. The x, y and z components are weighted in this.
    @inlinable public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension CIE.XYZA: Sendable where Value: Sendable {}

extension CIE.XYZA: Encodable where Value: Encodable {}

extension CIE.XYZA: Decodable where Value: Decodable {}

extension CIE.XYZA: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension CIE.XYZA where Value: BinaryFloatingPoint {
    /// Creates new CIE.XYZA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZA color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new CIE.XYZA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZ color space.
    /// - SeeAlso: ``CIE/XYZA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension CIE.XYZA where Value: BinaryInteger {
    /// Creates new CIE.XYZA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZ color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new CIE.XYZA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultCIEXYZ``
    ///         if it is not in a known CIE.XYZ color space.
    /// - SeeAlso: ``CIE/XYZA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension CIE.XYZA where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new CIE.XYZA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new CIE.XYZA components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    /// - SeeAlso: ``RGBA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension CIE.XYZA where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new CIE.XYZA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new CIE.XYZA components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericXYZ` color space if necessary.
    /// - SeeAlso: ``CIE/XYZA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension CIE.XYZA: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension CIE.XYZA where Value: BinaryFloatingPoint {
    /// Creates new CIE.XYZA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new CIE.XYZA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``CIE/XYZA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension CIE.XYZA where Value: BinaryInteger {
    /// Creates new CIE.XYZA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new CIE.XYZA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``CIE/XYZA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

/// Describes a type that represents (opaque) color components without an alpha channel.
public protocol ColorComponents<Value>: Hashable {
    /// The value type of these color components.
    associatedtype Value: Comparable, Hashable, Numeric
}

public extension ColorComponents where Self: CustomPlaygroundDisplayConvertible, Self.Value: BinaryFloatingPoint {
    var playgroundDescription: Any { get }
}

public extension ColorComponents where Self: CustomPlaygroundDisplayConvertible, Self.Value: BinaryInteger {
    var playgroundDescription: Any { get }
}

public extension ColorComponents where Self: CustomPlaygroundDisplayConvertible {
    var playgroundDescription: Any { get }
}

/// The type of values that can be used with color components.
public typealias ColorCompontentValue = Comparable & Hashable & Numeric

/// Describes a type that represents (opaque) color components whose value is a floating point type.
/// - SeeAlso: ``ColorComponents``
public protocol FloatingPointColorComponents<Value>: ColorComponents.ColorComponents where Self.Value: FloatingPoint {
    /// The brightness of these color components.
    var brightness: Self.Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    mutating func changeBrightness(by percent: Self.Value)
}

public extension FloatingPointColorComponents where Self.Value: ExpressibleByFloatLiteral {
    /// Returns whether these color components represent a dark color (``FloatingPointColorComponents/brightness`` less than 0.5).
    @inlinable var isDarkColor: Bool { get }

    /// Returns whether these color components represent a light color (``FloatingPointColorComponents/brightness`` greater than or equal to 0.5).
    @inlinable var isBrightColor: Bool { get }
}

/// An opaque HSB (hue, saturation, brightness) color components representation.
@frozen public struct HSB<Value>: ColorComponents.ColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The hue component.
    public var hue: Value

    /// The saturation component.
    public var saturation: Value

    /// The brightness component.
    public var brightness: Value

    /// Creates new HSB components with the given values.
    /// - Parameters:
    ///   - hue: The hue component.
    ///   - saturation: The saturation component.
    ///   - brightness: The brightness component.
    public init(hue: Value, saturation: Value, brightness: Value)
}

public extension HSB where Value: BinaryFloatingPoint {
    /// Creates new HSB components using the given HSL components.
    /// - Parameter hsl: The HSL components to convert to HSB.
    init(hsl: ColorComponents.HSL<Value>)
}

public extension HSB where Value: BinaryInteger {
    /// Creates new HSB components using the given HSL components.
    /// - Parameter hsl: The HSL components to convert to HSB.
    init(hsl: ColorComponents.HSL<Value>)
}

public extension HSB where Value: BinaryFloatingPoint {
    /// Creates new HSB components using the given RGB components.
    /// - Parameter rgb: The RGB components to convert to HSB.
    init(rgb: ColorComponents.RGB<Value>)
}

public extension HSB where Value: BinaryInteger {
    /// Creates new HSB components using the given RGB components.
    /// - Parameter rgb: The RGB components to convert to HSB.
    init(rgb: ColorComponents.RGB<Value>)
}

public extension HSB where Value: BinaryInteger {
    /// Creates new HSB components from another HSB color components object with integer values.
    /// - Parameter other: The other HSB color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSB components that exactly match the values
    /// from another HSB color components object with integer values.
    /// - Parameter other: The other HSB color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSB components from another HSB color components object with floating point values.
    /// - Parameter other: The other HSB color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSB components that exactly match the values
    /// from another HSB color components object with floating point values.
    /// - Parameter other: The other HSB color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension HSB where Value: BinaryFloatingPoint {
    /// Creates new HSB components from another HSB color components object with integer values.
    /// - Parameter other: The other HSB color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSB components that exactly match the values
    /// from another HSB color components object with integer values.
    /// - Parameter other: The other HSB color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSB components from another HSB color components object with floating point values.
    /// - Parameter other: The other HSB color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSB components that exactly match the values
    /// from another HSB color components object with floating point values.
    /// - Parameter other: The other HSB color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSB<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension HSB: ColorComponents.FloatingPointColorComponents where Value: FloatingPoint {
    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension HSB: Sendable where Value: Sendable {}

extension HSB: Encodable where Value: Encodable {}

extension HSB: Decodable where Value: Decodable {}

extension HSB: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSB where Value: BinaryFloatingPoint {
    /// Creates new HSB components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSB components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    /// - SeeAlso: ``HSB/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSB where Value: BinaryInteger {
    /// Creates new HSB components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSB components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    /// - SeeAlso: ``HSB/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension HSB where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSB components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSB components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSB/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension HSB where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSB components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSB components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSB/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension HSB: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSB where Value: BinaryFloatingPoint {
    /// Creates new HSB components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSB components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSB/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSB where Value: BinaryInteger {
    /// Creates new HSB components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSB components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSB/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

/// An HSBA (hue, saturation, brightness, alpha) color components representation.
@frozen public struct HSBA<Value>: ColorComponents.AlphaColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The HSB components.
    public var hsb: ColorComponents.HSB<Value>

    /// The alpha component.
    public var alpha: Value

    /// The hue component.
    /// - SeeAlso: ``HSB/hue``
    @inlinable public var hue: Value

    /// The saturation component.
    /// - SeeAlso: ``HSB/saturation``
    @inlinable public var saturation: Value

    /// The brightness component.
    /// - SeeAlso: ``HSB/brightness``
    @inlinable public var brightness: Value

    /// Creates new HSBA components using the given values.
    /// - Parameters:
    ///   - hsb: The HSB components.
    ///   - alpha: The alpha component.
    public init(hsb: ColorComponents.HSB<Value>, alpha: Value)

    /// Creates new HSBA components using the given values.
    /// - Parameters:
    ///   - hue: The hue component.
    ///   - saturation: The saturation component.
    ///   - brightness: The brightness component.
    ///   - alpha: The alpha component.
    @inlinable public init(hue: Value, saturation: Value, brightness: Value, alpha: Value)
}

public extension HSBA where Value: BinaryFloatingPoint {
    /// Creates new HSBA components using the given HSLA components.
    /// - Parameter hsla: The HSLA components to convert to HSBA.
    /// - SeeAlso: ``HSB/init(hsl:)``
    @inlinable init(hsla: ColorComponents.HSLA<Value>)
}

public extension HSBA where Value: BinaryInteger {
    /// Creates new HSBA components using the given HSLA components.
    /// - Parameter hsla: The HSLA components to convert to HSBA.
    /// - SeeAlso: ``HSB/init(hsl:)``
    @inlinable init(hsla: ColorComponents.HSLA<Value>)
}

public extension HSBA where Value: BinaryFloatingPoint {
    /// Creates new HSBA components using the given RGBA components.
    /// - Parameter rgba: The RGBA components to convert to HSBA.
    /// - SeeAlso: ``HSB/init(rgb:)``
    @inlinable init(rgba: ColorComponents.RGBA<Value>)
}

public extension HSBA where Value: BinaryInteger {
    /// Creates new HSBA components using the given RGBA components.
    /// - Parameter rgba: The RGBA components to convert to HSBA.
    /// - SeeAlso: ``HSB/init(rgb:)``
    @inlinable init(rgba: ColorComponents.RGBA<Value>)
}

public extension HSBA where Value: BinaryInteger {
    /// Creates new HSBA components from another HSBA color components object with integer values.
    /// - Parameter other: The other HSBA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSBA components that exactly match the values
    /// from another HSBA color components object with integer values.
    /// - Parameter other: The other HSBA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSBA components from another HSBA color components object with floating point values.
    /// - Parameter other: The other HSBA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSBA components that exactly match the values
    /// from another HSBA color components object with floating point values.
    /// - Parameter other: The other HSBA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension HSBA where Value: BinaryFloatingPoint {
    /// Creates new HSBA components from another HSBA color components object with integer values.
    /// - Parameter other: The other HSBA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSBA components that exactly match the values
    /// from another HSBA color components object with integer values.
    /// - Parameter other: The other HSBA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSBA components from another HSBA color components object with floating point values.
    /// - Parameter other: The other HSBA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSBA components that exactly match the values
    /// from another HSBA color components object with floating point values.
    /// - Parameter other: The other HSBA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSBA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension HSBA: ColorComponents.FloatingPointColorComponents where Value: FloatingPoint {
    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension HSBA: Sendable where Value: Sendable {}

extension HSBA: Encodable where Value: Encodable {}

extension HSBA: Decodable where Value: Decodable {}

extension HSBA: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSBA where Value: BinaryFloatingPoint {
    /// Creates new HSBA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSBA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    /// - SeeAlso: ``HSBA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSBA where Value: BinaryInteger {
    /// Creates new HSBA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSBA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSB``
    ///         if it is not in a known HSB color space (which is the same as for RGB).
    /// - SeeAlso: ``HSBA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension HSBA where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSBA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSB components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSBA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension HSBA where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSBA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSB components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSBA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension HSBA: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSBA where Value: BinaryFloatingPoint {
    /// Creates new HSBA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSBA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSBA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSBA where Value: BinaryInteger {
    /// Creates new HSBA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSBA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSBA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

/// An opaque HSL (hue, saturation, luminance) color components representation.
@frozen public struct HSL<Value>: ColorComponents.ColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The hue component.
    public var hue: Value

    /// The saturation component.
    public var saturation: Value

    /// The luminance component.
    public var luminance: Value

    /// Creates new HSL components with the given values.
    /// - Parameters:
    ///   - hue: The hue component.
    ///   - saturation: The saturation component.
    ///   - luminance: The luminance component.
    public init(hue: Value, saturation: Value, luminance: Value)
}

public extension HSL where Value: BinaryFloatingPoint {
    /// Creates new HSL components using the given HSB components.
    /// - Parameter hsb: The HSB components to convert to HSL.
    init(hsb: ColorComponents.HSB<Value>)
}

public extension HSL where Value: BinaryInteger {
    /// Creates new HSL components using the given HSB components.
    /// - Parameter hsb: The HSB components to convert to HSL.
    init(hsb: ColorComponents.HSB<Value>)
}

public extension HSL where Value: BinaryFloatingPoint {
    /// Creates new HSL components using the given RGB components.
    /// - Parameter rgb: The RGB components to convert to HSL.
    init(rgb: ColorComponents.RGB<Value>)
}

public extension HSL where Value: BinaryInteger {
    /// Creates new HSL components using the given RGB components.
    /// - Parameter rgb: The RGB components to convert to HSL.
    init(rgb: ColorComponents.RGB<Value>)
}

public extension HSL where Value: BinaryInteger {
    /// Creates new HSL components from another HSL color components object with integer values.
    /// - Parameter other: The other HSL color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSL components that exactly match the values
    /// from another HSL color components object with integer values.
    /// - Parameter other: The other HSL color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSL components from another HSL color components object with floating point values.
    /// - Parameter other: The other HSL color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSL components that exactly match the values
    /// from another HSL color components object with floating point values.
    /// - Parameter other: The other HSL color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension HSL where Value: BinaryFloatingPoint {
    /// Creates new HSL components from another HSL color components object with integer values.
    /// - Parameter other: The other HSL color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSB components that exactly match the values
    /// from another HSB color components object with integer values.
    /// - Parameter other: The other HSB color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSL components from another HSL color components object with floating point values.
    /// - Parameter other: The other HSL color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSL components that exactly match the values
    /// from another HSL color components object with floating point values.
    /// - Parameter other: The other HSB color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSL<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension HSL: ColorComponents.FloatingPointColorComponents where Value: FloatingPoint {
    /// The brightness of these color components.
    public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension HSL: Sendable where Value: Sendable {}

extension HSL: Encodable where Value: Encodable {}

extension HSL: Decodable where Value: Decodable {}

extension HSL: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSL where Value: BinaryFloatingPoint {
    /// Creates new HSL components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSL components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    /// - SeeAlso: ``HSL/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSL where Value: BinaryInteger {
    /// Creates new HSL components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSL components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    /// - SeeAlso: ``HSB/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension HSL where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSL components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSL components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSL/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension HSL where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSL components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSL components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSL/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension HSL: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSL where Value: BinaryFloatingPoint {
    /// Creates new HSL components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSL components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSL/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSL where Value: BinaryInteger {
    /// Creates new HSL components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSL components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSL/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

/// An HSLA (hue, saturation, luminance, alpha) color components representation.
@frozen public struct HSLA<Value>: ColorComponents.AlphaColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The HSL components.
    public var hsl: ColorComponents.HSL<Value>

    /// The alpha component.
    public var alpha: Value

    /// The hue component.
    /// - SeeAlso: ``HSL/hue``
    @inlinable public var hue: Value

    /// The saturation component.
    /// - SeeAlso: ``HSL/saturation``
    @inlinable public var saturation: Value

    /// The luminance component.
    /// - SeeAlso: ``HSL/luminance``
    @inlinable public var luminance: Value

    /// Creates new HSLA components using the given values.
    /// - Parameters:
    ///   - hsb: The HSL components.
    ///   - alpha: The alpha component.
    public init(hsl: ColorComponents.HSL<Value>, alpha: Value)

    /// Creates new HSLA components using the given values.
    /// - Parameters:
    ///   - hue: The hue component.
    ///   - saturation: The saturation component.
    ///   - luminance: The luminance component.
    ///   - alpha: The alpha component.
    @inlinable public init(hue: Value, saturation: Value, luminance: Value, alpha: Value)
}

public extension HSLA where Value: BinaryFloatingPoint {
    /// Creates new HSLA components using the given HSBA components.
    /// - Parameter hsba: The HSBA components to convert to HSLA.
    /// - SeeAlso: ``HSL/init(hsb:)``
    @inlinable init(hsba: ColorComponents.HSBA<Value>)
}

public extension HSLA where Value: BinaryInteger {
    /// Creates new HSLA components using the given HSBA components.
    /// - Parameter hsba: The HSBA components to convert to HSLA.
    /// - SeeAlso: ``HSL/init(hsb:)``
    @inlinable init(hsba: ColorComponents.HSBA<Value>)
}

public extension HSLA where Value: BinaryFloatingPoint {
    /// Creates new HSLA components using the given RGBA components.
    /// - Parameter rgba: The RGBA components to convert to HSLA.
    /// - SeeAlso: ``HSL/init(rgb:)``
    @inlinable init(rgba: ColorComponents.RGBA<Value>)
}

public extension HSLA where Value: BinaryInteger {
    /// Creates new HSLA components using the given RGBA components.
    /// - Parameter rgba: The RGBA components to convert to HSLA.
    /// - SeeAlso: ``HSL/init(rgb:)``
    @inlinable init(rgba: ColorComponents.RGBA<Value>)
}

public extension HSLA where Value: BinaryInteger {
    /// Creates new HSLA components from another HSLA color components object with integer values.
    /// - Parameter other: The other HSLA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSLA components that exactly match the values
    /// from another HSLA color components object with integer values.
    /// - Parameter other: The other HSLA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSLA components from another HSLA color components object with floating point values.
    /// - Parameter other: The other HSLA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSLA components that exactly match the values
    /// from another HSLA color components object with floating point values.
    /// - Parameter other: The other HSLA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255) - including `hue`!
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension HSLA where Value: BinaryFloatingPoint {
    /// Creates new HSLA components from another HSLA color components object with integer values.
    /// - Parameter other: The other HSLA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new HSLA components that exactly match the values
    /// from another HSLA color components object with integer values.
    /// - Parameter other: The other HSLA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0) - including `hue`!
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new HSLA components from another HSLA color components object with floating point values.
    /// - Parameter other: The other HSLA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new HSLA components that exactly match the values
    /// from another HSLA color components object with floating point values.
    /// - Parameter other: The other HSLA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.HSLA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension HSLA: ColorComponents.FloatingPointColorComponents where Value: FloatingPoint {
    /// The brightness of these color components.
    @inlinable public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension HSLA: Sendable where Value: Sendable {}

extension HSLA: Encodable where Value: Encodable {}

extension HSLA: Decodable where Value: Decodable {}

extension HSLA: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSLA where Value: BinaryFloatingPoint {
    /// Creates new HSLA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSLA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    /// - SeeAlso: ``HSLA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension HSLA where Value: BinaryInteger {
    /// Creates new HSLA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new HSLA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultHSL``
    ///         if it is not in a known HSL color space (which is the same as for RGB).
    /// - SeeAlso: ``HSLA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension HSLA where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSLA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSL components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSLA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension HSLA where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new HSLA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new HSL components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``HSLA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension HSLA: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSLA where Value: BinaryFloatingPoint {
    /// Creates new HSLA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSLA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSLA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension HSLA where Value: BinaryInteger {
    /// Creates new HSLA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new HSLA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``HSLA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

/// HSV is just an alias for HSB.
public typealias HSV = ColorComponents.HSB

/// HSVA is just an alias for HSBA.
public typealias HSVA = ColorComponents.HSBA

/// An opaque RGB (red, green, blue) color components representation.
@frozen public struct RGB<Value>: ColorComponents.ColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The red component.
    public var red: Value

    /// The green component.
    public var green: Value

    /// The blue component.
    public var blue: Value

    /// Creates new RGB components with the given values.
    /// - Parameters:
    ///   - red: The red component.
    ///   - green: The green component.
    ///   - blue: The blue component.
    public init(red: Value, green: Value, blue: Value)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension RGB where Value: BinaryFloatingPoint {
    /// Creates new RGB components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new RGB components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    /// - SeeAlso: ``RGB/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension RGB where Value: BinaryInteger {
    /// Creates new RGB components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new RGB components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    /// - SeeAlso: ``RGB/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension RGB where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new RGB components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new RGB components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``RGB/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension RGB where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new RGB components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new RGB components that exactly
    /// match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``RGB/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension RGB: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension RGB where Value: BinaryFloatingPoint {
    /// Creates new RGB components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new RGB components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``RGB/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension RGB where Value: BinaryInteger {
    /// Creates new RGB components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new RGB components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``RGB/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

public extension RGB where Value: BinaryFloatingPoint {
    /// Creates new RGB components using the given CIE.XYZ components.
    /// - Parameter cieXYZ: The CIE.XYZ components to convert to RGB.
    init(cieXYZ: ColorComponents.CIE.XYZ<Value>)
}

public extension RGB where Value: BinaryInteger {
    /// Creates new RGB components using the given CIE.XYZ components.
    /// - Parameter hsb: The CIE.XYZ components to convert to RGB.
    init(cieXYZ: ColorComponents.CIE.XYZ<Value>)
}

public extension RGB where Value: BinaryFloatingPoint {
    /// Creates new RGB components using the given HSB components.
    /// - Parameter hsb: The HSB components to convert to RGB.
    init(hsb: ColorComponents.HSB<Value>)
}

public extension RGB where Value: BinaryInteger {
    /// Creates new RGB components using the given HSB components.
    /// - Parameter hsb: The HSB components to convert to RGB.
    init(hsb: ColorComponents.HSB<Value>)
}

public extension RGB where Value: BinaryFloatingPoint {
    /// Creates new RGB components using the given HSL components.
    /// - Parameter hsl: The HSL components to convert to RGB.
    init(hsl: ColorComponents.HSL<Value>)
}

public extension RGB where Value: BinaryInteger {
    /// Creates new RGB components using the given HSL components.
    /// - Parameter hsl: The HSL components to convert to RGB.
    init(hsl: ColorComponents.HSL<Value>)
}

public extension RGB where Value: BinaryInteger {
    /// Creates new RGB components by splitting the combined hex value into RGB components.
    /// E.g. `RGB<UInt64>(hex: 0x3D4A7C)` becomes `RGB<UInt64>(red: 0x3D, green: 0x4A, blue: 0x7C)`.
    /// - Parameter hex: The combined RGB hex value.
    init(hex: Value)

    /// Creates new RGB components by splitting the combined hex value into RGB components.
    /// E.g. `RGB<UInt8>(hex: 0x3D4A7C)` becomes `RGB<UInt8>(red: 0x3D, green: 0x4A, blue: 0x7C)`.
    /// This overload exists so that e.g. `RGB<UInt8>` can be created from `0xFFECDA` which would overflow `UInt8`.
    /// - Parameter hex: The combined RGB hex value.
    @inlinable init<Hex>(hex: Hex) where Hex: BinaryInteger

    /// Creates new RGB components by parsing a given hex string into RGB components.
    /// If the string has `0x` or `#` as prefix, it is automatically removed.
    /// Returns nil if the string is no valid hex string.
    /// E.g. `RGB<UInt8>(hexString: "0x3D4A7C")` becomes `RGB<UInt8>(red: 0x3D, green: 0x4A, blue: 0x7C)`.
    /// - Parameter hexString: The string containing hex RGB values.
    init?<S>(hexString: S) where S: StringProtocol

    /// Computes the combined hex value for this RGB components.
    /// E.g. for `RGB<UInt64>(red: 0x3D, green: 0x4A, blue: 0x7C)` this returns `0x3D4A7C`.
    /// - Returns: The combined hex value for this RGB type.
    /// - Note: If the `Value` of this RGB components is too small to hold the entire hex value, this method will trap.
    ///         Use `hexValue(as:)` to perform the convesion using a larger type.
    func hexValue() -> Value

    /// Computes the combined hex value for this RGB components using a given integer type.
    /// E.g. for `RGB<UInt8>(red: 0x3D, green: 0x4A, blue: 0x7C)` using `UInt64` as type, this returns `0x3D4A7C`.
    /// - Parameter : The type of integer to use.
    /// - Returns: The combined hex value for this RGB type.
    func hexValue<I>(as _: I.Type = I.self) -> I where I: BinaryInteger
}

public extension RGB where Value: BinaryFloatingPoint {
    /// Creates new RGB components by splitting the combined hex value into RGB components.
    /// E.g. `RGB<Float>(hex: 0x3D4A7C)` becomes `RGB<Float>(red: 0.24, green: 0.3, blue: 0.486)`.
    /// - Parameter hex: The combined RGB hex value.
    @inlinable init<Hex>(hex: Hex) where Hex: BinaryInteger

    /// Creates new RGB components by parsing a given hex string into RGB components.
    /// If the string has `0x` or `#` as prefix, it is automatically removed.
    /// Returns nil if the string is no valid hex string.
    /// E.g. `RGB<Float>(hexString: "0x3D4A7C")` becomes `RGB<Float>(red: 0.24, green: 0.3, blue: 0.486)`.
    /// - Parameter hexString: The string containing hex RGB values.
    @inlinable init?<S>(hexString: S) where S: StringProtocol

    /// Computes the combined hex value for this RGB components using a given integer type.
    /// E.g. for `RGB<Float>(red: 0.5, green: 0.25, blue: 0.75)` this returns `0x7F3FBF`.
    /// - Parameter : The type of integer to use.
    /// - Returns: The combined hex value for this RGB type.
    @inlinable func hexValue<I>(as _: I.Type = I.self) -> I where I: BinaryInteger
}

public extension RGB where Value: BinaryInteger {
    /// Returns an RGB hex string representing these components.
    /// - Parameters:
    ///   - prefix: A prefix to prepend to the hex string. Defaults to an empty string.
    ///   - postfix: A postfix to append to the hex string. Defaults to an empty string.
    ///   - uppercase: Whether or not letter should be uppercase. Defaults to `false`.
    /// - Returns: A hex string of these RGB components.
    @inlinable func hexString(prefix: String = "", postfix: String = "", uppercase: Bool = false) -> String
}

public extension RGB where Value: BinaryFloatingPoint {
    /// Returns an RGB hex string representing these components.
    /// - Parameters:
    ///   - prefix: A prefix to prepend to the hex string. Defaults to an empty string.
    ///   - postfix: A postfix to append to the hex string. Defaults to an empty string.
    ///   - uppercase: Whether or not letter should be uppercase. Defaults to `false`.
    /// - Returns: A hex string of these RGB components.
    @inlinable func hexString(prefix: String = "", postfix: String = "", uppercase: Bool = false) -> String
}

public extension RGB where Value: BinaryInteger {
    /// Creates new RGB components from another RGB color components object with integer values.
    /// - Parameter other: The other RGB color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new RGB components that exactly match the values
    /// from another RGB color components object with integer values.
    /// - Parameter other: The other RGB color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new RGB components from another RGB color components object with floating point values.
    /// - Parameter other: The other RGB color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new RGB components that exactly match the values
    /// from another RGB color components object with floating point values.
    /// - Parameter other: The other RGB color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension RGB where Value: BinaryFloatingPoint {
    /// Creates new RGB components from another RGB color components object with integer values.
    /// - Parameter other: The other RGB color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new RGB components that exactly match the values
    /// from another RGB color components object with integer values.
    /// - Parameter other: The other RGB color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new RGB components from another RGB color components object with floating point values.
    /// - Parameter other: The other RGB color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new RGB components that exactly match the values
    /// from another RGB color components object with floating point values.
    /// - Parameter other: The other RGB color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGB<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension RGB: ColorComponents.FloatingPointColorComponents where Value: ExpressibleByFloatLiteral, Value: FloatingPoint {
    /// The brightness of these color components. The red, green and blue components are weighted in this.
    public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    public mutating func changeBrightness(by percent: Value)
}

extension RGB: Sendable where Value: Sendable {}

extension RGB: Encodable where Value: Encodable {}

extension RGB: Decodable where Value: Decodable {}

extension RGB: CustomPlaygroundDisplayConvertible {}

/// An RGBA (red, green, blue, alpha) color components representation.
@frozen public struct RGBA<Value>: ColorComponents.AlphaColorComponents where Value: Comparable, Value: Hashable, Value: Numeric {
    /// The RGB components.
    public var rgb: ColorComponents.RGB<Value>

    /// The alpha component.
    public var alpha: Value

    /// The red component.
    /// - SeeAlso: ``RGB/red``
    @inlinable public var red: Value

    /// The green component.
    /// - SeeAlso: ``RGB/green``
    @inlinable public var green: Value

    /// The green component.
    /// - SeeAlso: ``RGB/green``
    @inlinable public var blue: Value

    /// Creates new RGBA components using the given values.
    /// - Parameters:
    ///   - rgb: The RGB components.
    ///   - alpha: The alpha component.
    public init(rgb: ColorComponents.RGB<Value>, alpha: Value)

    /// Creates new RGBA components using the given values.
    /// - Parameters:
    ///   - red: The red component.
    ///   - green: The green component.
    ///   - blue: The blue component.
    ///   - alpha: The alpha component.
    @inlinable public init(red: Value, green: Value, blue: Value, alpha: Value)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension RGBA where Value: BinaryFloatingPoint {
    /// Creates new RGBA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new RGBA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    /// - SeeAlso: ``RGBA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension RGBA where Value: BinaryInteger {
    /// Creates new RGBA components from the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    @inlinable init(_ nsColor: NSColor)

    /// Tries to create new RGBA components that exactly match the components of the given color.
    /// - Parameter nsColor: The color to read the components from.
    /// - Note: This will convert the color to ``NSColorSpace/colorComponentsDefaultRGB``
    ///         if it is not in a known RGB color space.
    /// - SeeAlso: ``RGBA/init(exactly:)``
    @inlinable init?(exactly nsColor: NSColor)
}

public extension RGBA where Value: BinaryFloatingPoint {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new RGBA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new RGB components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``RGBA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

public extension RGBA where Value: BinaryInteger {
    /// The `CGColor` that corresponds to these color components.
    @available(macOS 10.5, iOS 13, tvOS 13, watchOS 6, *)
    @inlinable var cgColor: CGColor { get }

    /// Creates new RGBA components from the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init(_ cgColor: CGColor)

    /// Tries to create new RGB components that exactly match the components of the given color.
    /// - Parameter cgColor: The color to read the components from.
    /// - Note: This will convert the color to the `kCGColorSpaceGenericRGB` color space if necessary.
    /// - SeeAlso: ``RGBA/init(exactly:)``
    @available(macOS 10.11, iOS 10, tvOS 10, watchOS 3, *)
    @inlinable init?(exactly cgColor: CGColor)
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension RGBA: View where Value: BinaryFloatingPoint {
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that SwiftUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    @MainActor @inlinable public var body: some View { get }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension RGBA where Value: BinaryFloatingPoint {
    /// Creates new RGBA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new RGBA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``RGBA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public extension RGBA where Value: BinaryInteger {
    /// Creates new RGBA components from the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    @inlinable init(_ color: Color)

    /// Tries to create new RGBA components that exactly match the components of the given color.
    /// - Parameter color: The color to read the components from.
    /// - Note: This currently goes through the platform native color (`NSColor` or `UIColor`)
    ///         due to the lack of component accessors on `SwiftUI.Color`.
    /// - SeeAlso: ``RGBA/init(exactly:)``
    @inlinable init?(exactly color: Color)
}

public extension RGBA where Value: BinaryFloatingPoint {
    /// Creates new RGBA components using the given CIE.XYZA components.
    /// - Parameter cieXYZA: The CIE.XYZA components to convert to RGBA.
    @inlinable init(cieXYZA: ColorComponents.CIE.XYZA<Value>)
}

public extension RGBA where Value: BinaryInteger {
    /// Creates new RGBA components using the given CIE.XYZA components.
    /// - Parameter cieXYZA: The CIE.XYZA components to convert to RGBA.
    @inlinable init(cieXYZA: ColorComponents.CIE.XYZA<Value>)
}

public extension RGBA where Value: BinaryFloatingPoint {
    /// Creates new RGBA components using the given HSBA components.
    /// - Parameter hsba: The HSBA components to convert to RGBA.
    @inlinable init(hsba: ColorComponents.HSBA<Value>)
}

public extension RGBA where Value: BinaryInteger {
    /// Creates new RGBA components using the given HSBA components.
    /// - Parameter hsba: The HSBA components to convert to RGBA.
    @inlinable init(hsba: ColorComponents.HSBA<Value>)
}

public extension RGBA where Value: BinaryFloatingPoint {
    /// Creates new RGBA components using the given HSLA components.
    /// - Parameter hsla: The HSLA components to convert to RGBA.
    /// - SeeAlso: ``RGB/init(hsl:)``
    @inlinable init(hsla: ColorComponents.HSLA<Value>)
}

public extension RGBA where Value: BinaryInteger {
    /// Creates new RGBA components using the given HSLA components.
    /// - Parameter hsla: The HSLA components to convert to RGBA.
    /// - SeeAlso: ``RGB/init(hsl:)``
    @inlinable init(hsla: ColorComponents.HSLA<Value>)
}

public extension RGBA where Value: BinaryInteger {
    /// Creates new RGBA components by splitting the combined hex value into RGBA components.
    /// E.g. `RGBA<UInt64>(hex: 0x3D4A7C1B)` becomes `RGBA<UInt64>(red: 0x3D, green: 0x4A, blue: 0x7C, alpha: 0x1B)`.
    /// - Parameter hex: The combined RGBA hex value.
    init(hex: Value)

    /// Creates new RGBA components by splitting the combined hex value into RGBA components.
    /// E.g. `RGBA<UInt8>(hex: 0x3D4A7C1B)` becomes `RGBA<UInt8>(red: 0x3D, green: 0x4A, blue: 0x7C, alpha: 0x1B)`.
    /// This overload exists so that e.g. `RGBA<UInt8>` can be created from `0xFFECDAFF` which would overflow `UInt8`.
    /// - Parameter hex: The combined RGBA hex value.
    @inlinable init<Hex>(hex: Hex) where Hex: BinaryInteger

    /// Creates new RGBA components by parsing a given hex string into RGBA components.
    /// If the string has `0x` or `#` as prefix, it is automatically removed.
    /// Returns nil if the string is no valid hex string.
    /// E.g. `RGB<UInt8>(hexString: "0x3D4A7CFF")` becomes `RGB<UInt8>(red: 0x3D, green: 0x4A, blue: 0x7C, alpha: 0xFF)`.
    /// - Parameter hexString: The string containing hex RGBA values.
    init?<S>(hexString: S) where S: StringProtocol

    /// Computes the combined hex value for this RGBA components.
    /// E.g. for `RGBA<UInt64>(red: 0x3D, green: 0x4A, blue: 0x7C, alpha: 0xFF)` this returns `0x3D4A7CFF`.
    /// - Returns: The combined hex value for this RGB type.
    /// - Note: If the `Value` of this RGBA components is too small to hold the entire hex value, this method will trap.
    ///         Use `hexValue(as:)` to perform the convesion using a larger type.
    func hexValue() -> Value

    /// Computes the combined hex value for this RGBA components using a given integer type.
    /// E.g. for `RGBA<UInt8>(red: 0x3D, green: 0x4A, blue: 0x7C, alpha: 0xFF)` using `UInt64` as type this returns `0x3D4A7CFF`.
    /// - Parameter : The type of integer to use.
    /// - Returns: The combined hex value for this RGB type.
    func hexValue<I>(as _: I.Type = I.self) -> I where I: BinaryInteger
}

public extension RGBA where Value: BinaryFloatingPoint {
    /// Creates new RGBA components by splitting the combined hex value into RGBA components.
    /// E.g. `RGBA<Float>(hex: 0x3D4A7CFF)` becomes `RGB<Float>(red: 0.24, green: 0.3, blue: 0.486, alpha: 1)`.
    /// - Parameter hex: The combined RGBA hex value.
    @inlinable init<Hex>(hex: Hex) where Hex: BinaryInteger

    /// Creates new RGBA components by parsing a given hex string into RGBA components.
    /// If the string has `0x` or `#` as prefix, it is automatically removed.
    /// Returns nil if the string is no valid hex string.
    /// E.g. `RGBA<Float>(hexString: "0x3D4A7CFF")` becomes `RGBA<Float>(red: 0.24, green: 0.3, blue: 0.486, alpha: 1)`.
    /// - Parameter hexString: The string containing hex RGBA values.
    @inlinable init?<S>(hexString: S) where S: StringProtocol

    /// Computes the combined hex value for this RGBA components using a given integer type.
    /// E.g. for `RGBA<Float>(red: 0.5, green: 0.25, blue: 0.75, alpha: 1)` this returns `0x7F3FBFFF`.
    /// - Parameter : The type of integer to use.
    /// - Returns: The combined hex value for this RGBA type.
    @inlinable func hexValue<I>(as _: I.Type = I.self) -> I where I: BinaryInteger
}

public extension RGBA where Value: BinaryInteger {
    /// Returns an RGBA hex string representing these components.
    /// - Parameters:
    ///   - prefix: A prefix to prepend to the hex string. Defaults to an empty string.
    ///   - postfix: A postfix to append to the hex string. Defaults to an empty string.
    ///   - uppercase: Whether or not letter should be uppercase. Defaults to `false`.
    /// - Returns: A hex string of these RGBA components.
    @inlinable func hexString(prefix: String = "", postfix: String = "", uppercase: Bool = false) -> String
}

public extension RGBA where Value: BinaryFloatingPoint {
    /// Returns an RGBA hex string representing these components.
    /// - Parameters:
    ///   - prefix: A prefix to prepend to the hex string. Defaults to an empty string.
    ///   - postfix: A postfix to append to the hex string. Defaults to an empty string.
    ///   - uppercase: Whether or not letter should be uppercase. Defaults to `false`.
    /// - Returns: A hex string of these RGBA components.
    @inlinable func hexString(prefix: String = "", postfix: String = "", uppercase: Bool = false) -> String
}

public extension RGBA where Value: BinaryInteger {
    /// Creates new RGBA components from another RGBA color components object with integer values.
    /// - Parameter other: The other RGBA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new RGBA components that exactly match the values
    /// from another RGBA color components object with integer values.
    /// - Parameter other: The other RGBA color components.
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new RGBA components from another RGBA color components object with floating point values.
    /// - Parameter other: The other RGBA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new RGBA components that exactly match the values
    /// from another RGBA color components object with floating point values.
    /// - Parameter other: The other RGBA color components.
    /// - Note: This will convert the floating point values (0.0 - 1.0) to integer values (0 - 255).
    /// - SeeAlso: ``BinaryInteger/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

public extension RGBA where Value: BinaryFloatingPoint {
    /// Creates new RGBA components from another RGBA color components object with integer values.
    /// - Parameter other: The other RGBA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryInteger

    /// Tries to create new RGBA components that exactly match the values
    /// from another RGBA color components object with integer values.
    /// - Parameter other: The other RGBA color components.
    /// - Note: This will convert the integer values (0 - 255) to floating point values (0.0 - 1.0).
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryInteger

    /// Creates new RGBA components from another RGBA color components object with floating point values.
    /// - Parameter other: The other RGBA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init<OtherValue>(_ other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryFloatingPoint

    /// Tries to create new RGBA components that exactly match the values
    /// from another RGBA color components object with floating point values.
    /// - Parameter other: The other RGBA color components.
    /// - SeeAlso: ``BinaryFloatingPoint/init(_:)``
    @inlinable init?<OtherValue>(exactly other: ColorComponents.RGBA<OtherValue>) where OtherValue: BinaryFloatingPoint
}

extension RGBA: ColorComponents.FloatingPointColorComponents where Value: ExpressibleByFloatLiteral, Value: FloatingPoint {
    /// The brightness of these color components. The red, green and blue components are weighted in this.
    @inlinable public var brightness: Value { get }

    /// Changes the brightness by the given percent value.
    /// Pass 0.1 to increase brightness by 10%.
    /// Pass -0.1 to decrease brightness by 10%.
    /// - Parameter percent: The percentage amount to change the brightness.
    @inlinable public mutating func changeBrightness(by percent: Value)
}

extension RGBA: Sendable where Value: Sendable {}

extension RGBA: Encodable where Value: Encodable {}

extension RGBA: Decodable where Value: Decodable {}

extension RGBA: CustomPlaygroundDisplayConvertible {}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColorSpace {
    /// The default color space used by ``BW`` and ``BWA`` to create `NSColor`s when no color space was specified.
    /// This is currently equivalent to `NSColorSpace.deviceGray`.
    static var colorComponentsDefaultGray: NSColorSpace { get }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColor {
    /// Creates a new color using the given black/white components and color space.
    /// - Parameters:
    ///   - bw: The black/white components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultGray``.
    @inlinable convenience init<Value>(_ bw: ColorComponents.BW<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultGray) where Value: BinaryFloatingPoint

    /// Creates a new color using the given black/white components with alpha channel and color space.
    /// - Parameters:
    ///   - bwa: The black/white components with alpha channel.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultGray``.
    @inlinable convenience init<Value>(_ bwa: ColorComponents.BWA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultGray) where Value: BinaryFloatingPoint

    /// Creates a new color using the given black/white components and color space.
    /// - Parameters:
    ///   - bw: The black/white components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultGray``.
    @inlinable convenience init<Value>(_ bw: ColorComponents.BW<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultGray) where Value: BinaryInteger

    /// Creates a new color using the given black/white components with alpha channel and color space.
    /// - Parameters:
    ///   - bwa: The black/white components with alpha channel.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultGray``.
    @inlinable convenience init<Value>(_ bwa: ColorComponents.BWA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultGray) where Value: BinaryInteger
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Color {
    /// Creates a new color using the given black/white components.
    /// - Parameter bw: The black/white components.
    @inlinable init<Value>(_ bw: ColorComponents.BW<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given black/white components with alpha channel.
    /// - Parameter bwa: The black/white components with alpha channel.
    @inlinable init<Value>(_ bwa: ColorComponents.BWA<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given black/white components.
    /// - Parameter bw: The black/white components.
    @inlinable init<Value>(_ bw: ColorComponents.BW<Value>) where Value: BinaryInteger

    /// Creates a new color using the given black/white components with alpha channel.
    /// - Parameter bwa: The black/white components with alpha channel.
    @inlinable init<Value>(_ bwa: ColorComponents.BWA<Value>) where Value: BinaryInteger
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColorSpace {
    /// The default color space used by ``CIE/XYZ`` and ``CIE/XYZA`` to create `NSColor`s when no color space was specified.
    /// This is currently equivalent to ``NSColorSpace/colorComponentsDefaultRGB``.
    static var colorComponentsDefaultCIEXYZ: NSColorSpace { get }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColor {
    /// Creates a new color using the given CIE.XYZ components and color space.
    /// - Parameters:
    ///   - cieXYZ: The CIE.XYZ components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultCIEXYZ``.
    @inlinable convenience init<Value>(_ cieXYZ: ColorComponents.CIE.XYZ<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultCIEXYZ) where Value: BinaryFloatingPoint

    /// Creates a new color using the given CIE.XYZA components and color space.
    /// - Parameters:
    ///   - cieXYZA: The CIE.XYZA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultCIEXYZ``.
    @inlinable convenience init<Value>(_ cieXYZA: ColorComponents.CIE.XYZA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultCIEXYZ) where Value: BinaryFloatingPoint

    /// Creates a new color using the given CIE.XYZ components and color space.
    /// - Parameters:
    ///   - cieXYZ: The CIE.XYZ components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultCIEXYZ``.
    @inlinable convenience init<Value>(_ cieXYZ: ColorComponents.CIE.XYZ<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultCIEXYZ) where Value: BinaryInteger

    /// Creates a new color using the given CIE.XYZA components and color space.
    /// - Parameters:
    ///   - cieXYZA: The CIE.XYZA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultCIEXYZ``.
    @inlinable convenience init<Value>(_ cieXYZA: ColorComponents.CIE.XYZA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultCIEXYZ) where Value: BinaryInteger
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Color {
    /// Creates a new color using the given CIE.XYZ components.
    /// - Parameter cieXYZ: The CIE.XYZ components.
    @inlinable init<Value>(_ cieXYZ: ColorComponents.CIE.XYZ<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given CIE.XYZA components.
    /// - Parameter cieXYZA: The CIE.XYZA components.
    @inlinable init<Value>(_ cieXYZA: ColorComponents.CIE.XYZA<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given CIE.XYZ components.
    /// - Parameter cieXYZ: The CIE.XYZ components.
    @inlinable init<Value>(_ cieXYZ: ColorComponents.CIE.XYZ<Value>) where Value: BinaryInteger

    /// Creates a new color using the given CIE.XYZA components.
    /// - Parameter cieXYZA: The CIE.XYZA components.
    @inlinable init<Value>(_ cieXYZA: ColorComponents.CIE.XYZA<Value>) where Value: BinaryInteger
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColorSpace {
    /// The default color space used by ``HSB`` and ``HSBA`` to create `NSColor`s when no color space was specified.
    /// This is currently equivalent to ``NSColorSpace/colorComponentsDefaultRGB``.
    static var colorComponentsDefaultHSB: NSColorSpace { get }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColor {
    /// Creates a new color using the given HSB components and color space.
    /// - Parameters:
    ///   - hsb: The HSB components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSB``.
    @inlinable convenience init<Value>(_ hsb: ColorComponents.HSB<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSB) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSBA components and color space.
    /// - Parameters:
    ///   - hsba: The HSBA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSB``.
    @inlinable convenience init<Value>(_ hsba: ColorComponents.HSBA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSB) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSB components and color space.
    /// - Parameters:
    ///   - hsb: The HSB components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSB``.
    @inlinable convenience init<Value>(_ hsb: ColorComponents.HSB<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSB) where Value: BinaryInteger

    /// Creates a new color using the given HSBA components and color space.
    /// - Parameters:
    ///   - hsba: The HSBA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSB``.
    @inlinable convenience init<Value>(_ hsba: ColorComponents.HSBA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSB) where Value: BinaryInteger
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Color {
    /// Creates a new color using the given HSB components.
    /// - Parameter hsb: The HSB components.
    @inlinable init<Value>(_ hsb: ColorComponents.HSB<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSBA components.
    /// - Parameter hsba: The HSBA components.
    @inlinable init<Value>(_ hsba: ColorComponents.HSBA<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSB components.
    /// - Parameter hsb: The HSB components.
    @inlinable init<Value>(_ hsb: ColorComponents.HSB<Value>) where Value: BinaryInteger

    /// Creates a new color using the given HSBA components.
    /// - Parameter hsba: The HSBA components.
    @inlinable init<Value>(_ hsba: ColorComponents.HSBA<Value>) where Value: BinaryInteger
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColorSpace {
    /// The default color space used by ``HSL`` and ``HSLA`` to create `NSColor`s when no color space was specified.
    /// This is currently equivalent to ``NSColorSpace/colorComponentsDefaultRGB``.
    static var colorComponentsDefaultHSL: NSColorSpace { get }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColor {
    /// Creates a new color using the given HSL components and color space.
    /// - Parameters:
    ///   - hsl: The HSL components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSL``.
    @inlinable convenience init<Value>(_ hsl: ColorComponents.HSL<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSL) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSLA components and color space.
    /// - Parameters:
    ///   - hsla: The HSLA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSL``.
    @inlinable convenience init<Value>(_ hsla: ColorComponents.HSLA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSL) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSL components and color space.
    /// - Parameters:
    ///   - hsb: The HSL components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSL``.
    @inlinable convenience init<Value>(_ hsl: ColorComponents.HSL<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSL) where Value: BinaryInteger

    /// Creates a new color using the given HSLA components and color space.
    /// - Parameters:
    ///   - hsla: The HSLA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultHSL``.
    @inlinable convenience init<Value>(_ hsla: ColorComponents.HSLA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultHSL) where Value: BinaryInteger
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Color {
    /// Creates a new color using the given HSL components.
    /// - Parameter hsl: The HSL components.
    @inlinable init<Value>(_ hsl: ColorComponents.HSL<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSLA components.
    /// - Parameter hsla: The HSLA components.
    @inlinable init<Value>(_ hsla: ColorComponents.HSLA<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given HSL components.
    /// - Parameter hsl: The HSL components.
    @inlinable init<Value>(_ hsl: ColorComponents.HSL<Value>) where Value: BinaryInteger

    /// Creates a new color using the given HSLA components.
    /// - Parameter hsla: The HSLA components.
    @inlinable init<Value>(_ hsla: ColorComponents.HSLA<Value>) where Value: BinaryInteger
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColorSpace {
    /// The default color space used by ``RGB`` and ``RGBA`` to create `NSColor`s when no color space was specified.
    /// This is currently equivalent to `NSColorSpace.deviceRGB`.
    static var colorComponentsDefaultRGB: NSColorSpace { get }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NSColor {
    /// Creates a new color using the given RGB components and color space.
    /// - Parameters:
    ///   - rgb: The RGB components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultRGB``.
    @inlinable convenience init<Value>(_ rgb: ColorComponents.RGB<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultRGB) where Value: BinaryFloatingPoint

    /// Creates a new color using the given RGBA components and color space.
    /// - Parameters:
    ///   - rgba: The RGBA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultRGB``.
    @inlinable convenience init<Value>(_ rgba: ColorComponents.RGBA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultRGB) where Value: BinaryFloatingPoint

    /// Creates a new color using the given RGB components and color space.
    /// - Parameters:
    ///   - rgb: The RGB components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultRGB``.
    @inlinable convenience init<Value>(_ rgb: ColorComponents.RGB<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultRGB) where Value: BinaryInteger

    /// Creates a new color using the given RGBA components and color space.
    /// - Parameters:
    ///   - rgba: The RGBA components.
    ///   - colorSpace: The color space to use. Defaults to ``NSColorSpace/colorComponentsDefaultRGB``.
    @inlinable convenience init<Value>(_ rgba: ColorComponents.RGBA<Value>, colorSpace: NSColorSpace = .colorComponentsDefaultRGB) where Value: BinaryInteger
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Color {
    /// Creates a new color using the given RGB components.
    /// - Parameter rgb: The RGB components.
    @inlinable init<Value>(_ rgb: ColorComponents.RGB<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given RGBA components.
    /// - Parameter rgba: The RGBA components.
    @inlinable init<Value>(_ rgba: ColorComponents.RGBA<Value>) where Value: BinaryFloatingPoint

    /// Creates a new color using the given RGB components.
    /// - Parameter rgb: The RGB components.
    @inlinable init<Value>(_ rgb: ColorComponents.RGB<Value>) where Value: BinaryInteger

    /// Creates a new color using the given RGBA components.
    /// - Parameter rgba: The RGBA components.
    @inlinable init<Value>(_ rgba: ColorComponents.RGBA<Value>) where Value: BinaryInteger
}
