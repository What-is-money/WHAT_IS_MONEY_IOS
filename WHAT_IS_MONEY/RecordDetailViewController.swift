//
//  RecordDetailViewController.swift
//  WHAT_IS_MONEY
//
//  Created by jinyong yun on 2023/01/11.
//

import UIKit


struct recorddeletepost: Codable {
    let userIdx: Int
    let recordIdx: Int
    
}

struct recordlistpost: Codable {
    let userIdx: Int
    let goalIdx: Int
    let date: String
    
}

struct response1: Codable {
    let isSuccess: Bool
    let code: Int
    let message: String
    let result: resulttwo
    
}

struct resulttwo: Codable {
    let records: [resultlist]
    let date: String
}

struct resultlist: Codable {
    let recordIdx: Int
    let type: Int
    let category: String
    let amount: Int
}

class RecordDetailViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var DateTextField: UITextField!
    
    @IBOutlet weak var DateButton: UIButton!
    
    @IBOutlet var EditButton: UIButton!
    
    var doneButton: UIButton?
    
    @IBOutlet weak var tableView: UITableView!
    
    var edittapnum: Int = 0
    
    var recordDate: String?
    var goalIdx: Int?
    
    private var recordList = [resultlist]() //
    
    override func viewWillAppear(_ animated: Bool) {
        TokenClass.handlingToken()
        getrecordList()
        tableView.reloadData()
        DateTextField.text = recordDate
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        DateTextField.delegate = self
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // TextField λΉνμ±ν
        return true
    }
    
    func getrecordList(){
        
        /*let record = recordlistpost(userIdx: UserDefaults.standard.integer(forKey: "userIdx"), goalIdx: goalIdx!, date: recordDate!)
        guard let uploadData = try? JSONEncoder().encode(record)
        else {return}*/
        
        let userIdx = UserDefaults.standard.integer(forKey: "userIdx")
        // URL κ°μ²΄ μ μ
        let url = URL(string: "https://www.pigmoney.xyz/daily-records/\(userIdx)/\(goalIdx!)/\(recordDate!)")
        
        // URLRequest κ°μ²΄λ₯Ό μ μ
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        // HTTP λ©μμ§ ν€λ
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
        
        
        DispatchQueue.global().async {
            do {
                
                // URLSession κ°μ²΄λ₯Ό ν΅ν΄ μ μ‘, μλ΅κ° μ²λ¦¬
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    
                    // μλ²κ° μλ΅μ΄ μκ±°λ ν΅μ μ΄ μ€ν¨
                    if let e = error {
                        NSLog("An error has occured: \(e.localizedDescription)")
                        return
                    }
                    // μλ΅ μ²λ¦¬ λ‘μ§
                    guard let data = data else {
                        print("Error: Did not receive data")
                        return
                    }
                    
                    guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                        print("Error: HTTP request failed")
                        return
                    }
                    
                    // data
                    let decoder = JSONDecoder()
                    if let json = try? decoder.decode(response1.self, from: data) {
                        self.recordList = json.result.records
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        
                    }
                    
                    // POST μ μ‘
                }.resume()
            }
        }
    }
    
    func deleterecordList(recordIdx: Int){
        
        let recorddelete = recorddeletepost(userIdx: UserDefaults.standard.integer(forKey: "userIdx"), recordIdx: recordIdx)
        guard let uploadData = try? JSONEncoder().encode(recorddelete)
        else {return}
        
        // URL κ°μ²΄ μ μ
        let url = URL(string: "https://www.pigmoney.xyz/records")
        
        // URLRequest κ°μ²΄λ₯Ό μ μ
        var request = URLRequest(url: url!)
        request.httpMethod = "DELETE"
        // HTTP λ©μμ§ ν€λ
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
        
        DispatchQueue.main.async {
            do {
                // URLSession κ°μ²΄λ₯Ό ν΅ν΄ μ μ‘, μλ΅κ° μ²λ¦¬
                URLSession.shared.uploadTask(with: request, from: uploadData) { (data, response, error) in
                    
                    // μλ²κ° μλ΅μ΄ μκ±°λ ν΅μ μ΄ μ€ν¨
                    if let e = error {
                        NSLog("An error has occured: \(e.localizedDescription)")
                        return
                    }
                    // μλ΅ μ²λ¦¬ λ‘μ§
                    guard let data = data else {
                        print("Error: Did not receive data")
                        return
                    }
                   
                    
                    guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                        print("Error: HTTP request failed")
                        return
                    }
                
                // POST μ μ‘
            }.resume()
        }
    }
        
    }
    

    
    @IBAction func tapEditButton(_ sender: UIButton) {
        if edittapnum == 0 {
            print("edittapnum==0μ΄λ€")
            guard !self.recordList.isEmpty else {return}
            self.EditButton.titleLabel?.text = "νΈμ§λ"
            self.EditButton.titleLabel?.textColor = UIColor.red
            self.tableView.setEditing(true, animated: true)
            edittapnum = edittapnum + 1
        } else {
            print("edittapnum=1μ΄λ€")
            self.EditButton.titleLabel?.text = "νΈμ§"
            self.EditButton.titleLabel?.textColor = UIColor(red: 0.3255, green: 0.4667, blue: 0.9647, alpha: 1.0)
            self.tableView.setEditing(false, animated: true)
            edittapnum = edittapnum - 1
            getrecordList()
            
        }
    }
    
    
    @IBAction func tapPlusButton(_ sender: UIButton) {
        guard let writerecordViewController = self.storyboard?.instantiateViewController(withIdentifier: "WriteRecordViewController") as? WriteRecordViewController else {return}
        let goalIdx = self.goalIdx
       writerecordViewController.goalIdx = goalIdx
        self.navigationController?.pushViewController(writerecordViewController, animated: true)}
        
    }
    


extension RecordDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let fixedRecordViewController = self.storyboard?.instantiateViewController(withIdentifier: "FixedRecordViewController") as? FixedRecordViewController else {return}
        let recordIdx = self.recordList[indexPath.row].recordIdx
        fixedRecordViewController.recordIdx = recordIdx
        fixedRecordViewController.flag = self.recordList[indexPath.row].type
        self.navigationController?.pushViewController(fixedRecordViewController, animated: true)
    }
    
    
}

extension RecordDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recordList.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordDetailTableViewCell", for: indexPath) as? RecordDetailTableViewCell else { return UITableViewCell() }
         let record = self.recordList[indexPath.row]
         if record.type == 0 {
            cell.CellKindLabel.text = "μ μΆ"
             cell.CellKindLabel.textColor = UIColor(red: 0.3255, green: 0.4667, blue: 0.9647, alpha: 1.0)
             cell.CostLabel.textColor = UIColor(red: 0.3255, green: 0.4667, blue: 0.9647, alpha: 1.0)
            
        } else {
            cell.CellKindLabel.text = "μ§μΆ"
            cell.CellKindLabel.textColor = UIColor.red
            cell.CostLabel.textColor = UIColor.red
        }
        
        cell.CategoryLabel.text = record.category
        cell.CostLabel.text = String(record.amount)
 
        return cell
    }
    
    
    func tableView(_ tableview: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let record = self.recordList[indexPath.row]
        let recordidx = record.recordIdx
        deleterecordList(recordIdx: recordidx)
        recordList.remove(at: indexPath.row)
        tableview.reloadData()
        
    }
    
}


