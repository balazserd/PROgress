//
//  FreeResolutionPicker.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 31..
//

import SwiftUI

struct FreeResolutionPicker: View {
    @Binding var resolutionX: Double
    @Binding var resolutionY: Double
    
    private var xRange: ClosedRange<Double> = 240...4096
    private var yRange: ClosedRange<Double> = 240...4096
    
    @State private var dragGestureStartingBoundResolutions: (x: Double, y: Double)? = nil
    
    @State private var arrowAnimationOffsetX = 0.0
    @State private var arrowAnimationOffsetY = 0.0
    
    init(resolutionX: Binding<Double>, resolutionY: Binding<Double>) {
        self._resolutionX = resolutionX
        self._resolutionY = resolutionY
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2.5))
                    .foregroundColor(.accentColor)
                    .overlay(alignment: .bottom) {
                        Text("\(boundResolutionX, specifier: "%.0f")")
                            .alignmentGuide(.bottom, computeValue: { d in d[.top] - 4 })
                            .font(.system(size: 12))
                    }
                    .overlay(alignment: .trailing) {
                        Text("\(boundResolutionY, specifier: "%.0f")")
                            .alignmentGuide(.trailing, computeValue: { d in d[.leading] - 6 })
                            .font(.system(size: 12))
                    }
                    .padding([.bottom, .trailing], 40)
                    .frame(width: proxy.size.width * pickerScaleX, height: proxy.size.height * pickerScaleY)
                    .contentShape(Rectangle())
            }
            
            Color.clear
                .contentShape(Rectangle())
                .gesture(DragGesture()
                    .onChanged { value in
                        if dragGestureStartingBoundResolutions == nil {
                            dragGestureStartingBoundResolutions = (x: boundResolutionX, y: boundResolutionY)
                        }
                        
                        let travelX = value.location.x - value.startLocation.x
                        let travelY = value.location.y - value.startLocation.y
                        let scaleX = travelX / proxy.size.width
                        let scaleY = travelY / proxy.size.height
                        
                        let proposedResolutionX = dragGestureStartingBoundResolutions!.x + (xRange.upperBound - xRange.lowerBound) * scaleX
                        resolutionX = max(min(proposedResolutionX, xRange.upperBound), xRange.lowerBound)
                        
                        let proposedResolutionY = dragGestureStartingBoundResolutions!.y + (yRange.upperBound - yRange.lowerBound) * scaleY
                        resolutionY = max(min(proposedResolutionY, yRange.upperBound), yRange.lowerBound)
                    }
                    .onEnded { _ in
                        dragGestureStartingBoundResolutions = nil
                    }
                )
        }
        .aspectRatio(1, contentMode: .fit)
        .padding([.bottom, .trailing], 16)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.and.down")
                .scaleEffect(of: 2)
                .foregroundColor(.gray)
                .opacity(0.3)
                .offset(x: 0, y: arrowAnimationOffsetY)
                .offset(x: -3)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: arrowAnimationOffsetX)
                .task { @MainActor in
                    arrowAnimationOffsetY = 15
                }
        }
        .overlay(alignment: .bottomLeading) {
            Image(systemName: "arrow.left.and.right")
                .scaleEffect(of: 2)
                .foregroundColor(.gray)
                .opacity(0.3)
                .offset(x: arrowAnimationOffsetX, y: 0)
                .offset(y: 5)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: arrowAnimationOffsetX)
                .task { @MainActor in
                    arrowAnimationOffsetX = 15
                }
        }
    }
    
    private var boundResolutionX: Double { min(max(resolutionX, xRange.lowerBound), xRange.upperBound) }
    private var pickerScaleX: Double {
        let ratio = (boundResolutionX - xRange.lowerBound) / (xRange.upperBound - xRange.lowerBound)
        return 0.85 * ratio + 0.2
    }
    
    private var boundResolutionY: Double { min(max(resolutionY, yRange.lowerBound), yRange.upperBound) }
    private var pickerScaleY: Double {
        let ratio = (boundResolutionY - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound)
        return 0.85 * ratio + 0.2
    }
}

struct FreeResolutionPicker_Previews: PreviewProvider {
    static var previews: some View {
        ResolutionPickerPreview()
            .padding()
    }
    
    @MainActor
    struct ResolutionPickerPreview: View {
        @State private var resolutionX = 640.0
        @State private var resolutionY = 340.0
        
        var body: some View {
            FreeResolutionPicker(resolutionX: $resolutionX, resolutionY: $resolutionY)
        }
    }
}
