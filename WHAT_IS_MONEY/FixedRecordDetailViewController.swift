//
//  FixedRecordDetailViewController.swift
//  WHAT_IS_MONEY
//
//  Created by jinyong yun on 2023/01/17.
//

import UIKit
import DropDown

struct existresponse: Codable {
    
    let isSuccess: Bool
    let code: Int
    let message: String
    let result: existresult
    
}

struct existresult: Codable {
    let goalIdx: Int
    let date: String
    let type: Int
    let category: String
    let amount: Int
    
    
}

struct patchrecord: Codable {
    let userIdx: Int
    let recordIdx: Int
    let date: String
    let categoryIdx: Int
    let amount: Int
    
}

class FixedRecordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var RecordDatePicker: UIDatePicker!
    
    @IBOutlet weak var SaveButton: UIButton!
    
    @IBOutlet weak var ConsumeButton: UIButton!
    
    @IBOutlet weak var MoneyTextField: UITextField!
    

    
    @IBOutlet weak var dropView: UIView!
    
    @IBOutlet weak var tfInput: UITextField!
    
    @IBOutlet weak var ivIcon: UIImageView!
    
    @IBOutlet weak var btnSelect: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        TokenClass.handlingToken()
        self.getRecord()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MoneyTextField.delegate = self
        self.loadcategory()
        self.getRecord()
        self.initUI()
        self.setDropdown()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    var recordIdx: Int?
    var goalIdx: Int?
    
    var resultlist: [categoryresultdetail] = []
    
    var itemList0: [String] = []
    var itemList1: [String] = []
    
    var flag: Int?
    var existresult1: existresult?
    
    private var diaryDate: Date? 
    private var recordtype: String?
    private var categorytype: String?
    private var moneyAmount: String?
    private var categoryname: String?
    
    func observeresultlist(){
        
        itemList0.removeAll()
        itemList1.removeAll()
        
        for resultone in resultlist {
            if resultone.flag == 0 {
                itemList0.append(resultone.category_name)
                
            } else {
                
                itemList1.append(resultone.category_name)
                
            }
            
            
        }
        
    }
    
    func findcategoryid(categoryname: String) -> Int {
        for resultlistone in resultlist {
            if resultlistone.category_name == categoryname {
                return resultlistone.categoryIdx
            }
        }
        return 0
    }
        
    func patchRecord() {
        
       
        let patchrecord = patchrecord(userIdx: UserDefaults.standard.integer(forKey: "userIdx"), recordIdx: recordIdx!, date: self.RecordDatePicker.date.toString(), categoryIdx: self.findcategoryid(categoryname: categoryname ?? "??? ??? ??????"), amount: Int(MoneyTextField.text ?? "0" ) ?? 0)
        
        guard let uploadData = try? JSONEncoder().encode(patchrecord)
        else {return}
        
        
        let url = URL(string: "https://www.pigmoney.xyz/records")
        
        
        var request = URLRequest(url: url!)
        request.httpMethod = "PATCH"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
        
        DispatchQueue.global().async {
            do {
              
                URLSession.shared.uploadTask(with: request, from: uploadData) { (data, response, error) in
                    
                 
                    if let e = error {
                        NSLog("An error has occured: \(e.localizedDescription)")
                        return
                    }
                       
                     guard let data = data else {
                         print("Error: Did not receive data")
                         return
                     }
                     
                    
                     guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                         print("Error: HTTP request failed")
                         return
                     }
                
                }.resume()
            }
        }
        }
        
        
        
    
    func loadcategory(){
        let userIdx = UserDefaults.standard.integer(forKey: "userIdx")
        if let url = URL(string: "https://www.pigmoney.xyz/category/\(userIdx)/\(flag!)"){
            
            var request = URLRequest.init(url: url)
            
            request.httpMethod = "GET"
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
            
            DispatchQueue.global().async {
                do {
                    
                    URLSession.shared.dataTask(with: request){ [self] (data, response, error) in
                        
                        guard let data = data else {
                                                  print("Error: Did not receive data")
                                                  return
                                              }
                                              
                                             
                                              
                                              
                                              
                                              guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                                                  print("Error: HTTP request failed")
                                                  return
                                              }

                        
                        let decoder = JSONDecoder()
                        if let json = try? decoder.decode(categoryresult.self, from: data) {
                            self.resultlist =  json.result
                            observeresultlist()
                        }
                        
                    }.resume() //URLSession - end
                    
                }
            }
            
        }
        
    }
    
    func getRecord() {
        let userIdx = UserDefaults.standard.integer(forKey: "userIdx")
        if let url = URL(string: "https://www.pigmoney.xyz/records/isol/\(userIdx)/\(recordIdx!)"){
            
            var request = URLRequest.init(url: url)
            
            request.httpMethod = "GET"
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
            
            URLSession.shared.dataTask(with: request){ [self] (data, response, error) in
                
                guard let data = data else {return}
                
                let decoder = JSONDecoder()
                if let json = try? decoder.decode(existresponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.RecordDatePicker.date =  json.result.date.toDate() ?? Date()
                        self.goalIdx = json.result.goalIdx
                        if json.result.type == 0 {
                            self.tapSaveOrConsume(self.SaveButton)
                        } else {
                            self.tapSaveOrConsume(self.ConsumeButton)
                        }
                        self.tfInput.text = json.result.category
                        self.MoneyTextField.text = String(json.result.amount)
                    }
                    
                }
                
            }.resume() //URLSession - end
            
            
            
        }
        
    }
    
    
    func postcategory(newcategoryname: String) {
        
        
        let addcategory = Addcategory(userIdx: UserDefaults.standard.integer(forKey: "userIdx"), flag: flag ?? 0, category_name: newcategoryname)
        guard let uploadData = try? JSONEncoder().encode(addcategory)
        else {return}
        
        
        let url = URL(string: "https://www.pigmoney.xyz/category")
        
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
        
        
    
        URLSession.shared.uploadTask(with: request, from: uploadData) { (data, response, error) in
            
         
            if let e = error {
                NSLog("An error has occured: \(e.localizedDescription)")
                return
            }
    
            
            
            
            
        }.resume()
        
        self.loadcategory()
        
    }
    
    let dropdown = DropDown()

    
    func initUI() {
        
        dropView.backgroundColor = UIColor.init(named: "#F1F1F1")
        dropView.layer.cornerRadius = 8
        
        DropDown.appearance().textColor = UIColor.black // ????????? ????????? ??????
        DropDown.appearance().selectedTextColor = UIColor.red // ????????? ????????? ????????? ??????
        DropDown.appearance().backgroundColor = UIColor.white // ????????? ?????? ?????? ??????
        DropDown.appearance().selectionBackgroundColor = UIColor.lightGray // ????????? ????????? ?????? ??????
        DropDown.appearance().setupCornerRadius(8)
        dropdown.dismissMode = .automatic // ????????? ?????? ?????? ??????
            
        tfInput.text = "??????????????????." // ?????? ?????????
            
        ivIcon.tintColor = UIColor.gray
    }

    func setDropdown() {
        // dataSource??? ItemList??? ??????
        if flag == 0 {
            
            dropdown.dataSource = itemList0
        } else {
            
            dropdown.dataSource = itemList1
        }
            
        // anchorView??? ?????? UI??? ??????
        dropdown.anchorView = self.dropView
        
        // View??? ????????? ?????? View????????? Item ????????? ????????? ??????
        dropdown.bottomOffset = CGPoint(x: 0, y: dropView.bounds.height)
        
        // Item ?????? ??? ??????
        dropdown.selectionAction = { [weak self] (index, item) in
            //????????? Item??? TextField??? ????????????.
            self!.tfInput.text = item
            self!.categoryname = item
            self!.categorytype = item
            self!.ivIcon.image = UIImage.init(named: "DropDownDown")
        }
        
        // ?????? ??? ??????
        dropdown.cancelAction = { [weak self] in
            //??? ?????? ?????? ??? DropDown??? ???????????? ???????????? ???????????? ??????
            self!.ivIcon.image = UIImage.init(named: "DropDownDown")
        }
    }
    
    @IBAction func dropdownClicked(_ sender: UIButton) {
        self.loadcategory()
        self.setDropdown()
          // ????????? ???????????? ???????????? DropDown??? ????????? ?????? ??????
          self.ivIcon.image = UIImage.init(named: "DropDownDown")
        dropdown.show()
    }
    
    @IBAction func tapSaveOrConsume(_ sender: UIButton) {
        if sender == self.SaveButton {
            self.changeButtonalpha(color: .red)
            recordtype = "save"
            flag = 0
            self.loadcategory()
            self.setDropdown()
        } else if sender == self.ConsumeButton {
            self.changeButtonalpha(color: .systemMint)
            recordtype = "consume"
            flag = 1
            self.loadcategory()
            self.setDropdown()
        }
        
    }
    
    private func changeButtonalpha(color: UIColor){
        self.SaveButton.alpha = color == UIColor.red ? 1 : 0.2
        self.ConsumeButton.alpha = color == UIColor.systemMint ? 1 : 0.2
    }
    
    
    @IBAction func AddCategory(_ sender: UIButton) {
        let alert = UIAlertController(title: "???????????? ??????", message: "???????????? ????????? ?????? ???????????????!", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField()
        let addAction = UIAlertAction(title: "??????", style: .default) { (action) in
            self.postcategory(newcategoryname: alert.textFields?[0].text ?? "??? ??? ??????")
            self.setDropdown()
                }
        let cancelAction = UIAlertAction(title: "??????", style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: false, completion: nil)
        
    }
    
    
    @IBAction func tapEditButton(_ sender: UIButton) {
        MoneyTextField.endEditing(true)
        moneyAmount = MoneyTextField.text ?? nil
        categorytype = tfInput.text ?? nil
        if moneyAmount?.isEmpty ?? false || categorytype?.isEmpty ?? false {
            let sheet = UIAlertController(title: "??????", message: "?????? ???????????? ???????????? ?????????????????? ??????????????????", preferredStyle: .alert)
            sheet.addAction(UIAlertAction(title: "??????", style: .default, handler: { _ in print("??? ????????? ??????") }))
            present(sheet, animated: true)
            return
        }
        
        
        
        self.patchRecord()
        
        if flag == 1 {
            
            
            guard let consumeViewController = self.storyboard?.instantiateViewController(withIdentifier: "ConsumeViewController") as? ConsumeViewController else {return}
            consumeViewController.goalIdx = self.goalIdx
            consumeViewController.recordDate = self.RecordDatePicker.date.toString()
            self.navigationController?.pushViewController(consumeViewController, animated: true)
            
        } else {
            self.navigationController?.popViewController(animated: true) //6. ?????? ???????????? ?????? ??????
        }
        
    }
    
    
    
    
}


/*extension String {
    func toDate() -> Date? { //"yyyy-MM-dd HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            return nil
        }
    }
}

extension Date {
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: self)
    }
}
*/
