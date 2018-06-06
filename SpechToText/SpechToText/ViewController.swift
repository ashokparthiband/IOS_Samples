//
//  ViewController.swift
//  SpechToText
//
//  Created by Ashok Parthiban D on 05/06/18.
//  Copyright © 2018 Ashok Parthiban D. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController,SFSpeechRecognizerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microPhoneButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var alert: UIAlertController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        microPhoneButton.isEnabled = false
        speechRecognizer?.delegate = self
        
        var authorizationMessage = ""
        
        SFSpeechRecognizer.requestAuthorization {
            (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                authorizationMessage = "Request Authorization Denied."
            case .restricted:
                isButtonEnabled = false
                authorizationMessage = "Request Authorization Restriced."
            case .notDetermined:
                isButtonEnabled = false
                authorizationMessage = "Request Authorization Not Determined."
            }
            
            OperationQueue.main.addOperation {
                self.microPhoneButton.isEnabled = isButtonEnabled;
                if (authorizationMessage.count>0) {
                    self.displayAlert(withMessage: authorizationMessage)
                }
            }
            
        }
        
    }

    
    @IBAction func microPhoneTapped(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microPhoneButton.isEnabled = false
            microPhoneButton.setTitle("Start Recording", for: .normal)
        } else {
            self.microPhoneButton.setTitle("Stop Recording", for: .normal)
            self.startRecording()
        }
    }
    
    func startRecording(){
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        }catch {
            self.displayAlert(withMessage: "AudioSession properties weren't set because of an error.")
        }
        
        
        
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: {(result,error) in
            
            var isFinal = false
            
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microPhoneButton.isEnabled = true
            }
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func displayAlert(withMessage message:String) {
        alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

