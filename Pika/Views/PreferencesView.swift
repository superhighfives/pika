//
//  PreferencesView.swift
//  Pika
//
//  Created by Charlie Gleason on 24/12/2020.
//

import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct PreferencesView: View {
    @Default(.colorFormat) var colorFormat

    var body: some View {
        HStack(spacing: 0) {
            NavigationView {
                VersionView()
            }
            .frame(maxWidth: 140.0)
            .allowsHitTesting(false)

            VStack(spacing: 10.0) {
                Form {
                    VStack(alignment: .leading, spacing: 16.0) {
                        // Global Shortcut

                        Section(header: Text("Global Shortcut").font(.title3)) {
                            VStack(alignment: .leading) {
                                Text("Set a global hot key shortcut to invoke Pika from anywhere.")
                                    .font(.callout)
                                KeyboardShortcuts.Recorder(for: .togglePika)
                            }
                        }

                        Divider()

                        // Colour Format

                        Section(header: Text("Colour Format").font(.title3)) {
                            VStack(alignment: .leading) {
                                Text("Set a global hot key shortcut to invoke Pika from anywhere.")
                                    .font(.callout)
                                Picker("Colour Format", selection: $colorFormat) {
                                    ForEach(ColorFormatKeys.allCases, id: \.self) { value in
                                        Text(value.rawValue)
                                    }
                                }
                                .pickerStyle(RadioGroupPickerStyle())
                                .horizontalRadioGroupLayout()
                                .labelsHidden()
                            }
                        }

                        Divider()

                        // Launch at login
                        Section {
                            LaunchAtLogin.Toggle {
                                Text("Launch at login")
                            }
                        }
                    }

                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.all, 20.0)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
