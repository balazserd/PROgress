//
//  FreeResolutionPickerPage.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 31..
//

import SwiftUI

struct FreeResolutionPickerPage: View {
    @EnvironmentObject private var viewModel: NewProgressVideoViewModel
    
    @State private var numberFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Grid(alignment: .leading, verticalSpacing: 8) {
                GridRow {
                    Text("💡").font(.body)
                    Text("Resize the frame rectangle by dragging it along either axis, or specify the extents of the frame manually.")
                }
                
                GridRow {
                    Text("💡").font(.body)
                    Text("To resize, but keep the original aspect ratio unchanged, select another resolution mode: \"Custom (preserve aspect ratio)\"")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
                .padding(.bottom, 6)
            
            HStack {
                Text("Width")
                    .font(.subheadline)
                
                TextField("Width", value: $viewModel.userSettings.extentX, formatter: numberFormatter)
                    .textFieldStyle(.roundedBorder)
                
                Text(" X ")
                    .bold()
                
                TextField("Height", value: $viewModel.userSettings.extentY, formatter: numberFormatter)
                    .textFieldStyle(.roundedBorder)
                
                Text("Height")
                    .font(.subheadline)
            }
            
            FreeResolutionPicker(resolutionX: $viewModel.userSettings.extentX,
                                 resolutionY: $viewModel.userSettings.extentY)
            
            
            Spacer()
        }
        .navigationTitle("Custom resolution")
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var customExtentBinding: Binding<Double> {
        if viewModel.userSettings.customExtentAxis == .horizontal {
            return $viewModel.userSettings.extentX
        } else {
            return $viewModel.userSettings.extentY
        }
    }
}

struct FreeResolutionPickerPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FreeResolutionPickerPage()
                .environmentObject(NewProgressVideoViewModel())
        }
    }
}
