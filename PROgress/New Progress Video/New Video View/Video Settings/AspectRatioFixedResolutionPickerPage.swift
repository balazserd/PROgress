//
//  AspectRatioFixedResolutionPickerPage.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 29..
//

import SwiftUI

struct AspectRatioFixedResolutionPickerPage: View {
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
                    Text("Resize the frame rectangle by dragging it along the customized axis, or specify the custom extent of the frame manually.")
                }
                
                GridRow {
                    Text("💡").font(.body)
                    Text("To resize both dimensions freely, select another resolution mode: \"Custom (both extents)\"")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
                .padding(.bottom, 2)
            
            HStack {
                Text("Custom dimension")
                    .padding(.top, 2)
                
                Spacer()
                
                Picker("", selection: $viewModel.userSettings.customExtentAxis) {
                    ForEach(Axis.allCases, id: \.self) { axis in
                        Text(axis.displayName)
                            .tag(axis as Axis?)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            
            Divider()
                .padding(.bottom, 6)
            
            HStack {
                Text("Width")
                    .font(.subheadline)
                
                TextField("Width", value: $viewModel.userSettings.extentX, formatter: numberFormatter)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.userSettings.customExtentAxis != .horizontal)
                
                Text(" X ")
                    .bold()
                
                TextField("Height", value: $viewModel.userSettings.extentY, formatter: numberFormatter)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.userSettings.customExtentAxis != .vertical)
                
                Text("Height")
                    .font(.subheadline)
            }
            
            AspectRatioFixedResolutionPicker(resolution: customExtentBinding,
                                             aspectRatio: viewModel.userSettings.aspectRatio,
                                             customDimension: viewModel.userSettings.customExtentAxis!)
            
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

struct AspectRatioFixedResolutionPickerPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AspectRatioFixedResolutionPickerPage()
                .environmentObject(NewProgressVideoViewModel.previewForVideoSettings)
        }
    }
}
