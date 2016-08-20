//
//  ViewController.swift
//  BluetoothTest
//
//  Created by Brian Dutton on 8/9/16.
//  Copyright © 2016 Asinine Games. All rights reserved.
//

import UIKit
import CoreBluetooth

let statusKey = "status:"
let readingsKey = "readings:"

class ViewController: UIViewController {
    
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      self.bluetoothManager = BluetoothManager()
   }
   
   @IBOutlet weak var bluetoothStateLabel: UILabel!
   @IBOutlet weak var heartRateLabel: UILabel!
   @IBOutlet weak var oxygenLabel: UILabel!
   @IBOutlet weak var piLabel: UILabel!
   @IBOutlet weak var scanBtnLabel: UIButton!
   @IBOutlet weak var saveBtnLabel: UIButton!
   
   @IBAction func saveBtnPressed(sender: AnyObject) {

   }
   
   @IBAction func scanBtnClicked(sender: AnyObject) {
      bluetoothManager.startManager()
   }
   
   var bluetoothManager: BluetoothManager!
   

   override func viewDidLoad() {
      super.viewDidLoad()

      bluetoothManager.startManager()

      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.statusNotification(_:)), name: statusKey, object: nil)
      NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.readingsNotification(_:)), name: readingsKey, object: nil)

   }
   
   
   func statusNotification(notification: NSNotification) {
      guard let statusString = notification.userInfo!["status"]  
      else {
         print("Status user info error")
         return
      }

      bluetoothStateLabel.text = String("\(statusString)")
   }
   
   
   func readingsNotification(notification: NSNotification) {
      
      guard let hr = notification.userInfo!["hr"],
            let oxygen = notification.userInfo!["oxygen"],
            let pi = notification.userInfo!["pi"]
      else {
         print("Readings user info error")
         return
      }
      
      heartRateLabel.text = String(hr)
      oxygenLabel.text = String(oxygen)
      piLabel.text = String(pi)
      
   }
   
  
}