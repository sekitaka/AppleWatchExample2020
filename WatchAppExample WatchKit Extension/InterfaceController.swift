//
//  InterfaceController.swift
//  WatchAppExample WatchKit Extension
//
//  Created by Takashi Seki on 2020/04/23.
//  Copyright © 2020 Takashi Seki. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {
    let healthKitStore = HKHealthStore()
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func startTapped() {
        print("start tapped")
        if(HKHealthStore.isHealthDataAvailable()){
            print("HealthData AVAILABLE")
            let readTypes: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
            healthKitStore.requestAuthorization(toShare: nil, read: readTypes) { (isSuccess, err) in
                if(isSuccess){
                    print("Authorization SUCCESS")
                    let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

                    let query = HKSampleQuery.init(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: nil, limit: 1, sortDescriptors: sortDescriptors) { (query, data, error) in
                        if(error != nil){
                            print("QUERY FAILED")
                            print(error)
                        }
                        print(data)
                    }
                    self.healthKitStore.execute(query)
                } else {
                    print("Authorization FAILED")
                    print (err)
                }
            }
            
        } else {
            print("HealthData UMAVAILABLE")

        }
    }
    @IBAction func stopTapped() {
        print("stop tapped")

    }
}
