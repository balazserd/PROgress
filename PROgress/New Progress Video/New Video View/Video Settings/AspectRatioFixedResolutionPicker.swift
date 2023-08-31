//
//  AspectRatioFixedResolutionPicker.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 28..
//

import SwiftUI

struct AspectRatioFixedResolutionPicker: View {
    @Binding var resolution: Double
    
    static let range: ClosedRange<Double> = 240...4096
    
    var aspectRatio: Double
    var customDimension: Axis
    
    private var xRange: ClosedRange<Double>
    private var yRange: ClosedRange<Double>
    
    @State private var dragGestureStartingBoundResolution: Double? = nil
    
    @State private var arrowAnimationOffsetX = 0.0
    @State private var arrowAnimationOffsetY = 0.0
    
    init(resolution: Binding<Double>, aspectRatio: Double = 1.0, customDimension: Axis = .horizontal) {
        self._resolution = resolution
        self.aspectRatio = aspectRatio
        self.customDimension = customDimension
        
        if aspectRatio >= 1.0 {
            xRange = Self.range
            yRange = (Self.range.lowerBound / aspectRatio)...(Self.range.upperBound / aspectRatio)
        } else {
            yRange = Self.range
            xRange = (Self.range.lowerBound * aspectRatio)...(Self.range.upperBound * aspectRatio)
        }
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
            .aspectRatio(aspectRatio, contentMode: .fit)
            
            Color.clear
                .contentShape(Rectangle())
                .gesture(DragGesture()
                    .onChanged { value in
                        if dragGestureStartingBoundResolution == nil {
                            dragGestureStartingBoundResolution = boundResolution
                        }
                        
                        var scale: Double
                        if customDimension == .horizontal {
                            let travel = value.translation.width
                            scale = travel / proxy.size.width
                        } else {
                            let travel = value.translation.height
                            scale = travel / proxy.size.height
                        }
                        
                        let proposedResolution = dragGestureStartingBoundResolution! + (customizedRange.upperBound - customizedRange.lowerBound) * scale
                        
                        resolution = max(min(proposedResolution, customizedRange.upperBound), customizedRange.lowerBound)
                    }
                    .onEnded { _ in
                        dragGestureStartingBoundResolution = nil
                    }
                )
        }
        .padding([.bottom, .trailing], 16)
        .overlay(alignment: customDimension == .horizontal ? .bottomLeading : .topTrailing) {
            helperOverlayImage
        }
    }
    
    @ViewBuilder @MainActor
    private var helperOverlayImage: some View {
        if customDimension == .horizontal {
            Image(systemName: "arrow.left.and.right")
                .scaleEffect(of: 2)
                .foregroundColor(.gray)
                .opacity(0.3)
                .offset(x: arrowAnimationOffsetX, y: 0)
                .offset(y: 10)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: arrowAnimationOffsetX)
                .task { @MainActor in
                    arrowAnimationOffsetX = 15
                    arrowAnimationOffsetY = 0
                }
        } else {
            Image(systemName: "arrow.up.and.down")
                .scaleEffect(of: 2)
                .foregroundColor(.gray)
                .opacity(0.3)
                .offset(x: 0, y: arrowAnimationOffsetY)
                .offset(x: -5, y: 5)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: arrowAnimationOffsetY)
                .task { @MainActor in
                    arrowAnimationOffsetX = 0
                    arrowAnimationOffsetY = 15
                }
        }
    }
    
    private var width: Int {
        if customDimension == .horizontal {
            return Int(boundResolution)
        } else {
            return Int(Double(boundResolution) * aspectRatio)
        }
    }
    
    private var height: Int {
        if customDimension == .vertical {
            return Int(boundResolution)
        } else {
            return Int(Double(boundResolution) / aspectRatio)
        }
    }
    
    private var boundResolution: Double {
        return min(max(resolution, customizedRange.lowerBound), customizedRange.upperBound)
    }
    
    private var customizedRange: ClosedRange<Double> {
        self.customDimension == .horizontal ? xRange : yRange
    }
    
    private var scale: Double {
        let ratio = Double(boundResolution - customizedRange.lowerBound) / Double(customizedRange.upperBound - customizedRange.lowerBound)
        return 0.85 * ratio + 0.2
    }
}

struct AspectRatioFixedResolutionPicker_Previews: PreviewProvider {
    static var previews: some View {
        ResolutionPickerPreview()
            .padding()
    }
    
    @MainActor
    struct ResolutionPickerPreview: View {
        @State private var resolution = 60.0
        @State private var aspectRatioToggle = true
        
        var body: some View {
            VStack {
                Toggle(isOn: $aspectRatioToggle, label: { Text("Dimension") })
                AspectRatioFixedResolutionPicker(resolution: $resolution, aspectRatio: 16 / 9, customDimension: aspectRatioToggle ? .horizontal : .vertical)
            }
        }
    }
}
