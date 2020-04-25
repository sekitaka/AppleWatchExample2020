//
//  ViewController.swift
//  WatchAppExample
//
//  Created by Takashi Seki on 2020/04/23.
//  Copyright © 2020 Takashi Seki. All rights reserved.
//

import UIKit
import HealthKit
import MapKit
class ViewController: UIViewController {
    let healthStore = HKHealthStore()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func onSearchWorkoutTapped(_ sender: Any) {
        let healthKitTypes: Set = [
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
        HKObjectType.workoutType(),
        HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
        ]
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (isSuccess, err) in
            if(isSuccess){
                print("Authorization SUCCESS")
                self.searchWorkout()

            } else {
                print("Authorization FAILED")
                print (err)
            }
        }
    }
    
    @IBAction func onSearchHeartRateTapped(_ sender: Any) {
        searchHeartRace()
    }
    func searchWorkout() {
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let sort = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 10, sortDescriptors: [sort]) { (query, data, error) in
                print(error)
            print("\(data?.count)個のワークアウト")
            print(data)
            guard let latest:HKWorkout = data?.first as? HKWorkout else {
                return
            }
            self.showWorkoutDetail(workout: latest)
            self.searchWorkoutRoute(workout: latest)
        }

        healthStore.execute(query)
    }
    
    func showWorkoutDetail(workout:HKWorkout){
        print("開始: \(workout.startDate)")
        print("終了: \(workout.endDate)")
        print("距離: \(workout.totalDistance)")
        print("時間: \(workout.duration)")
    }
    
    func searchHeartRace(){
        let predicate = HKQuery.predicateForSamples(withStart: Date.init(timeIntervalSinceNow: -3600), end: Date.init(), options: [])
        let sortDescriptors = [NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
        ]
        
        let query = HKSampleQuery.init(sampleType: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!, predicate: predicate, limit: 1000, sortDescriptors: sortDescriptors) { (query
            , data, error) in
            print(error)
            print(data)
            print("\(data?.count)個の心拍")
            guard let heartRates:[HKQuantitySample] = data as? [HKQuantitySample] else {
                return
            }
            let heartRateUnit:HKUnit = HKUnit.init(from: "count/min")
            heartRates.forEach{
                print("\($0.startDate): \($0.quantity.doubleValue(for: heartRateUnit))")
            }
        }
        healthStore.execute(query)
    }
    
    func searchWorkoutRoute(workout: HKWorkout){
        let runningObjectQuery = HKQuery.predicateForObjects(from: workout)
        
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            print("INITIAL QUERY")

            guard error == nil else {
                // Handle any errors here.
                fatalError("The initial query failed.")
            }
            print(samples?.first?.sampleType)
            guard let routes = samples as? [HKWorkoutRoute] else {
                print("INVALID TYPE")
                return ;
            }
            print(routes.first)
            guard let route = routes.first else {
                print("NOT FOUND")
                return
            }
            
            // Create the route query.
            let query = HKWorkoutRouteQuery(route:route) { (query, locationsOrNil, done, errorOrNil) in

                // This block may be called multiple times.

                if let error = errorOrNil {
                    // Handle any errors here.
                    return
                }

                guard let locations = locationsOrNil else {
                    fatalError("*** Invalid State: This can only fail if there was an error. ***")
                }

                // Do something with this batch of location data.
                locations.forEach {a in
                    
                    print(a.timestamp, a.coordinate.latitude, a.coordinate.longitude)
                }
                
                if done {
                    print("DONE")
                    // The query returned all the location data associated with the route.
                    // Do something with the complete data set.
                }

                // You can stop the query by calling:
                // store.stop(query)

            }
            self.healthStore.execute(query)
            
            
            // Process the initial route data here.
        }

        routeQuery.updateHandler = { (query, samples, deleted, anchor, error) in
            print("UPDATE QUERY")

            guard error == nil else {
                // Handle any errors here.
                fatalError("The update failed.")
            }
            
            // Process updates or additions here.
            print(samples)
        }
        
        healthStore.execute(routeQuery)

    }

}

