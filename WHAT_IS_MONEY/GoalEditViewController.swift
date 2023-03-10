//
//  GoalEditViewController.swift
//  WHAT_IS_MONEY
//
//  Created by jinyong yun on 2023/01/20.
//

import UIKit
import AVFoundation
import Photos



protocol ImagePickerDelegate : AnyObject {
    func clickButton()
}

struct patchgoal: Codable {
    let goal_amount: Int
    let init_amount: Int
    let category_name: String
    
}

struct goallistresponseone: Codable {
    let isSuccess: Bool
    let code: Int
    let message: String
    let result: goalresult
    
    
}

struct goalpatchresponse: Codable {
    let isSuccess: Bool
    let code: Int
    let message: String
    
}


class GoalEditViewController: UIViewController, UINavigationControllerDelegate & UIImagePickerControllerDelegate, UITextFieldDelegate {

 
    @IBOutlet weak var ImgLabel: UILabel!
    @IBOutlet weak var ImgUI: UIButton!
    @IBOutlet weak var GoalNameTextField: UITextField!
    @IBOutlet weak var GoalPriceTextField: UITextField!
    @IBOutlet weak var PriceTextField: UITextField!
    @IBOutlet weak var CompleteButton: UIButton!
    
    let picker = UIImagePickerController()
    var goalresult: goalresult?
    var goalIdx: Int?
    var patchgoalone: patchgoal?
    var oldImage: String?
    
    var imageData : NSData? = nil
    
    
    override func viewWillAppear(_ animated: Bool) {
        TokenClass.handlingToken()
        self.loadgoal()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        GoalNameTextField.delegate = self
        GoalPriceTextField.delegate = self
        PriceTextField.delegate = self
        picker.delegate = self
        picker.sourceType = .photoLibrary // 앨범에서 가져옴
        picker.allowsEditing = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // TextField 비활성화
        return true
    }
    
    
    func configureView(){
        ImgLabel.text = "사진수정"
        let data = Data(base64Encoded: goalresult!.image, options: .ignoreUnknownCharacters) ?? Data()
        var decodeImg = UIImage(data: data)
        decodeImg = decodeImg?.resized(toWidth: 90.0) ?? decodeImg
        self.ImgUI.setImage(decodeImg, for: .normal)
        GoalNameTextField.text = goalresult?.category_name
        GoalPriceTextField.text = String(goalresult?.goal_amount ?? 0)
        PriceTextField.text = String(goalresult?.init_amount ?? 0)
        
        
    }
    
    /*
     image = image.resized(toWidth: 90.0) ?? image
     ImgUI.setImage(image, for: .normal)
     imagebase64 = convertImageToBase64(image: image)
     */
    // MARK: - [URL Session Post 멀티 파트 사진 데이터 업로드]
    func requestPOST() {
        
        // MARK: [사진 파일 파라미터 이름 정의 실시]
        let file = "image"
        
        let userIdx = UserDefaults.standard.integer(forKey: "userIdx")
        let accessToken = UserDefaults.standard.string(forKey: "accessToken")
        
        
        // MARK: [전송할 데이터 파라미터 정의 실시]
        var reqestParam : Dictionary<String, Any> = [String : Any]()
        //reqestParam["userIdx"] = userIdx // 일반 파라미터
        reqestParam["\(file)"] = self.imageData // 사진 파일
        
        // MARK: [URL 지정 실시]
        let urlComponents = URLComponents(string: "https://www.pigmoney.xyz/goal/uploadGoalImage/\(goalIdx!)/\(userIdx)")
        
        // [boundary 설정 : 바운더리 라인 구분 필요 위함]
        let boundary = "Boundary-\(UUID().uuidString)" // 고유값 지정
        
        
        
        // [http 통신 타입 및 헤더 지정 실시]
        var requestURL = URLRequest(url: (urlComponents?.url)!) // url 주소 지정
        requestURL.httpMethod = "POST" // POST 방식
        requestURL.setValue(accessToken!, forHTTPHeaderField: "X-ACCESS-TOKEN")
        requestURL.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type") // 멀티 파트 타입
        
        
        // [서버로 전송할 uploadData 데이터 형식 설정]
        var uploadData = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        
        
        // [멀티 파트 전송 파라미터 삽입 : 딕셔너리 for 문 수행]
        for (key, value) in reqestParam {
            if "\(key)" == "\(file)" { // MARK: [사진 파일 인 경우]
             
                
                uploadData.append(boundaryPrefix.data(using: .utf8)!)
                uploadData.append("Content-Disposition: form-data; name=\"\(file)\"; filename=\"\(file)\"\r\n".data(using: .utf8)!) // [파라미터 key 지정]
                uploadData.append("Content-Type: \("image/jpg")\r\n\r\n".data(using: .utf8)!) // [전체 이미지 타입 설정]
                uploadData.append(value as! Data) // [사진 파일 삽입]
                uploadData.append("\r\n".data(using: .utf8)!)
                uploadData.append("--\(boundary)--".data(using: .utf8)!)
            }
            else { // MARK: [일반 파라미터인 경우]
               
                
                uploadData.append(boundaryPrefix.data(using: .utf8)!)
                uploadData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!) // [파라미터 key 지정]
                uploadData.append("\(value)\r\n".data(using: .utf8)!) // [value 삽입]
            }
        }

        
        
        // [http 요쳥을 위한 URLSessionDataTask 생성]
       
        
        // MARK: [URLSession uploadTask 수행 실시]
        let dataTask = URLSession(configuration: .default)
        dataTask.configuration.timeoutIntervalForRequest = TimeInterval(20)
        dataTask.configuration.timeoutIntervalForResource = TimeInterval(20)
        dataTask.uploadTask(with: requestURL, from: uploadData) { (data: Data?, response: URLResponse?, error: Error?) in

            // [error가 존재하면 종료]
            guard error == nil else {
               
                return
            }

            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
            
                return
            }

            // [response 데이터 획득, json 형태로 변환]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let resultLen = data! // 데이터 길이
            do {
                guard let jsonConvert = try JSONSerialization.jsonObject(with: data!) as? [String: Any] else {
                   
                    return
                }
                guard let JsonResponse = try? JSONSerialization.data(withJSONObject: jsonConvert, options: .prettyPrinted) else {
                 
                    return
                }
                guard let resultString = String(data: JsonResponse, encoding: .utf8) else {
                  
                    return
                }
             
            } catch {
             
                return
            }
        }.resume()
    }
    
    
    func loadgoal(){
            let userIdx = UserDefaults.standard.integer(forKey: "userIdx")
            if let url = URL(string: "https://www.pigmoney.xyz/goal/getGoal/\(goalIdx!)/\(userIdx)"){
                
                var request = URLRequest.init(url: url)
                
                request.httpMethod = "GET"
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
                
                DispatchQueue.global().async {
                    do {
                        
                        URLSession.shared.dataTask(with: request){ [self] (data, response, error) in
                            
                            guard let data = data else {
                                print("Error: Did not receive data")
                                return
                            }
                            
                           // print(String(data: data, encoding: .utf8)!)
                            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                                print("Error: HTTP request failed")
                                return
                            }
                            
                            let decoder = JSONDecoder()
                            if let json = try? decoder.decode(goallistresponseone.self, from: data) {
                                self.goalresult = json.result
                                self.oldImage = json.result.image
                                DispatchQueue.main.async {
                                    self.configureView()
                                }
                                
                            }
                            
                        }.resume() //URLSession - end
                        
                        
                    }
                }
            }
            
        }
        
    func convertImageToBase64(image: UIImage) -> String {
        let imageData = image.pngData()!
        return imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters) }
        
    
    
        func patchGoal() {

            
            
            let patchgoal = patchgoal(goal_amount: Int(GoalPriceTextField.text ?? "5") ?? 5, init_amount: Int(PriceTextField.text ?? "5") ?? 5, category_name: GoalNameTextField.text ?? "알 수 없음")

            
                                      
            guard let uploadData = try? JSONEncoder().encode(patchgoal) else {return}
            
            
            
            // URL 객체 정의
            let userIdx = UserDefaults.standard.integer(forKey: "userIdx")
            let url = URL(string: "https://www.pigmoney.xyz/goal/modifyGoal/\(goalIdx!)/\(userIdx)")

            
            // URLRequest 객체를 정의
            var request = URLRequest(url: url!)
            request.httpMethod = "PATCH"
            // HTTP 메시지 헤더
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue( UserDefaults.standard.string(forKey: "accessToken") ?? "0", forHTTPHeaderField: "X-ACCESS-TOKEN")
            
            request.httpBody = uploadData
    
                    // URLSession 객체를 통해 전송, 응답값 처리
                    URLSession.shared.uploadTask(with: request, from: uploadData) { (data, response, error) in
                        
                        guard let data = data else {
                            print("Error: Did not receive data")
                            return
                        }
                        
                        
                        guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                            print("Error: HTTP request failed")
                            return
                        }
                        
                        let decoder = JSONDecoder()
                        if let json = try? decoder.decode(goalpatchresponse.self, from: data) {
                            print(json.message)
                            
                        }
                        // POST 전송
                    }.resume()
               
        }

    
    func openLibrary(){

        
              PHPhotoLibrary.requestAuthorization( { [self] status in
                  switch status{
                  case .authorized:
                      print("Album: 권한 허용")
                      DispatchQueue.main.sync {
                          self.picker.sourceType = .photoLibrary
                          present(picker, animated: false, completion: nil)
                      }
                  case .denied:
                      print("Album: 권한 거부")
                      DispatchQueue.main.sync {
                          
                          let alert = UIAlertController(title: "앨범권한거부", message: "앨범 접근에 대한 권한이 거부됐습니다.(권한 변경은 아이폰 설정에서!)", preferredStyle: .alert)
                          let ok =  UIAlertAction(title: "확인", style: .cancel)
                          alert.addAction(ok)
                          present(alert, animated: true, completion: nil)
                          
                      }
                  case .restricted, .notDetermined:
                      print("Album: 선택하지 않음")
                      
                  default:
                      break
                  }
              })

    }

    func openCamera(){

        AVCaptureDevice.requestAccess(for: .video, completionHandler: { [self] (granted: Bool) in
            if granted {
                print("Camera: 권한 허용")
                DispatchQueue.main.sync {
                    self.picker.sourceType = .camera
                    present(picker, animated: false, completion: nil)
                }
            } else {
                print("Camera: 권한 거부")
                DispatchQueue.main.sync {
                    let alert = UIAlertController(title: "카메라접근권한거부", message: "카메라 접근에 대한 권한이 거부됐습니다.(권한 변경은 아이폰 설정에서!)", preferredStyle: .alert)
                    let ok =  UIAlertAction(title: "확인", style: .cancel)
                    alert.addAction(ok)
                    present(picker, animated: true, completion: nil)
                }
            }
        })
    }

    @IBAction func TapImgUIButton(_ sender: UIButton) {
       
        let alert =  UIAlertController(title: "사진 수정", message: "", preferredStyle: .actionSheet)
        let library =  UIAlertAction(title: "사진앨범", style: .default) { (action) in self.openLibrary()
        }
        let camera =  UIAlertAction(title: "카메라", style: .default) { (action) in

        self.openCamera()

        }
        let delete = UIAlertAction(title: "삭제", style: .destructive){
                    //TODO 추가 이미지 setting (+)
            (action) in self.ImgUI.setImage(UIImage(named: "defaultImage")?.resized(toWidth: 90), for: .normal)
                }

        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        alert.addAction(library)

        alert.addAction(camera)
        
        alert.addAction(delete)

        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if var img = info[UIImagePickerController.InfoKey.originalImage]{
             
                
                
                img = (img as? UIImage)!.resized(toWidth: 240.0) ?? img
                let newimg = (img as? UIImage)!.resized(toWidth: 90.0) ?? img
                ImgUI.layer.cornerRadius = ImgUI.layer.frame.size.width / 2
                ImgUI.setImage(newimg as? UIImage, for: .normal)
        
                
                // [이미지 데이터에 선택한 이미지 지정 실시]
                self.imageData = (img as? UIImage)!.jpegData(compressionQuality: 0.8) as NSData? // jpeg 압축 품질 설정
                
                
                // [멀티파트 서버에 사진 업로드 수행]
                 DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // [1초 후에 동작 실시]
                 self.requestPOST()
                 }
            }
            // [이미지 파커 닫기 수행]
            dismiss(animated: true, completion: nil)
        
    }

  
    
    @IBAction func tapCompleteButton(_ sender: UIButton) {
        
        let goaltext = GoalNameTextField.text
        let goalpricetext = GoalPriceTextField.text
        let initpricetext = PriceTextField.text
        
        
        if ImgUI.currentImage == UIImage(named: "plus") || goaltext?.isEmpty ?? true || goalpricetext?.isEmpty ?? true || initpricetext?.isEmpty ?? true {
           
            let sheet = UIAlertController(title: "경고", message: "모든 입력칸에 올바르게 입력하였는지 확인해주세요", preferredStyle: .alert)
            sheet.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in print("빈 입력칸 확인") }))
            present(sheet, animated: true)
            return
        }
        
        
        
        
        self.progressStart(onView: self.view)
               
               
               // [일정 시간 후 작업 수행 : 로딩 프로그레스 종료 호출]
         DispatchQueue.main.asyncAfter(deadline: .now() + 8) { // [6초 후에 동작 실시]
                   
                   self.progressStop()
               }

      
        
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1){ [self] in
            self.PriceTextField.endEditing(true)
            patchGoal()
            
            self.navigationController?.popViewController(animated: true)
        }
        
        
    }
    
}
