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
import CoreLocation

class InterfaceController: WKInterfaceController {
    let healthStore = HKHealthStore()
    var session:HKWorkoutSession?
    var builder:HKLiveWorkoutBuilder?
    var routeBuilder:HKWorkoutRouteBuilder?
    var locationManager = CLLocationManager()
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func startTapped() {
        print("start tapped")
        startWorkout()
        
        if(HKHealthStore.isHealthDataAvailable()){
            print("HealthData AVAILABLE")
            let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKObjectType.workoutType(),
            HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
            ]
            
            let readTypes: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
            //let writeTypes: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
            healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (isSuccess, err) in
                if(isSuccess){
                    print("Authorization SUCCESS")
                    self.startHeartRateQuery(quantityTypeIdentifier: .heartRate)

                } else {
                    print("Authorization FAILED")
                    print (err)
                }
            }
            
        } else {
            print("HealthData UMAVAILABLE")

        }
    }
    
    func startWorkout(){
        let configuration = HKWorkoutConfiguration.init()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        do {
            session = try HKWorkoutSession.init(healthStore: healthStore, configuration: configuration)
            guard let session = session else {
                return
            }
            let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
            self.routeBuilder = routeBuilder
            builder = session.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
            workoutConfiguration: configuration)
            session.delegate = self
            builder?.delegate = self
            session.startActivity(with: Date())

            builder?.beginCollection(withStart: Date()) { (success, error) in
                
                if(success == true){
                    print("BUILDER BEGIN COLLECTION")

                }
//                guard success else {
//                    // Handle errors.
//                }
                // Indicate that the session has started.
            }
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.delegate = self

        } catch  {
            print("ERR")
        }
    }
    
    
    func finishWorkout(){
        session?.end()
        locationManager.stopUpdatingLocation()
        guard let session = self.session else {
            return
        }
//        guard let startDate = session.startDate else {
//            return
//        }
//        guard let endDate = session.endDate else {
//            return
//        }
        let workout = HKWorkout.init(activityType: .running, start: Date.init(timeIntervalSinceNow: -300), end: Date.init())
        self.healthStore.save(workout) { (success, error) in
            if success {
                print("workout save success")
                self.routeBuilder?.finishRoute(with: workout, metadata: ["name":"takashi"]) { (newRoute, error) in
                    
                    guard newRoute != nil else {
                        // Handle any errors here.
                        print("save route failure")
                        print(error)
                        return
                    }
                    print("save route success")
                    // Optional: Do something with the route here.
                }
            } else {
                print("workout save failure")
                print(error)
            }
        }

    }
    
    @IBAction func stopTapped() {
        print("stop tapped")
        finishWorkout()

    }
    
    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        
        // We want data points from our current device
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        // A query that returns changes to the HealthKit store, including a snapshot of new changes and continuous monitoring as a long-running query.
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
         // A sample that represents a quantity, including the value and the units.
        guard let samples = samples as? [HKQuantitySample] else {
            return
        }
            
        self.process(samples, type: quantityTypeIdentifier)

        }
        
        // It provides us with both the ability to receive a snapshot of data, and then on subsequent calls, a snapshot of what has changed.
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        // query execution
        
        healthStore.execute(query)
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        // variable initialization
        var lastHeartRate = 0.0
        
        // cycle and value assignment
        for sample in samples {
            if type == .heartRate {
                print("heartRate:\(sample)")
//                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
            print(lastHeartRate)
        }
    }
    
    func hoge(){
        HKQuantityTypeIdentifier.distanceWalkingRunning
        HKQuantityTypeIdentifier.height
    }
}

extension InterfaceController : HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date)
    {
        print("WORKOUT STATUS CHANGED: \(fromState.rawValue) to \(toState.rawValue)")
    }
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error){
        print("WORKOUT FAILED")

    }
}

extension InterfaceController: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        print("BUILDER COLLECT: \(collectedTypes)")
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            // Calculate statistics for the type.
            let statistics = workoutBuilder.statistics(for: quantityType)
            //let label = labelForQuantityType(quantityType)
            
            DispatchQueue.main.async() {
                // Update the user interface.
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        let lastEvent = workoutBuilder.workoutEvents.last
        print("BUILDER DID COLLECT EVENT: \(lastEvent)")
        
        DispatchQueue.main.async() {
            // Update the user interface here.
        }
    }
}

extension InterfaceController:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        print("location didUpdateLocations")
        print(locations)
        
        let filteredLocations = locations.filter { (location: CLLocation) -> Bool in
            location.horizontalAccuracy <= 50.0
        }
        
        guard !filteredLocations.isEmpty else {
            print ("EMPTY LOCATION")
            return }
        
        routeBuilder?.insertRouteData(filteredLocations) { (success, error) in
            if success {
                print("insertRouteData SUCCESS")
                
            } else {
                print("insertRouteData FAILED")
                print(error)
            }
        }
    }
}
