//
//  ViewController.swift
//  TextRecognizer
//
//  Created by Guillermo Moraleda on 04.11.19.
//  Copyright © 2019 Guillermo Moraleda. All rights reserved.
//

import UIKit
import Vision
import VisionKit
import NaturalLanguage
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var recognizedTextLabel: UILabel!
    @IBOutlet weak var recognizedSentimentLabel: UILabel!
    
    @IBAction func shutterAction(_ sender: Any) {
        self.performSegue(withIdentifier: "showCameraCapture", sender: self)
    }
    
    
    
    private var scannedImaged: UIImage = UIImage() {
        didSet {
            imageView.image = scannedImaged
            recognizeText()
        }
    }
    
    private var recognizedText: String = "" {
        didSet {
            recognizedTextLabel.text = recognizedText
            tagText()
        }
    }
    
    private var recognizedSentiment: String = "" {
        didSet {
            recognizedSentimentLabel.text = recognizedSentiment
        }
    }
    
    func recognizeText() {
        guard let imageData = scannedImaged.pngData() else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNRecognizeTextRequest()
            let requests = [request]
            
            let handler = VNImageRequestHandler(data: imageData)
            try? handler.perform(requests)
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { fatalError("Wrong observation received") }
            
            var recognizedText = ""
            for observation in observations {
                guard let bestCandidate = observation.topCandidates(1).first else { continue }
                
                recognizedText += " \(bestCandidate.string)"
            }
            
            DispatchQueue.main.async {
                self.recognizedText = recognizedText
            }
            
        }
        
    }
    
    func tagText() {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = recognizedText
        
        let (sentimentTag, _) = tagger.tag(at: recognizedText.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = Double(sentimentTag?.rawValue ?? "") ?? 0
        recognizedSentimentLabel.text = "\(Sentiment(score: score).emoji)\n(\(score))"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func scanDocument(_ sender: AnyObject) {
        let controller  = VNDocumentCameraViewController()
        controller.delegate = self
        present(controller, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cameraCaptureVC = segue.destination as? CameraCaptureUIViewController {
            cameraCaptureVC.imageWasCapturedClosure = { image in
                self.scannedImaged = image
            }
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate
extension ViewController: VNDocumentCameraViewControllerDelegate {
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true)
        
        scannedImaged = scan.imageOfPage(at: 0)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true)
    }
}

enum Sentiment {
    case positive, negative, neutral
    var emoji: String {
        switch self {
        case .positive:
            return "😄"
        case .negative:
            return "🤬"
        case .neutral:
            return "😐"
        }
    }
    
    init(score: Double) {
        switch score {
        case 0.5...:
            self = .positive
        case ...(-0.5):
            self = .negative
        default:
            self = .neutral
        }
    }
}
