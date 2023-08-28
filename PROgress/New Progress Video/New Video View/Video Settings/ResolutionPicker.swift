//
//  ResolutionPicker.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 28..
//

import SwiftUI

struct ResolutionPicker: View {
    @Binding var resolution: Int
    
    let range: ClosedRange<Int> = 120...4096
    
    var aspectRatio: Double = 1.0
    var customDimension: Axis = .horizontal
    
    private var xRange: ClosedRange<Int>
    private var yRange: ClosedRange<Int>
    
    init(resolution: Binding<Int>, aspectRatio: Double = 1.0, customDimension: Axis = .horizontal) {
        self._resolution = resolution
        self.aspectRatio = aspectRatio
        self.customDimension = customDimension
        
        if aspectRatio >= 1.0 {
            xRange = range
            yRange = Int(Double(range.lowerBound) / aspectRatio)...Int(Double(range.upperBound) / aspectRatio)
        } else {
            yRange = range
            xRange = Int(Double(range.lowerBound) * aspectRatio)...Int(Double(range.upperBound) * aspectRatio)
        }
        
        print(xRange)
        print(yRange)
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2.5 / scale))
                    .foregroundColor(.accentColor)
                    .overlay(alignment: .bottom) {
                        Text("\(resolution)")
                            .alignmentGuide(.bottom, computeValue: { d in d[.top] - 4 / scale })
                            .font(.system(size: 12 / scale))
                    }
                    .overlay(alignment: .trailing) {
                        Text("\(Int(Double(resolution) / aspectRatio))")
                            .alignmentGuide(.trailing, computeValue: { d in d[.leading] - 6 / scale })
                            .font(.system(size: 12 / scale))
                    }
                    .padding([.bottom], 16)
                    .padding(.trailing, 40)
                    .scaleEffect(CGSize(width: scale, height: scale), anchor: .topLeading)
                    .contentShape(Rectangle())
            }
            .gesture(DragGesture()
                .onChanged { value in
                    print(value.location)
                    let scaleX = max(value.location.x, proxy.size.width * Double(range.lowerBound) / Double(range.upperBound)) / proxy.size.width
                    let scaleY = max(value.location.y, proxy.size.height * Double(range.lowerBound) / Double(range.upperBound)) / proxy.size.height

                    print("(scaleX: \(scaleX), scaleY: \(scaleY))")
                    let finalScale = max(scaleX, scaleY)
                    let _resolution = Int(Double(customizedRange.upperBound - customizedRange.lowerBound) * finalScale)
                    print(_resolution)
                    
                    resolution = max(min(_resolution, customizedRange.upperBound), customizedRange.lowerBound)
                }
            )
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
    
    private var customizedRange: ClosedRange<Int> {
        self.customDimension == .horizontal ? xRange : yRange
    }
    
    private var scale: Double {
        let ratio = Double(resolution - customizedRange.lowerBound) / Double(customizedRange.upperBound - customizedRange.lowerBound)
        return 0.85 * ratio + 0.1
    }
}

struct ResolutionPicker_Previews: PreviewProvider {
    static var previews: some View {
        ResolutionPickerPreview()
            .padding()
    }
    
    @MainActor
    struct ResolutionPickerPreview: View {
        @State private var resolution = 2048
        
        var body: some View {
            ResolutionPicker(resolution: $resolution, aspectRatio: 16 / 9)
        }
    }
}
