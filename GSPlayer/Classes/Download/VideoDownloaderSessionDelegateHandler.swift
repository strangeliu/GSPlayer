//
//  VideoDownloaderSessionDelegateHandler.swift
//  GSPlayer
//
//  Created by Gesen on 2019/4/20.
//  Copyright © 2019 Gesen. All rights reserved.
//

import Foundation

private let bufferSize = 1024 * 256

protocol VideoDownloaderSessionDelegateHandlerDelegate: class {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)

}

class VideoDownloaderSessionDelegateHandler: NSObject {
    
    weak var delegate: VideoDownloaderSessionDelegateHandlerDelegate?
    
    var buffer = Data()
    
    init(delegate: VideoDownloaderSessionDelegateHandlerDelegate) {
        self.delegate = delegate
    }
    
}

extension VideoDownloaderSessionDelegateHandler: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        VideoLoadManager.dispatchQueue.async {
            self.delegate?.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        VideoLoadManager.dispatchQueue.async {
            self.delegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        VideoLoadManager.dispatchQueue.async {
            self.buffer.append(data)
            guard self.buffer.count > bufferSize else { return }
            self.callbackBuffer(session: session, dataTask: dataTask)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        VideoLoadManager.dispatchQueue.async {
            if self.buffer.count > 0 && error == nil {
                self.callbackBuffer(session: session, dataTask: task as! URLSessionDataTask)
            }
            self.delegate?.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
}

private extension VideoDownloaderSessionDelegateHandler {
    
    private func callbackBuffer(session: URLSession, dataTask: URLSessionDataTask) {
        let range: Range<Int> = 0 ..< buffer.count
        let chunk = buffer.subdata(in: range)
        
        buffer.replaceSubrange(range, with: [], count: 0)
        
        delegate?.urlSession(session, dataTask: dataTask, didReceive: chunk)
    }
    
}
