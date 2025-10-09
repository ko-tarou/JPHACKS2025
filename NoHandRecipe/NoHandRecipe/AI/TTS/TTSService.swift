import Foundation

protocol TTSService: AnyObject {
    func speak(_ text: String)
    func stop()
}
