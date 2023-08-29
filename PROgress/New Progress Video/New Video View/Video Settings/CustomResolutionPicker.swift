//
//  ResolutionPicker.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 28..
//

import SwiftUI

struct CustomResolutionPicker: View {
    @Binding var resolution: Int
    
    static let range: ClosedRange<Int> = 240...4096
    
    var aspectRatio: Double = 1.0
    var customDimension: Axis = .horizontal
    
    private var xRange: ClosedRange<Int>
    private var yRange: ClosedRange<Int>
    
    init(resolution: Binding<Int>, aspectRatio: Double = 1.0, customDimension: Axis = .horizontal) {
        self._resolution = resolution
        self.aspectRatio = aspectRatio
        self.customDimension = customDimension
        
        if aspectRatio >= 1.0 {
            xRange = Self.range
            yRange = Int(Double(Self.range.lowerBound) / aspectRatio)...Int(Double(Self.range.upperBound) / aspectRatio)
        } else {
            yRange = Self.range
            xRange = Int(Double(Self.range.lowerBound) * aspectRatio)...Int(Double(Self.range.upperBound) * aspectRatio)
        }
        
        print(xRange)
        print(yRange)
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 4 / scale)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2.5 / scale))
                    .foregroundColor(.accentColor)
                    .overlay(alignment: .bottom) {
                        Text("\(width)")
                            .alignmentGuide(.bottom, computeValue: { d in d[.top] - 4 / scale })
                            .font(.system(size: 12 / scale))
                            .fontWeight(customDimension == .horizontal ? .bold : .regular)
                            .foregroundColor(customDimension == .horizontal ? .primary : .secondary)
                    }
                    .overlay(alignment: .trailing) {
                        Text("\(height)")
                            .alignmentGuide(.trailing, computeValue: { d in d[.leading] - 6 / scale })
                            .font(.system(size: 12 / scale))
                            .fontWeight(customDimension == .vertical ? .bold : .regular)
                            .foregroundColor(customDimension == .vertical ? .primary : .secondary)
                    }
                    .padding([.bottom], 16)
                    .padding(.trailing, 40)
                    .scaleEffect(CGSize(width: scale, height: scale), anchor: .topLeading)
                    .contentShape(Rectangle())
            }
            .gesture(DragGesture()
                .onChanged { value in
                    print(value.location)
                    
                    var scale: Double
                    if customDimension == .horizontal {
                        scale = max(value.location.x, proxy.size.width * Double(customizedRange.lowerBound) / Double(customizedRange.upperBound)) / proxy.size.width
                    } else {
                        scale = max(value.location.y, proxy.size.height * Double(customizedRange.lowerBound) / Double(customizedRange.upperBound)) / proxy.size.height
                    }
                    
                    let _resolution = Int(Double(customizedRange.upperBound - customizedRange.lowerBound) * scale)
                    print(scale)
                    
                    resolution = max(min(_resolution, customizedRange.upperBound), customizedRange.lowerBound)
                }
            )
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .padding([.bottom, .trailing], 16)
    }
    
    private var width: Int {
        if customDimension == .horizontal {
            return boundResolution
        } else {
            return Int(Double(boundResolution) * aspectRatio)
        }
    }
    
    private var height: Int {
        if customDimension == .vertical {
            return boundResolution
        } else {
            return Int(Double(boundResolution) / aspectRatio)
        }
    }
    
    private var boundResolution: Int {
        return min(max(resolution, customizedRange.lowerBound), customizedRange.upperBound)
    }
    
    private var customizedRange: ClosedRange<Int> {
        self.customDimension == .horizontal ? xRange : yRange
    }
    
    private var scale: Double {
        let ratio = Double(boundResolution - customizedRange.lowerBound) / Double(customizedRange.upperBound - customizedRange.lowerBound)
        return 0.85 * ratio + 0.2
    }
}

struct CustomResolutionPicker_Previews: PreviewProvider {
    static var previews: some View {
        ResolutionPickerPreview()
            .padding()
    }
    
    @MainActor
    struct ResolutionPickerPreview: View {
        @State private var resolution = 60
        
        var body: some View {
            CustomResolutionPicker(resolution: $resolution, aspectRatio: 16 / 9)
        }
    }
}
