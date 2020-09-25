//
//  ContentView.swift
//  SandMann
//
//  Created by Jonathan Sweeney on 9/24/20.
//

import SwiftUI
import CoreML

struct ContentView: View {
    @State private var wakeup = defaultWakeTime
    @State private var sleepAmount = 8.0
    @State private var coffee = 1
    @State private var actualSleep = 8.0
    
    @State private var isShowing = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 5
        components.minute = 30
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    var predictedBedtime: String {
        let model: SleepCalculator = {
            do {
                let config = MLModelConfiguration()
                return try SleepCalculator(configuration: config)
            } catch {
                print(error)
                fatalError("Couldn't create SleepCalculator")
            }
        }()
        let components = Calendar.current.dateComponents([.hour, .minute], from: wakeup)
        let hour = (components.hour ?? 0) * 60 * 60
        let minute = (components.minute ?? 0) * 60
        var bedTime = "Please input your values"
        
        do {
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffee))
            let sleepTime = wakeup - prediction.actualSleep
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            bedTime = "\(formatter.string(from: sleepTime))"
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem calculating your bedtime."
            isShowing = true
        }
        return bedTime
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recommended BedTime")) {
                    Text("\(predictedBedtime)")
                        .font(.largeTitle)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("When do you want to wakeup?")
                        .font(.headline)
                    HStack {
                        Spacer()
                        DatePicker("Please enter a time",
                                   selection: $wakeup,
                                   displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Spacer()
                    }
                }
                
                Section(header: Text("Desired amount of sleep")) {
                    Stepper(value: $sleepAmount, in: 4 ... 12, step: 0.25) {
                        Text("\(sleepAmount, specifier: "%g") hours")
                    }
                }
                
                Section(header: Text("Daily Cups of Coffee Intake"))  {
                    Picker(selection: $coffee, label: Text("Cups per day")) {
                        ForEach(0 ..< 21) {i in
                            Text("\(i)")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .navigationTitle("SandMann")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $isShowing) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func calulateBedtime() {
        let model: SleepCalculator = {
            do {
                let config = MLModelConfiguration()
                return try SleepCalculator(configuration: config)
            } catch {
                print(error)
                fatalError("Couldn't create SleepCalculator")
            }
        }()
        let components = Calendar.current.dateComponents([.hour, .minute], from: wakeup)
        let hour = (components.hour ?? 0) * 60 * 60
        let minute = (components.minute ?? 0) * 60
        
        do {
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffee))
            let sleepTime = wakeup - prediction.actualSleep
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            alertMessage = formatter.string(from: sleepTime)
            alertTitle = "Your ideal bedtime is..."
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem calculating your bedtime."
        }
        isShowing = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
