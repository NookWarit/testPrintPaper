//
//  ViewController.swift
//  TestPrintPaper
//
//  Created by warittha on 24/7/2562 BE.
//  Copyright © 2562 warittha. All rights reserved.
//

import UIKit
import MMApi
import CoreBluetooth
import MBProgressHUD
import TZImagePickerController

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet private weak var devicesTableView: UITableView!
    private var devicesArray: [AnyHashable] = []
    @IBOutlet private weak var connecteDevice: UILabel!
    @IBOutlet private weak var printImageView: UIImageView!
    private var hubView: MBProgressHUD?
    private var currentDeviceMac = ""
    @IBOutlet weak var printButton: UIButton!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        initUI()
        addNotificationObserve()
    }

    
    func initData() {
        
        MMSharePrint.regist(withAppID: 1510197503, appKey: "mm7828a2556cea412b", andSecret: "f8ac6490884b4ddc84bdf1053d7fd6dd", success: {
            print("\(MMSharePrint.getAuthorizationStatus() ? "YES" : "NO")")
        }, fail: { error in
            if let error = error {
                print("\(error)")
            }
        })
        
        //    [MMSharePrint debugLog:YES];
        print("\(MMSharePrint.getSdkVersion())")
        //    NSLog(@"%@",[MMSharePrint getLastPeripheralUUID]);
    }
    
    func initUI() {
        devicesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        printImageView.image = UIImage(named: "123.jpg")
        
    }
    func addNotificationObserve() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(didDiscoverDevice(_:)), name: NSNotification.Name.MMDidDiscoverPeripheral, object: nil)
        center.addObserver(self, selector: #selector(didConnectDevice(_:)), name: NSNotification.Name.MMDidConnectPeripheral, object: nil)
        center.addObserver(self, selector: #selector(didConnectDevice(_:)), name: NSNotification.Name.MMWillConnectPeripheral, object: nil)
        center.addObserver(self, selector: #selector(didFailConnectDevice(_:)), name: NSNotification.Name.MMDidFailToConnectPeripheral, object: nil)
        center.addObserver(self, selector: #selector(willSendData(_:)), name: NSNotification.Name.MMWillSendData, object: nil)
        center.addObserver(self, selector: #selector(deviceStatusChanged(_:)), name: NSNotification.Name.MMDeviceExceptionStatus, object: nil)
        center.addObserver(self, selector: #selector(didDisconnectDevice(_:)), name: NSNotification.Name.MMDidDisconnectPeripheral, object: nil)    }
    @IBAction func onClickPrint(_ sender: UIButton) {
            sender.isEnabled = false
            weak var weakSelf = self
            if MMSharePrint.getDeviceConnectStatus() {
        
                MMSharePrint.print(printImageView.image, printType: .forImage, completeSendData: {
                    print("数据发送完成การส่งข้อมูลเสร็จสมบูรณ์")
                    weakSelf!.printButton.isEnabled = true
                }, fail: { error in
                    if let error = error {
                        print("\(error)")
                    }
                })
            } else {
                printButton.isEnabled = true
                print("未连接设备อุปกรณ์ที่ไม่ได้เชื่อมต่อ")
            }
    }
    @objc func didDiscoverDevice(_ noti: Notification?) {
            if let noti = noti {
                print("\(noti)")
            }
            let devicesInfo = noti?.object as? [AnyHashable : Any]
        
            var mSet = Set<AnyHashable>(array: devicesArray)
            mSet.insert(devicesInfo)
            print("result: \(Array(mSet))")
            devicesArray.array = Array(mSet)
            devicesTableView.reloadData()
    }
    
    @objc func didFailConnectDevice(_ noti: Notification?) {
            if let object = noti?.object {
                print("\(object)")
            }
        hubView!.hide(animated: true)
    }
    
    @objc func didConnectDevice(_ noti: Notification?) {
            print("connect success")
            connecteDevice.text = currentDeviceMac
            MMSharePrint.stopScan()
            hubView!.hide(animated: true)
    }
    @objc func willSendData(_ noti: Notification?) {
    }

    @objc func deviceStatusChanged(_ noti: Notification?) {
        if let object = noti?.object {
            print("\(object)")
        }
    }
    
    @objc func didDisconnectDevice(_ noti: Notification?) {
            if let object = noti?.object {
                print("\(object)")
            }
            currentDeviceMac = ""
            connecteDevice.text = currentDeviceMac
        }
    
    @IBAction func disconnectAllDevices(_ sender: UIButton) {
        MMSharePrint.disconnect()
        currentDeviceMac = ""
        connecteDevice.text = currentDeviceMac
    }
    
    @IBAction func selectImage(_ sender: UITapGestureRecognizer) {
        let imagePickerVc = TZImagePickerController(maxImagesCount: 1, delegate: nil)
    
        imagePickerVc!.didFinishPickingPhotosHandle = { photos, assets, isSelectOriginalPhoto in
            self.printImageView.image = photos?.first
        }
        present(imagePickerVc!, animated: true)
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellDict = devicesArray[indexPath.row]
        print("\(cellDict)")
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        tableViewCell.selectionStyle = .none
        let peripheral = cellDict["peripheral"] as? CBPeripheral
        tableViewCell.textLabel?.text = "\(peripheral?.name ?? "") \(cellDict["MAC"])"
        return tableViewCell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devicesArray.count
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "设备列表รายการอุปกรณ์"
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let cellDict = devicesArray[indexPath.row]
        
            // MARK: -- 连接打印机 เชื่อมต่อเครื่องพิมพ์
            let peripheral = cellDict["peripheral"] as? CBPeripheral
            MMSharePrint.connect(peripheral)
            currentDeviceMac = "\(peripheral?.name ?? "") \(cellDict["MAC"])"
            hubView = MBProgressHUD.showAdded(to: view, animated: true)
        hubView!.mode = MBProgressHUDMode.text
        hubView!.label.text = "连接设备中อุปกรณ์ที่เชื่อมต่อ"
        
        }
    
        func devicesArray() -> [AnyHashable]? {
            if !devicesArray {
                devicesArray = [AnyHashable]()
            }
            return devicesArray
        }

}
